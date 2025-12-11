-- Copyright (C) 2025  Altera Corporation. All rights reserved.
-- Your use of Altera Corporation's design tools, logic functions 
-- and other software and tools, and any partner logic 
-- functions, and any output files from any of the foregoing 
-- (including device programming or simulation files), and any 
-- associated documentation or information are expressly subject 
-- to the terms and conditions of the Altera Program License 
-- Subscription Agreement, the Altera Quartus Prime License Agreement,
-- the Altera IP License Agreement, or other applicable license
-- agreement, including, without limitation, that your use is for
-- the sole purpose of programming logic devices manufactured by
-- Altera and sold by Altera or its authorized distributors.  Please
-- refer to the Altera Software License Subscription Agreements 
-- on the Quartus Prime software download page.

-- PROGRAM		"Quartus Prime"
-- VERSION		"Version 24.1std.0 Build 1077 03/04/2025 SC Lite Edition"
-- CREATED		"Thu Dec 10 13:00:00 2025"

LIBRARY ieee;
USE ieee.std_logic_1164.all; 

LIBRARY work;

ENTITY jk_counter_wrapper IS 
	PORT
	(
		clk    :  IN   STD_LOGIC;
		rst_n  :  IN   STD_LOGIC;
		enable :  IN   STD_LOGIC;
		hex0_a :  OUT  STD_LOGIC;
		hex0_b :  OUT  STD_LOGIC;
		hex0_c :  OUT  STD_LOGIC;
		hex0_d :  OUT  STD_LOGIC;
		hex0_e :  OUT  STD_LOGIC;
		hex0_f :  OUT  STD_LOGIC;
		hex0_g :  OUT  STD_LOGIC
	);
END jk_counter_wrapper;

ARCHITECTURE bdf_type OF jk_counter_wrapper IS 

COMPONENT hex7seg_display
	PORT(    clk    : IN STD_LOGIC;
		 rst_n  : IN STD_LOGIC;
		 sum_number : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
		 hex0_a : OUT STD_LOGIC;
		 hex0_b : OUT STD_LOGIC;
		 hex0_c : OUT STD_LOGIC;
		 hex0_d : OUT STD_LOGIC;
		 hex0_e : OUT STD_LOGIC;
		 hex0_f : OUT STD_LOGIC;
		 hex0_g : OUT STD_LOGIC
	);
END COMPONENT;

COMPONENT button_debouncer
GENERIC (     CLOCK_FREQ_HZ : INTEGER;
		CNT_WIDTH   : INTEGER;
		DEBOUNCE_MS : INTEGER
	);
	PORT(   clk      : IN  STD_LOGIC;
		rst_n    : IN  STD_LOGIC;
		raw_btn  : IN  STD_LOGIC;
		db_level : OUT STD_LOGIC;
		db_pulse : OUT STD_LOGIC
	);
END COMPONENT;

COMPONENT jk_4bit_counter
	PORT(   Clock  : IN STD_LOGIC;
		nReset : IN STD_LOGIC;
		Enable : IN STD_LOGIC;
		Q : OUT STD_LOGIC_VECTOR(3 DOWNTO 0)
	);
END COMPONENT;

SIGNAL	SYNTHESIZED_WIRE_0 :  STD_LOGIC_VECTOR(3 DOWNTO 0);
SIGNAL	SYNTHESIZED_WIRE_1 :  STD_LOGIC;

BEGIN 

b2v_inst_7seg : hex7seg_display
PORT MAP(  clk => clk,
		rst_n  => rst_n,
		sum_number => SYNTHESIZED_WIRE_0,
		hex0_a => hex0_a,
		hex0_b => hex0_b,
		hex0_c => hex0_c,
		hex0_d => hex0_d,
		hex0_e => hex0_e,
		hex0_f => hex0_f,
		hex0_g => hex0_g
	);

b2v_inst_btn_debouncer : button_debouncer
GENERIC MAP(CLOCK_FREQ_HZ   => 50000000,
		CNT_WIDTH   => 200,
		DEBOUNCE_MS => 200
	)
PORT MAP(	clk      => clk,
		rst_n    => rst_n,
		raw_btn  => enable,
		db_pulse => SYNTHESIZED_WIRE_1
	);


b2v_inst_jk_counter4 : jk_4bit_counter
PORT MAP(	Clock => clk,
		nReset => rst_n,
		Enable => SYNTHESIZED_WIRE_1,
		Q => SYNTHESIZED_WIRE_0
	);

END bdf_type;
