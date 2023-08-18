----------------------------------------------------------------------------------
-- Summer School on Real-world Crypto & Privacy - Hardware Tutorial 
-- Sibenik, June 11-15, 2018 
-- 
-- Author: Pedro Maat Costa Massolino
--  
-- Module Name: tb_ecc_base 
-- Description: testbench for the ecc_base module
----------------------------------------------------------------------------------

-- include the IEEE library and the STD_LOGIC_1164 package for basic functionality
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- describe the interface of the module: a testbench does not have any inputs or outputs
entity tb_ecc_base is
    generic(
        n: integer := 4;
        log2n: integer := 2;
        ads: integer:= 5);
end tb_ecc_base;

architecture behavioral of tb_ecc_base is

-- declare and initialize internal signals to drive the inputs of ecc_base
signal start_i: std_logic := '0';
signal rst_i: std_logic := '1';
signal clk_i: std_logic := '0';
signal oper_a_i: std_logic_vector(ads-1 downto 0) := (others => '0');
signal oper_b_i: std_logic_vector(ads-1 downto 0) := (others => '0');
signal oper_o_i: std_logic_vector(ads-1 downto 0) := (others => '0');
signal command_i: std_logic_vector(2 downto 0) := "010";
signal busy_i: std_logic;
signal done_i: std_logic;
signal m_enable_i: std_logic := '0';
signal m_din_i: std_logic_vector(n-1 downto 0) := (others => '0');
signal m_dout_i: std_logic_vector(n-1 downto 0);
signal m_rw_i: std_logic := '0';
signal m_address_i: std_logic_vector(ads-1 downto 0) := (others => '0');

-- declare the expected output from the component under test
signal command_true: std_logic_vector(n-1 downto 0) := (others => '0');

-- declare a signal to check if values match.
signal error_comp: std_logic := '0';

-- define the clock period
constant clk_period: time := 10 ns;

-- define signal to terminate simulation
signal testbench_finish: boolean := false;

-- declare the ecc_base component
component ecc_base
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
end component;

begin

-- instantiate the ecc_base component
-- map the generic parameter in the testbench to the generic parameter in the component  
-- map the signals in the testbench to the ports of the component
inst_ecc_base: ecc_base
    generic map(n => n,
    log2n => log2n,
    ads=>ads)
    port map(
        start=>start_i,
        rst=>rst_i,
        clk=>clk_i,
        oper_a=>oper_a_i,
        oper_b=>oper_b_i,
        oper_o=>oper_o_i,
        command=>command_i,
        busy=>busy_i,
        done=>done_i,
        m_enable=>m_enable_i,
        m_din=>m_din_i,
        m_dout=>m_dout_i,
        m_rw=>m_rw_i,
        m_address=>m_address_i
    );

-- generate the clock with a duty cycle of 50%
gen_clk: process
begin
     while(testbench_finish = false) loop
        clk_i <= '0';
        wait for clk_period/2;
        clk_i <= '1';
        wait for clk_period/2;
     end loop;
     wait;
end process;

-- stimulus process (without sensitivity list, but with wait statements)
stim: process
variable i: integer;
begin
    wait for clk_period;
    
    rst_i <= '0';
    
    wait for clk_period;
    -- Fill memory module with simple pattern
    i := 0;
    while(i < 2**ads-1) loop
        m_enable_i <= '1';
        m_din_i <= std_logic_vector(to_unsigned((i mod (2**n)), n));
        m_address_i <= std_logic_vector(to_unsigned(i, ads));
        m_rw_i <= '1';
        wait for clk_period;
        i := i + 1;
    end loop;
    wait for clk_period;
    -- Check if pattern is correct
    i := 0;
    while(i < 2**ads-1) loop
        error_comp <= '0';
        m_enable_i <= '1';
        m_address_i <= std_logic_vector(to_unsigned(i, ads));
        m_rw_i <= '0';
        wait for clk_period;
        if(m_dout_i /= std_logic_vector(to_unsigned((i mod (2**n)), n))) then
            error_comp <= '1';
        else
            error_comp <= '0';
        end if;
        wait for clk_period;
        error_comp <= '0';
        wait for clk_period;
        i := i + 1;
    end loop;
    wait for clk_period;
    m_enable_i <= '0';
    wait for clk_period;
    -- Load the value 13 into the prime register
    start_i <= '1';
    oper_a_i <= (others=>'0');
    oper_b_i <= std_logic_vector(to_unsigned(13, ads));
    oper_o_i <= (others=>'0');
    command_i <= "110";
    wait for clk_period;
    start_i <= '0';
    wait until done_i = '1';
    wait for 3*clk_period/2;
    -- Compute 10*9 mod 13 
    start_i <= '1';
    oper_a_i <= std_logic_vector(to_unsigned(10, ads));
    oper_b_i <= std_logic_vector(to_unsigned(9, ads));
    oper_o_i <= std_logic_vector(to_unsigned(16, ads));
    command_true <= std_logic_vector(to_unsigned(12, n));
    error_comp <= '0';
    command_i <= "011";
    wait for clk_period;
    start_i <= '0';
    wait until done_i = '1';
    wait for 3*clk_period/2;
    
    m_enable_i <= '1';
    m_address_i <= std_logic_vector(to_unsigned(16, ads));
    m_rw_i <= '0';
    wait for clk_period;
    
    if(command_true /= m_dout_i) then
        error_comp <= '1';
    else
        error_comp <= '0';
    end if;
    
    wait for 3*clk_period/2;
    
    -- Compute 7*8 mod 13 
    start_i <= '1';
    oper_a_i <= std_logic_vector(to_unsigned(7, ads));
    oper_b_i <= std_logic_vector(to_unsigned(8, ads));
    oper_o_i <= std_logic_vector(to_unsigned(17, ads));
    command_true <= std_logic_vector(to_unsigned(4, n));
    error_comp <= '0';
    command_i <= "011";
    wait for clk_period;
    start_i <= '0';
    wait until done_i = '1';
    wait for 3*clk_period/2;
    
    m_enable_i <= '1';
    m_address_i <= std_logic_vector(to_unsigned(17, ads));
    m_rw_i <= '0';
    wait for clk_period;
    
    if(command_true /= m_dout_i) then
        error_comp <= '1';
    else
        error_comp <= '0';
    end if;
    
    wait for 3*clk_period/2;
    
    -- Compute 9+5 mod 13 
    start_i <= '1';
    oper_a_i <= std_logic_vector(to_unsigned(9, ads));
    oper_b_i <= std_logic_vector(to_unsigned(5, ads));
    oper_o_i <= std_logic_vector(to_unsigned(18, ads));
    command_true <= std_logic_vector(to_unsigned(1, n));
    error_comp <= '0';
    command_i <= "000";
    wait for clk_period;
    start_i <= '0';
    wait until done_i = '1';
    wait for 3*clk_period/2;
    
    m_enable_i <= '1';
    m_address_i <= std_logic_vector(to_unsigned(18, ads));
    m_rw_i <= '0';
    wait for clk_period;
    
    if(command_true /= m_dout_i) then
        error_comp <= '1';
    else
        error_comp <= '0';
    end if;
    
    wait for 3*clk_period/2;
    
    -- Compute 9-5 mod 13 
    start_i <= '1';
    oper_a_i <= std_logic_vector(to_unsigned(9, ads));
    oper_b_i <= std_logic_vector(to_unsigned(5, ads));
    oper_o_i <= std_logic_vector(to_unsigned(19, ads));
    command_true <= std_logic_vector(to_unsigned(4, n));
    error_comp <= '0';
    command_i <= "001";
    wait for clk_period;
    start_i <= '0';
    wait until done_i = '1';
    wait for 3*clk_period/2;
    
    m_enable_i <= '1';
    m_address_i <= std_logic_vector(to_unsigned(19, ads));
    m_rw_i <= '0';
    wait for clk_period;
    
    if(command_true /= m_dout_i) then
        error_comp <= '1';
    else
        error_comp <= '0';
    end if;
    
    wait for 3*clk_period/2;
    
    -- Compute 5+12 mod 13 
    start_i <= '1';
    oper_a_i <= std_logic_vector(to_unsigned(5, ads));
    oper_b_i <= std_logic_vector(to_unsigned(12, ads));
    oper_o_i <= std_logic_vector(to_unsigned(20, ads));
    command_true <= std_logic_vector(to_unsigned(4, n));
    error_comp <= '0';
    command_i <= "000";
    wait for clk_period;
    start_i <= '0';
    wait until done_i = '1';
    wait for 3*clk_period/2;
    
    m_enable_i <= '1';
    m_address_i <= std_logic_vector(to_unsigned(20, ads));
    m_rw_i <= '0';
    wait for clk_period;
    
    if(command_true /= m_dout_i) then
        error_comp <= '1';
    else
        error_comp <= '0';
    end if;
    
    wait for 3*clk_period/2;
    
    -- Compute 5-12 mod 13 
    start_i <= '1';
    oper_a_i <= std_logic_vector(to_unsigned(5, ads));
    oper_b_i <= std_logic_vector(to_unsigned(12, ads));
    oper_o_i <= std_logic_vector(to_unsigned(21, ads));
    command_true <= std_logic_vector(to_unsigned(6, n));
    error_comp <= '0';
    command_i <= "001";
    wait for clk_period;
    start_i <= '0';
    wait until done_i = '1';
    wait for 3*clk_period/2;
    
    m_enable_i <= '1';
    m_address_i <= std_logic_vector(to_unsigned(21, ads));
    m_rw_i <= '0';
    wait for clk_period;
    
    if(command_true /= m_dout_i) then
        error_comp <= '1';
    else
        error_comp <= '0';
    end if;
    
    wait for 3*clk_period/2;
    
    testbench_finish <= true;
    wait;
end process;

end behavioral;