----------------------------------------------------------------------------------
-- Summer School on Real-world Crypto & Privacy - Hardware Tutorial 
-- Sibenik, June 11-15, 2018 
-- 
-- Author: Pedro Maat Costa Massolino
--  
-- Module Name: modarithn
-- Description: Modular arithmetic unit (multiplication, addition, subtraction)
----------------------------------------------------------------------------------

-- include the STD_LOGIC_1164 package in the IEEE library for basic functionality
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- include the NUMERIC_STD package for arithmetic operations
use IEEE.NUMERIC_STD.ALL;

-- describe the interface of the module
-- product = a*b mod p or a+b mod p or a-b mod p
entity modarithn is
    generic(
        n: integer := 8;
        log2n: integer := 3);
    port(
        a: in std_logic_vector(n-1 downto 0);
        b: in std_logic_vector(n-1 downto 0);
        p: in std_logic_vector(n-1 downto 0);
        rst: in std_logic;
        clk: in std_logic;
        start: in std_logic;
        command: in std_logic_vector(1 downto 0);
        product: out std_logic_vector(n-1 downto 0);
        done: out std_logic);
end modarithn;

-- describe the behavior of the module in the architecture
architecture behavioral of modarithn is

-- create the enumerated type 'my_state' to update and store the state of the FSM
type my_state is (s_idle, s_cmd, s_mul, s_add, s_sub, s_done);

-- declare internal signals
signal c, d, e, f, g, h, a_reg, b_1_reg, b_2_reg, p_reg, g_reg: std_logic_vector(n-1 downto 0);
signal state: my_state;
signal ctr: std_logic_vector(log2n - 1 downto 0);
signal enable, shift, b_left, endmul: std_logic;

-- declare the modaddsubn component
component modaddsubn
    generic(
        n: integer := 8);
    port(
        a, b, p: in std_logic_vector(n-1 downto 0);
        as: in std_logic;
        sum: out std_logic_vector(n-1 downto 0));
end component;

begin

-- instantiate the first modaddsubn component
-- map the generic parameter in the top design to the generic parameter in the component  
-- map the signals in the top design to the ports of the component
inst_modaddsubn_1: modaddsubn
    generic map(n => n)
    port map(   a => g_reg,
                b => g_reg,
                p => p_reg,
                as => '0',
                sum => c);
					 
-- instantiate the second modaddsubn component
-- map the generic parameter in the top design to the generic parameter in the component  
-- map the signals in the top design to the ports of the component
inst_modaddsubn_2: modaddsubn
    generic map(n => n)
    port map(   a => c,
                b => d,
                p => p_reg,
                as => '0',
                sum => e);
					 
-- instantiate the third modaddsubn component
-- map the generic parameter in the top design to the generic parameter in the component  
-- map the signals in the top design to the ports of the component
inst_modaddsubn_3: modaddsubn
    generic map(n => n)
    port map(   a => a_reg,
                b => b_2_reg,
                p => p_reg,
                as => command(0),
                sum => h);
					 
mux_1: process(b_left, a)
begin
    if b_left = '0' then
        d <= (others => '0');
    else
        d <= a;
    end if;
end process;

mux_2: process(command, g, h)
begin
    if unsigned(command) = to_unsigned(3, 2) then
        product <= g;
    elsif unsigned(command) = to_unsigned(2, 2) then
        product <= (others => '0');
	 else
		  product <= h;
    end if;
end process;

mux_3: process(endmul, g, e)
begin
    if endmul = '1' then
        f <= g;
    else
	     f <= e;
    end if;
end process;

-- store the intermediate sum in the register 'g_reg'
-- the register has an asynchronous reset: 'rst'
reg_g: process(rst, clk)
begin
    if rst = '1' then
        g_reg <= (others => '0');
    elsif rising_edge(clk) then
        if start = '1' then
            g_reg <= (others => '0');
        else
            g_reg <= f;
        end if;
    end if;
end process;

-- store the inputs 'a', 'b' and 'p' in the registers 'a_reg', 'b_1_reg', 'b_2_reg' and 'p_reg', respectively, if start = '1'
-- the registers have an asynchronous reset
-- rotate the content of 'b_reg' one position to the left if shift = '1'
reg_a_b_p: process(rst, clk)
begin
    if rst = '1' then
        a_reg <= (others => '0');
        b_1_reg <= (others => '0');
		  b_2_reg <= (others => '0');
        p_reg <= (others => '0');
    elsif rising_edge(clk) then
        if start = '1' then
            a_reg <= a;
            b_1_reg <= b;
				b_2_reg <= b;
            p_reg <= p;
        elsif shift = '1' then
            b_1_reg <= b_1_reg(n-2 downto 0) & b_1_reg(n-1);
        end if;
    end if;
end process;

b_left <= b_1_reg(n-1);

-- create a counter that increments when enable = '1'
-- because of clock delay, we check for ctr = '1' instead of '0'
counter: process(rst, clk)
begin
    if rst = '1' then
        ctr <= std_logic_vector(to_unsigned(n-1, log2n));
		  endmul <= '0';
    elsif rising_edge(clk) then
        if start = '1' then
            ctr <= std_logic_vector(to_unsigned(n-1, log2n));
				endmul <= '0';
        elsif enable = '1' then
            if unsigned(ctr) > to_unsigned(0, log2n) then
               ctr <= std_logic_vector(unsigned(ctr) - to_unsigned(1, log2n));
				end if;
				if unsigned(ctr) = to_unsigned(0, log2n) then
					endmul <= '1';
				end if;
        end if;
    end if;
end process;

g <= g_reg;

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
                    state <= s_cmd;
                end if;
				when s_cmd =>
				    if unsigned(command) = to_unsigned(3, 2) then
					     state <= s_mul;
					 elsif unsigned(command) = to_unsigned(0, 2) then
					     state <= s_add;
					 elsif unsigned(command) = to_unsigned(1, 2) then
					     state <= s_sub;
					 else
					     state <= s_done;
					 end if;
            when s_mul =>
                if endmul = '1' then
                    state <= s_done;
                end if;
				when s_add =>
                state <= s_done;
				when s_sub =>
                state <= s_done;
            when others =>
                state <= s_idle;
        end case;
    end if;
end process;

FSM_out: process(state)
begin
    case state is
        when s_idle =>
            enable <= '0';
				shift <= '0';
            done <= '0';
		  when s_cmd =>
            enable <= '1';
				shift <= '1';
            done <= '0';
        when s_mul =>
            enable <= '1';
				shift <= '1';
            done <= '0';
		  when s_add =>
            enable <= '0';
				shift <= '0';
            done <= '0';
		  when s_sub =>
            enable <= '0';
				shift <= '0';
            done <= '0';
        when others =>
            enable <= '0';
				shift <= '0';
            done <= '1';
    end case;
end process;

end behavioral;