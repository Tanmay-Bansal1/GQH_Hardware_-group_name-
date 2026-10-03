library ieee;
use ieee.std_logic_1164.all;  -- gives the logic types
use ieee.numeric_std.all;     -- math on vectors
 
entity top is
  -- generic list: constants that configure the block but are not physical pins.
  generic (
    CLK_FREQ : natural := 27_000_000  -- constants are UPPERCASE; natural = integer
  );
 
  -- list of ports: the actual signals entering and leaving the block
  -- in:  signal enters the block, you can read but not assign to it
  -- out: the signal is assigned
  port (
    clk : in  std_logic;                    -- std_logic is a single bit
    btn : in  std_logic;
    led : out std_logic_vector(5 downto 0)  -- 5 downto 0 gives 6 bits
  );
end entity;
 
architecture rtl of top is
  -- DECLARATIVE PART: internal signals, constants, types
  constant HALF_SEC : natural := 13_500_000;
  signal cnt     : natural range 0 to HALF_SEC - 1 := 0;
  signal pattern : unsigned(5 downto 0) := "000001";
begin
  -- STATEMENT PART: everything here runs in parallel
 
  -- a) Sequential logic (process with clock)
  process(clk)
  begin
    if rising_edge(clk) then  -- rising edge: clk goes from 0 to 1
      null;                   -- clocked logic goes here
    end if;
  end process;
 
  -- b) Concurrent assignment (pure wiring / combinational)
  -- a permanent wire which is always active.
  led <= not std_logic_vector(pattern);
end architecture;