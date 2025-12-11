-------------------------------------------------------------------------------
-- Title       : JK Flip-Flop (with asynchronous active-low reset)
-- File        : jk_ff.vhd
-- Author      : twwang97
-- Created     : 2025-11-28
-- Description : 
--   This VHDL module implements a JK flip-flop with the following behavior:
--     - Asynchronous reset (active low): forces Q = '0'
--     - On rising edge of Clock:
--         * J=0, K=0 → Q holds its previous state
--         * J=0, K=1 → Q resets to '0'
--         * J=1, K=0 → Q sets to '1'
--         * J=1, K=1 → Q toggles
--
-- Notes:
--   - Output Q is driven by internal signal Q_reg.
--   - Reset has priority over clock events.
--   - This design is intended for RTL simulation and synthesis.
--   - Ensure proper clocking and reset synchronization in larger designs.
--
-- Revision     : 1.0 - Initial version
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity jk_ff is
    port (
        J      : in  std_logic;
        K      : in  std_logic;
        Clock  : in  std_logic;
        nReset : in  std_logic;
        Q      : out std_logic
    );
end entity jk_ff;

architecture rtl of jk_ff is
    signal Q_reg : std_logic;
begin
    process(nReset, Clock)
    begin
        if nReset = '0' then
            Q_reg <= '0';
        elsif rising_edge(Clock) then
            if (J = '1' and K = '1') then
                Q_reg <= not Q;
            elsif (J = '1' and K = '0') then
                Q_reg <= '1';
            elsif (J = '0' and K = '1') then
                Q_reg <= '0';
            end if;
        end if;
		  Q <= Q_reg;
    end process;
end architecture rtl;
