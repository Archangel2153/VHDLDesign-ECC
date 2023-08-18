----------------------------------------------------------------------------------
-- Summer School on Real-world Crypto & Privacy - Hardware Tutorial 
-- Sibenik, June 11-15, 2018 
-- 
-- Author: Pedro Maat Costa Massolino
--  
-- Module Name: ecc_base
-- Description: Base unit that is able to run all necessary commands.
----------------------------------------------------------------------------------

-- include the STD_LOGIC_1164 package in the IEEE library for basic functionality
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- include the NUMERIC_STD package for arithmetic operations
use IEEE.NUMERIC_STD.ALL;

entity ecc_base is
    generic(
        n: integer := 8;
        log2n: integer := 3;
        ads: integer := 8);
    port(
        start: in std_logic;
        rst: in std_logic;
        clk: in std_logic;
        oper_a: in std_logic_vector(ads-1 downto 0);
        oper_b: in std_logic_vector(ads-1 downto 0);
        oper_o: in std_logic_vector(ads-1 downto 0);
        command: in std_logic_vector(2 downto 0);
        busy: out std_logic;
        done: out std_logic;
        m_enable: in std_logic;
        m_din:in std_logic_vector(n-1 downto 0);
        m_dout:out std_logic_vector(n-1 downto 0);
        m_rw:in std_logic;
        m_address:in std_logic_vector(ads-1 downto 0));
end ecc_base;

-- describe the behavior of the module in the architecture
architecture behavioral of ecc_base is

-- create the enumerated type 'my_state' to update and store the state of the FSM
type my_state is (s_idle, s_wait_ram, s_load_p, s_load_arith, s_comp_arith, s_write_arith);

-- declare internal signals
signal oper_o_address, oper_a_address, oper_b_address, address_i_1, address_i_2: std_logic_vector(ads-1 downto 0);
signal a, b, p, product, din_i_1: std_logic_vector(n-1 downto 0);
signal state: my_state;
signal reg_comm: std_logic_vector(2 downto 0);
signal free, rw, enable, p_enable, a_start, a_done, rw_i, enable_i: std_logic;

-- declare the modarithn component
component modarithn
    generic(
        n: integer := 8;
		  log2n: integer := 3);
    port(
        a, b, p: in std_logic_vector(n-1 downto 0);
        rst, clk, start: in std_logic;
		  command: in std_logic_vector(1 downto 0);
        product: out std_logic_vector(n-1 downto 0);
        done: out std_logic);
end component;

-- declare the ram_double component
component ram_double
    generic(
        ws: integer := 8;
        ads: integer := 8);
    port(
        enable, clk, rw: in std_logic;
        din_a: in std_logic_vector((ws - 1) downto 0);
		  address_a, address_b: in std_logic_vector((ads - 1) downto 0);
        dout_a, dout_b: out std_logic_vector((ws - 1) downto 0));
end component;

begin

-- instantiate the modarithn component
-- map the generic parameter in the top design to the generic parameter in the component  
-- map the signals in the top design to the ports of the component
inst_modarithn: modarithn
    generic map(n => n,
	 log2n => log2n)
    port map(   a => a,
                b => b,
                p => p,
					 rst => rst,
					 clk => clk,
					 start => a_start,
					 command => command(1 downto 0),
                product => product,
                done => a_done);
					 
-- instantiate the ram_double component
-- map the generic parameter in the top design to the generic parameter in the component  
-- map the signals in the top design to the ports of the component
inst_ram_double: ram_double
    generic map(ws => n,
	 ads => ads)
    port map(   enable => enable_i,
                clk => clk,
                rw => rw_i,
                din_a => din_i_1,
                address_a => address_i_2,
					 address_b => oper_b_address,
					 dout_a => a,
					 dout_b => b);

-- create the first multiplexer which selects between oper_a_address and oper_o_address					 
mux_1: process(oper_a_address, oper_o_address, rw)
begin
    if rw = '0' then
        address_i_1 <= oper_a_address;
    else
        address_i_1 <= oper_o_address;
    end if;
end process;

-- create the second multiplexer which selects between address_i_1 and m_address					 
mux_2: process(address_i_1, m_address, free)
begin
    if free = '0' then
        address_i_2 <= address_i_1;
    else
        address_i_2 <= m_address;
    end if;
end process;

-- create the third multiplexer which selects between m_din and product
mux_3: process(product, m_din, free)
begin
    if free = '0' then
        din_i_1 <= product;
    else
        din_i_1 <= m_din;
    end if;
end process;

-- create the fourth multiplexer which selects between rw and m_rw
mux_4: process(rw, m_rw, free)
begin
    if free = '0' then
        rw_i <= rw;
    else
        rw_i <= m_rw;
    end if;
end process;

-- create the fifth multiplexer which selects between enable and m_enable
mux_5: process(enable, m_enable, free)
begin
    if free = '0' then
        enable_i <= enable;
    else
        enable_i <= m_enable;
    end if;
end process;

-- store the inputs 'oper_o', 'oper_a' and 'oper_b' in the registers 'oper_o_address', 'oper_a_address' and 'oper_b_address', 
-- respectively, if start = '1'
reg_o_a_b: process(clk)
begin
    if rising_edge(clk) then
        if start = '1' then
            oper_o_address <= oper_o;
				oper_a_address <= oper_a;
				oper_b_address <= oper_b;
        end if;
    end if;
end process;

-- store the value of 'b' in the register 'p' if 'p_enable' is '1' 
reg_p: process(clk)
begin
    if rising_edge(clk) then
        if p_enable = '1' then
            p <= b;
        end if;
    end if;
end process;

-- store the value of 'command' in the register 'reg_comm' if 'start' is '1'
command_register: process(clk)
begin
    if rising_edge(clk) then
        if start = '1' then
            reg_comm <= command;
        end if;
    end if;
end process;

busy <= not(free);
m_dout <= a;

-- update and store the state of the FSM
-- stop the calculation when ctr = '0', i.e. when we reach b*a
-- (we lose 1 cycle by resetting the product register when the start signal comes)
FSM_state: process(rst, clk)
begin
    if rst = '1' then
        state <= s_idle;
    elsif rising_edge(clk) then
        case state is
            when s_idle =>
                if start = '1' then
                    state <= s_wait_ram;
                end if;
				when s_wait_ram =>
				    if reg_comm(2) = '1' then
					     state <= s_load_p;
					 else
					     state <= s_load_arith;
					 end if;
            when s_load_p =>
                state <= s_idle;
				when s_load_arith =>
                state <= s_comp_arith;
				when s_comp_arith =>
				    if a_done = '1' then
                    state <= s_write_arith;
					 end if;
            when others =>
                state <= s_idle;
        end case;
    end if;
end process;

FSM_out: process(state)
begin
    case state is
        when s_idle =>
		      free <= '1';
				done <= '0';
				rw <= '0';
            enable <= '0';
				a_start <= '0';
				p_enable <= '0';
		  when s_wait_ram =>
            free <= '0';
				done <= '0';
				rw <= '0';
            enable <= '1';
				a_start <= '0';
				p_enable <= '0';
        when s_load_p =>
            free <= '0';
				done <= '1';
				rw <= '0';
            enable <= '1';
				a_start <= '0';
				p_enable <= '1';
		  when s_load_arith =>
            free <= '0';
				done <= '0';
				rw <= '0';
            enable <= '1';
				a_start <= '1';
				p_enable <= '0';
		  when s_comp_arith =>
            free <= '0';
				done <= '0';
				rw <= '0';
            enable <= '0';
				a_start <= '0';
				p_enable <= '0';
        when others =>
            free <= '0';
				done <= '1';
				rw <= '1';
            enable <= '1';
				a_start <= '0';
				p_enable <= '0';
    end case;
end process;

end behavioral;