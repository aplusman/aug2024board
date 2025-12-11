-- =============================================================================
-- File    : button_debouncer.vhd
-- Author  : Wang <twwang97@gmail.com>
-- Date    : 2025-11-28
-- Version : 1.0
-- 
-- Brief   : Debounce a mechanical push-button. Produces a stable level and a
--           single-cycle rising-edge pulse after a configurable debounce time.
--
-- Purpose : Implements a 2-stage synchronizer, an initial hold-off after reset,
--           and a time-based debounce counter. Outputs are forced low until the
--           initial hold-off completes to avoid spurious pulses at startup.
--
-- Generics: CLOCK_FREQ_HZ  - input clock frequency in Hz (default 50_000_000)
--           DEBOUNCE_MS    - debounce time in milliseconds (default 20 ms)
--           CNT_WIDTH      - width of internal counters (adjust for range)
--
-- Ports   : clk     - system clock (rising-edge synchronous)
--           rst_n   - active-low synchronous reset (held low to reset)
--           raw_btn - asynchronous button input (active high)
--           db_level- debounced level output (0/1)
--           db_pulse- single-cycle pulse on rising edge of db_level
--
-- Timing  : THRESH = (CLOCK_FREQ_HZ / 1000) * DEBOUNCE_MS cycles.
--           Ensure CNT_WIDTH is large enough to represent THRESH.
--
-- Synthesis Notes:
--   * raw_btn is asynchronous; the design synchronizes it with a 2-stage
--     synchronizer to avoid metastability.
--   * Outputs are held low until init_done to avoid startup glitches.
--   * This design infers simple counters and registers; no latches.
--
-- Known Issues / TODO:
--   * Consider parameterizing reset behavior or pulse polarity if needed.
--   * Add optional active-low button support or configurable polarity.
--
-- Revision History:
--   1.0 2025-11-28  Initial release
-- =============================================================================


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity button_debouncer is
  generic (
    CLOCK_FREQ_HZ : natural := 50_000_000; -- input clock frequency
    DEBOUNCE_MS   : natural := 20;         -- debounce time in milliseconds
    CNT_WIDTH     : natural := 20          -- width of counter (adjust if needed)
  );
  port (
    clk        : in  std_logic;
    rst_n      : in  std_logic;
    raw_btn    : in  std_logic;  -- asynchronous button input (active high)
    db_level   : out std_logic;  -- debounced level (0/1)
    db_pulse   : out std_logic   -- single-cycle pulse on rising edge
  );
end entity;

architecture rtl of button_debouncer is
  signal sync0, sync1    : std_logic := '0';
  signal stable0         : std_logic := '0';
  signal stable0_prev    : std_logic := '0';
  signal cnt             : unsigned(CNT_WIDTH-1 downto 0) := (others => '0');
  signal init_cnt        : unsigned(CNT_WIDTH-1 downto 0) := (others => '0');
  signal init_done       : std_logic := '0';
  constant THRESH        : unsigned(CNT_WIDTH-1 downto 0) :=
    to_unsigned((CLOCK_FREQ_HZ/1000) * DEBOUNCE_MS, CNT_WIDTH);
begin

  -- 2-stage synchronizer to avoid metastability
  process(clk)
  begin
    if rising_edge(clk) then
      if rst_n = '0' then
        sync0 <= '0';
        sync1 <= '0';
      else
        sync0 <= raw_btn;
        sync1 <= sync0;
      end if;
    end if;
  end process;

  -- initial hold-off counter after reset: keep outputs zero for THRESH cycles
  process(clk)
  begin
    if rising_edge(clk) then
      if rst_n = '0' then
        init_cnt  <= (others => '0');
        init_done <= '0';
      else
        if init_done = '0' then
          if init_cnt = THRESH - 1 then
            init_done <= '1';
            init_cnt  <= (others => '0');
          else
            init_cnt <= init_cnt + 1;
          end if;
        end if;
      end if;
    end if;
  end process;

  -- debounce counter: require sync1 to be stable0 for THRESH cycles
  process(clk)
  begin
    if rising_edge(clk) then
      if rst_n = '0' then
        stable0 <= '0';
        cnt <= (others => '0');
      elsif init_done = '0' then
        -- during initial hold-off keep stable0 low and reset debounce counter
        stable0 <= '0';
        cnt <= (others => '0');
      else
        -- normal debounce operation
        if sync1 = stable0 then
          cnt <= (others => '0');
        else
          if cnt = THRESH - 1 then
            stable0 <= sync1;
            cnt <= (others => '0');
          else
            cnt <= cnt + 1;
          end if;
        end if;
      end if;
    end if;
  end process;

  -- output and one-shot pulse: hold prev low until init_done
  process(clk)
  begin
    if rising_edge(clk) then
      if rst_n = '0' then
        stable0_prev <= '0';
      elsif init_done = '0' then
        stable0_prev <= '0';
      else
        stable0_prev <= stable0;
      end if;
    end if;
  end process;

  -- outputs forced low until init_done, then reflect debounced signals
  db_level <= stable0 when init_done = '1' else '0';
  db_pulse <= '1' when (init_done = '1' and stable0 = '1' and stable0_prev = '0') else '0';

end architecture;
