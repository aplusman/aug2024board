-------------------------------------------------------------------------------
-- Title       : 4-bit Ripple Counter using JK Flip-Flops
-- File        : jk_4bit_counter.vhd
-- Author      : twwang97
-- Created     : 2025-11-28
-- Description :
--   This VHDL module implements a 4-bit binary counter using JK flip-flops.
--   - Counter increments on each rising edge of Clock when Enable = '1'.
--   - Active-low asynchronous reset (nReset) clears the counter to "0000".
--   - Q(0) is the least significant bit (LSB).
--
-- Functional Notes:
--   - The counter is built as a ripple counter:
--       * Q(0) toggles when Enable = '1'.
--       * Higher-order bits toggle when all lower bits are '1' and Enable = '1'.
--   - J and K inputs are tied together for toggle behavior.
--   - Internal signal q_reg holds the current counter state.
--   - Output Q is directly mapped to q_reg.
--
-- Dependencies :
--   - Requires jk_ff entity (JK flip-flop with async reset).
--   - Uses ieee.std_logic_1164 library.
--
-- Revision History :
--   v1.0 - Initial version
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity jk_4bit_counter is
    port (
        Clock  : in  std_logic;
        nReset : in  std_logic;  -- active low reset
        Enable : in  std_logic;  -- count when '1'
        Q      : out std_logic_vector(3 downto 0)  -- Q(0) is LSB
    );
end entity jk_4bit_counter;

architecture rtl of jk_4bit_counter is
    -- internal signals for J and K
    signal q_reg : std_logic_vector(3 downto 0) := (others => '0');
    signal J     : std_logic_vector(3 downto 0);
    signal K     : std_logic_vector(3 downto 0);
begin

    -- J assignments for toggle-style ripple counter
    J(0) <= Enable;
    J(1) <= Enable and q_reg(0);
    J(2) <= Enable and q_reg(0) and q_reg(1);
    J(3) <= Enable and q_reg(0) and q_reg(1) and q_reg(2);

    -- K equals J for toggle behavior
    K <= J;

    -- Instantiate four jk_ff components using a generate loop
    gen_bits : for i in 0 to 3 generate
        jk_inst : entity work.jk_ff
            port map (
                J      => J(i),
                K      => K(i),
                Clock  => Clock,
                nReset => nReset,
                Q      => q_reg(i)
            );
    end generate gen_bits;

    -- output assignment
    Q <= q_reg;

end architecture rtl;
