----------------------------------------------------------------------------------
-- Summer School on Real-world Crypto & Privacy - Hardware Tutorial 
-- Sibenik, June 11-15, 2018 
-- 
-- Author: Pedro Maat Costa Massolino
--  
-- Module Name: ram_single
-- Description: RAM memory with variable word size and depth.
----------------------------------------------------------------------------------

-- include the STD_LOGIC_1164 package in the IEEE library for basic functionality
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- include the NUMERIC_STD package for arithmetic operations
use IEEE.NUMERIC_STD.ALL;

-- describe the interface of the module
entity ram_single is
    generic( 
        ws: integer := 8;
        ads: integer := 8);
    port(
        enable: in std_logic;
        clk: in std_logic;
        din: in std_logic_vector((ws - 1) downto 0);
        address: in std_logic_vector((ads - 1) downto 0);
        rw: in std_logic;
        dout: out std_logic_vector((ws - 1) downto 0));
end ram_single;
    
-- describe the behavior of the module in the architecture
architecture behavioral of ram_single is

-- declare internal signals

-- We can see a memory as an matrix of bits, or array of memory words.
-- To construct an array of an existing type, we need to create a new type and this new type will be an array.
-- The size of the array has to be specified during the instantiation of the type.
type ramtype is array(integer range <>) of std_logic_vector((ws - 1) downto 0);

-- Instantiation of the memory itself with 2^(address size)-1
signal memory_ram: ramtype(0 to (2**ads-1));

begin

-- The command to_01 is necessary in case the address has a value that is not 0 and 1, the function will transform the different types to 0 or 1.
-- If there was no command, the function to_integer will give an error every time address is not 0 or 1. This can usually happen at the beginning of a simulation.
process(clk)
    begin
        if (rising_edge(clk)) then
            if(enable = '1') then
                dout <= memory_ram(to_integer(to_01(unsigned(address))));
                if rw = '1' then
                    memory_ram(to_integer(to_01(unsigned(address)))) <= din;
                end if;
            end if;
        end if;
end process;

end behavioral;