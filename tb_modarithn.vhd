----------------------------------------------------------------------------------
-- Summer School on Real-world Crypto & Privacy - Hardware Tutorial 
-- Sibenik, June 11-15, 2018 
-- 
-- Author: Pedro Maat Costa Massolino
--  
-- Module Name: tb_modarithn 
-- Description: testbench for the modarithn module
----------------------------------------------------------------------------------

-- include the IEEE library and the STD_LOGIC_1164 package for basic functionality
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- describe the interface of the module: a testbench does not have any inputs or outputs
entity tb_modarithn is
    generic(
        n: integer := 4;
        log2n: integer := 2);
end tb_modarithn;

architecture behavioral of tb_modarithn is

-- declare and initialize internal signals to drive the inputs of modarithn
signal a_i, b_i, p_i: std_logic_vector(n-1 downto 0) := (others => '0');
signal rst_i, clk_i, start_i: std_logic := '0';
signal command_i:std_logic_vector(1 downto 0) := "10";

-- declare internal signals to read out the outputs of modarithn
signal product_i: std_logic_vector(n-1 downto 0);
signal done_i: std_logic;

-- declare the expected output from the component under test
signal product_true: std_logic_vector(n-1 downto 0) := (others => '0');

-- declare a signal to check if values match.
signal error_comp: std_logic := '0';

-- define the clock period
constant clk_period: time := 10 ns;

-- define signal to terminate simulation
signal testbench_finish: boolean := false;

-- declare the modarithn component
component modarithn
    generic(n: integer := 8;
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
end component;

begin


-- instantiate the modarithn component
-- map the generic parameter in the testbench to the generic parameter in the component  
-- map the signals in the testbench to the ports of the component
inst_modarithn: modarithn
    generic map(n => n,
    log2n => log2n)
    port map(
        a => a_i,
        b => b_i,
        p => p_i,
        rst => rst_i,
        clk => clk_i,
        start => start_i,
        command => command_i,
        product => product_i,
        done => done_i
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
begin
    wait for clk_period;
    
    rst_i <= '1';
    
    wait for clk_period;
    
    rst_i <= '0';
    
    wait for clk_period;
    
    a_i <= "1010";
    b_i <= "1001";
    p_i <= "1101";
    start_i <= '1';
    product_true <= "1100";
    error_comp <= '0';
    command_i <= "11";
    
    wait for clk_period;
    
    start_i <= '0';
    
    wait until done_i = '1';
    
    if(product_true /= product_i) then
        error_comp <= '1';
    else
        error_comp <= '0';
    end if;
    
	 wait for 3*clk_period/2;
    
    a_i <= "0111";
    b_i <= "1000";
    p_i <= "1001";
    start_i <= '1';
    product_true <= "0010";
    error_comp <= '0';
    command_i <= "11";
    wait for clk_period;
        
    start_i <= '0';

    wait until done_i = '1';
    
    if(product_true /= product_i) then
        error_comp <= '1';
    else
        error_comp <= '0';
    end if;

    wait for 3*clk_period/2;
    
    a_i <= "0110";
    b_i <= "0011";
    p_i <= "1101";
    start_i <= '1';
    product_true <= "1001";
    command_i <= "00";
    error_comp <= '0';
    
    wait for clk_period;
    
    start_i <= '0';
    
    wait until done_i = '1';
    
    if(product_true /= product_i) then
        error_comp <= '1';
    else
        error_comp <= '0';
    end if;
    
    wait for 3*clk_period/2;
    
    command_i <= "01";
    start_i <= '1';
    product_true <= "0011";
    error_comp <= '0';
    
    wait for clk_period;
    
    start_i <= '0';
    
    wait until done_i = '1';
    
    if(product_true /= product_i) then
        error_comp <= '1';
    else
        error_comp <= '0';
    end if;
    
    wait for 3*clk_period/2;
    
    a_i <= "0010";
    b_i <= "1011";
    p_i <= "1100";
    command_i <= "00";
    start_i <= '1';
    product_true <= "0001";
    error_comp <= '0';
    
    wait for clk_period;
    
    start_i <= '0';
    
    wait until done_i = '1';
    
    if(product_true /= product_i) then
        error_comp <= '1';
    else
        error_comp <= '0';
    end if;
    
    wait for 3*clk_period/2;
            
    command_i <= "01";
    start_i <= '1';
    product_true <= "0011";
    error_comp <= '0';
    
    wait for clk_period;
    
    start_i <= '0';
    
    wait until done_i = '1';
    
    if(product_true /= product_i) then
        error_comp <= '1';
    else
        error_comp <= '0';
    end if;
    
    wait for 3*clk_period/2;
    
    testbench_finish <= true;
    wait;
end process;

end behavioral;