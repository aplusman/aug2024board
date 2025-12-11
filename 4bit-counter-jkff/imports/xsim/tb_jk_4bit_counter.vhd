-------------------------------------------------------------------------------
-- Title       : Testbench for 4-bit JK Ripple Counter
-- File        : tb_jk_4bit_counter.vhd
-- Author      : twwang97
-- Created     : 2025-11-28
-- Description :
--   This testbench verifies the functionality of the 4-bit JK ripple counter
--   (entity: jk_4bit_counter). It provides stimulus and monitors the DUT output.
--
-- Testbench Features:
--   - Generates a 50 MHz clock (20 ns period).
--   - Applies asynchronous active-low reset at startup and mid-simulation.
--   - Controls Enable signal to test:
--       * Counting when Enable = '1'
--       * Holding state when Enable = '0'
--       * Wrap-around behavior after multiple cycles
--   - Reports simulation progress and DUT state using VHDL 'report' statements.
--   - Prints counter value (Q) at each rising clock edge.
--   - Ends simulation with a failure assertion to stop the run.
--
-- Notes:
--   - This testbench is self-checking only through textual reports; 
--     no automated pass/fail comparison is implemented.
--   - Designed for functional verification in simulation, not for synthesis.
--   - Extendable for additional scenarios (e.g., randomized Enable toggling).
--
-- Dependencies :
--   - Requires jk_4bit_counter entity (DUT).
--   - Uses ieee.std_logic_1164 and ieee.numeric_std libraries.
--
-- Revision History :
--   v1.0 - Initial version
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_jk_4bit_counter is
end entity tb_jk_4bit_counter;

architecture sim of tb_jk_4bit_counter is
    -- DUT signals
    signal Clock  : std_logic := '0';
    signal nReset : std_logic := '1';  -- active low
    signal Enable : std_logic := '0';
    signal Q      : std_logic_vector(3 downto 0);

    constant CLK_PERIOD : time := 20 ns;  -- 50 MHz clock (20 ns period)
begin

    -- Instantiate the device under test
    uut: entity work.jk_4bit_counter
        port map (
            Clock  => Clock,
            nReset => nReset,
            Enable => Enable,
            Q      => Q
        );

    -- Clock generator
    clk_proc : process
    begin
        while true loop
            Clock <= '0';
            wait for CLK_PERIOD / 2;
            Clock <= '1';
            wait for CLK_PERIOD / 2;
        end loop;
    end process clk_proc;

    -- Stimulus process
    stim_proc : process
    begin
        -- initial asynchronous reset asserted
        nReset <= '0';
        Enable <= '0';
        wait for 25 ns;

        -- release reset
        nReset <= '1';
        wait for 15 ns;

        -- start counting
        Enable <= '1';
        report "Enable asserted, counting should start" severity note;

        -- let it count for a number of clock cycles (observe wrap-around)
        wait for 10 * CLK_PERIOD;  -- 10 clock cycles

        -- disable counting (hold)
        Enable <= '0';
        report "Enable deasserted, counter should hold" severity note;
        wait for 5 * CLK_PERIOD;

        -- re-enable counting
        Enable <= '1';
        report "Enable reasserted, counting resumes" severity note;
        wait for 8 * CLK_PERIOD;

        -- assert asynchronous reset again to test clear
        nReset <= '0';
        report "Asserting asynchronous reset (active low)" severity note;
        wait for 7 ns;  -- asynchronous, so can be asserted between clocks
        nReset <= '1';
        report "Releasing asynchronous reset" severity note;
        wait for 4 * CLK_PERIOD;

        -- final hold and finish
        Enable <= '0';
        wait for 2 * CLK_PERIOD;

        report "End of testbench" severity note;
        -- stop simulation
        assert false report "Simulation finished" severity failure;
        wait;
    end process stim_proc;

    -- Monitor process: print Q on each rising edge
    monitor_proc : process(Clock)
    begin
        if rising_edge(Clock) then
            report "At time " & time'image(now) & " Q = " & integer'image(to_integer(unsigned(Q))) severity note;
        end if;
    end process monitor_proc;

end architecture sim;
