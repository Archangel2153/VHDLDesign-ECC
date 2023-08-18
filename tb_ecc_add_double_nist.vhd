----------------------------------------------------------------------------------
-- Summer School on Real-world Crypto & Privacy - Hardware Tutorial 
-- Sibenik, June 11-15, 2018 
-- 
-- Author: Pedro Maat Costa Massolino
--  
-- Module Name: tb_ecc_add_double_small 
-- Description: testbench for the ecc_add_double module
----------------------------------------------------------------------------------

-- include the IEEE library and the STD_LOGIC_1164 package for basic functionality
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- describe the interface of the module: a testbench does not have any inputs or outputs
entity tb_ecc_add_double_nist is
    generic(
        n: integer := 256;
        log2n: integer := 8);
end tb_ecc_add_double_nist;

architecture behavioral of tb_ecc_add_double_nist is

-- declare and initialize internal signals to drive the inputs of ecc_add_double

constant ecc_prime: std_logic_vector(n-1 downto 0) := X"ffffffff00000001000000000000000000000000ffffffffffffffffffffffff";
constant ecc_a: std_logic_vector(n-1 downto 0) := X"ffffffff00000001000000000000000000000000fffffffffffffffffffffffc";
constant ecc_b: std_logic_vector(n-1 downto 0) := X"5ac635d8aa3a93e7b3ebbd55769886bc651d06b0cc53b0f63bce3c3e27d2604b";

constant ecc_p1_x: std_logic_vector(n-1 downto 0) := X"82ff10b5ce3ef76b3d479fbf67b1814adf32c22b7d6bfa8d52c6634ab5562f31";
constant ecc_p1_y: std_logic_vector(n-1 downto 0) := X"ddfaa9e2d1fb42888e3c0c68dd6ac01166ebf45ad44bb4d10115bb1ee9a618a5";
constant ecc_p1_z: std_logic_vector(n-1 downto 0) := X"142d21375d4b8e34fd975fb9ffc6ed27bcef061ffdce6c3e48d79d9a4a774686";

constant ecc_p2_x: std_logic_vector(n-1 downto 0) := X"771237aee432c1de1760a14d5ef2dc2bed90151a4512254b3a8166b46d8d03d3";
constant ecc_p2_y: std_logic_vector(n-1 downto 0) := X"24a827e6110102663b61e20b703294289f517c602bcfbdb28eba3d358ef04207";
constant ecc_p2_z: std_logic_vector(n-1 downto 0) := X"67e35ea00df06783de49f09bb1d0bfc6d32246304390fa40f9f0153f92fbd519";

constant ecc_p1_plus_p2_x: std_logic_vector(n-1 downto 0) := X"bbddb3471a021e4e8cf4272b9ea21e95a1ab6f5ec8d150b57b8489ff575a398e";
constant ecc_p1_plus_p2_y: std_logic_vector(n-1 downto 0) := X"1d09644972a38be8634c7c2f878291068e352acdf8e42662793dfc548a05dcb4";
constant ecc_p1_plus_p2_z: std_logic_vector(n-1 downto 0) := X"85f8cc7bb588a17d8177a1033e3c605bfecd2bf4174b3452fbc2c284600edec4";

constant ecc_p1_double_x: std_logic_vector(n-1 downto 0) := X"6e87337a8f6cbb49aebe737179c9bd4eba7e11f5344cd55e22585457c8924dc9";
constant ecc_p1_double_y: std_logic_vector(n-1 downto 0) := X"83e87ea5cd7b36b9a55cdb243730a2e400021e2b8a442561952755c3866146aa";
constant ecc_p1_double_z: std_logic_vector(n-1 downto 0) := X"5454948f66fc340d18c9bc3dfdb5c9313c55a333600a8be0cbcbdc5b61ef027e";

signal start_i: std_logic := '0';
signal rst_i: std_logic := '1';
signal clk_i: std_logic := '0';
signal add_double_i: std_logic := '0';
signal busy_i: std_logic;
signal done_i: std_logic;
signal m_enable_i: std_logic := '0';
signal m_din_i: std_logic_vector(n-1 downto 0) := (others => '0');
signal m_dout_i: std_logic_vector(n-1 downto 0);
signal m_rw_i: std_logic := '0';
signal m_address_i: std_logic_vector(4 downto 0) := (others => '0');

-- declare a signal to check if values match.
signal error_comp: std_logic := '0';

-- define the clock period
constant clk_period: time := 10 ns;

-- define signal to terminate simulation
signal testbench_finish: boolean := false;

-- declare the ecc_base component
component ecc_add_double
    generic(n: integer := 8;
            log2n: integer := 3);
    port(
        start: in std_logic;
        rst: in std_logic;
        clk: in std_logic;
        add_double: in std_logic;
        done: out std_logic;
        busy: out std_logic;
        m_enable: in std_logic;
        m_din:in std_logic_vector(n-1 downto 0);
        m_dout:out std_logic_vector(n-1 downto 0);
        m_rw:in std_logic;
        m_address:in std_logic_vector(4 downto 0));
end component;

begin

-- instantiate the ecc_base component
-- map the generic parameter in the testbench to the generic parameter in the component  
-- map the signals in the testbench to the ports of the component
inst_ecc_add_double: ecc_add_double
    generic map(n=>n,
            log2n=>log2n)
    port map(
        start=>start_i,
        rst=>rst_i,
        clk=>clk_i,
        add_double=>add_double_i,
        done=>done_i,
        busy=>busy_i,
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
    -- Fill memory with the ecc constants and points
    m_enable_i <= '1';
    m_din_i <= ecc_prime;
    m_rw_i <= '1';
    m_address_i <= std_logic_vector(to_unsigned(0, 5));
    wait for clk_period;
    m_enable_i <= '1';
    m_din_i <= ecc_a;
    m_rw_i <= '1';
    m_address_i <= std_logic_vector(to_unsigned(1, 5));
    wait for clk_period;
    m_enable_i <= '1';
    m_din_i <= ecc_b;
    m_rw_i <= '1';
    m_address_i <= std_logic_vector(to_unsigned(2, 5));
    wait for clk_period;
    m_enable_i <= '1';
    m_din_i <= ecc_p1_x;
    m_rw_i <= '1';
    m_address_i <= std_logic_vector(to_unsigned(3, 5));
    wait for clk_period;
    m_enable_i <= '1';
    m_din_i <= ecc_p1_y;
    m_rw_i <= '1';
    m_address_i <= std_logic_vector(to_unsigned(4, 5));
    wait for clk_period;
    m_enable_i <= '1';
    m_din_i <= ecc_p1_z;
    m_rw_i <= '1';
    m_address_i <= std_logic_vector(to_unsigned(5, 5));
    wait for clk_period;
    m_enable_i <= '1';
    m_din_i <= ecc_p2_x;
    m_rw_i <= '1';
    m_address_i <= std_logic_vector(to_unsigned(6, 5));
    wait for clk_period;
    m_enable_i <= '1';
    m_din_i <= ecc_p2_y;
    m_rw_i <= '1';
    m_address_i <= std_logic_vector(to_unsigned(7, 5));
    wait for clk_period;
    m_enable_i <= '1';
    m_din_i <= ecc_p2_z;
    m_rw_i <= '1';
    m_address_i <= std_logic_vector(to_unsigned(8, 5));
    wait for clk_period;
    m_enable_i <= '0';
    m_rw_i <= '0';
    m_address_i <= std_logic_vector(to_unsigned(0, 5));
    wait for clk_period;
    -- Perform point addition
    start_i <= '1';
    add_double_i <= '0';
    wait for clk_period;
    start_i <= '0';
    wait until done_i = '1';
    wait for 3*clk_period/2;
    -- Retrieve value
    wait for clk_period;
    error_comp <= '0';
    m_enable_i <= '1';
    m_din_i <= (others=>'0');
    m_rw_i <= '0';
    m_address_i <= std_logic_vector(to_unsigned(9, 5));
    wait for clk_period;
    if(ecc_p1_plus_p2_x /= m_dout_i) then
        error_comp <= '1';
    else
        error_comp <= '0';
    end if;
    wait for clk_period;
    error_comp <= '0';
    m_enable_i <= '1';
    m_din_i <= (others=>'0');
    m_rw_i <= '0';
    m_address_i <= std_logic_vector(to_unsigned(10, 5));
    wait for clk_period;
    if(ecc_p1_plus_p2_y /= m_dout_i) then
        error_comp <= '1';
    else
        error_comp <= '0';
    end if;
    wait for clk_period;
    error_comp <= '0';
    m_enable_i <= '1';
    m_din_i <= (others=>'0');
    m_rw_i <= '0';
    m_address_i <= std_logic_vector(to_unsigned(11, 5));
    wait for clk_period;
    if(ecc_p1_plus_p2_z /= m_dout_i) then
        error_comp <= '1';
    else
        error_comp <= '0';
    end if;
    -- Perform point doubling
    start_i <= '1';
    add_double_i <= '1';
    wait for clk_period;
    start_i <= '0';
    wait until done_i = '1';
    wait for 3*clk_period/2;
    -- Retrieve value
    wait for clk_period;
    error_comp <= '0';
    m_enable_i <= '1';
    m_din_i <= (others=>'0');
    m_rw_i <= '0';
    m_address_i <= std_logic_vector(to_unsigned(9, 5));
    wait for clk_period;
    if(ecc_p1_double_x /= m_dout_i) then
        error_comp <= '1';
    else
        error_comp <= '0';
    end if;
    wait for clk_period;
    error_comp <= '0';
    m_enable_i <= '1';
    m_din_i <= (others=>'0');
    m_rw_i <= '0';
    m_address_i <= std_logic_vector(to_unsigned(10, 5));
    wait for clk_period;
    if(ecc_p1_double_y /= m_dout_i) then
        error_comp <= '1';
    else
        error_comp <= '0';
    end if;
    wait for clk_period;
    error_comp <= '0';
    m_enable_i <= '1';
    m_din_i <= (others=>'0');
    m_rw_i <= '0';
    m_address_i <= std_logic_vector(to_unsigned(11, 5));
    wait for clk_period;
    if(ecc_p1_double_z /= m_dout_i) then
        error_comp <= '1';
    else
        error_comp <= '0';
    end if;
    wait for 3*clk_period/2;
    testbench_finish <= true;
    wait;
end process;

end behavioral;