# -------------------------------------------------------------------------------------------
# File     : basys3.xdc
# Purpose  : Pin assignments mainly for the 4-bit counter
# Device   : xc7a35tcpg236-1
# Author   : twwang97
# Date     : 2025-12-10
# Schematic:
# https://digilent.com/reference/_media/reference/programmable-logic/basys-3/basys-3_sch.pdf
# -------------------------------------------------------------------------------------------

#################################################
#                                               #
#            Clock signal (100 MHz)             #
#                                               #
#################################################

# Bank = 34, Pin name = IO_L12P_T1_MRCC_34, Sch name = CLK100MHZ
set_property PACKAGE_PIN W5 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -period 10.000 -name clk_pin -waveform {0.000 5.000} -add [get_ports clk]


#################################################
#                                               #
#                   Switch                      #
#                                               #
#################################################

# 1st SW
set_property PACKAGE_PIN V17 [get_ports rst_n]
set_property IOSTANDARD LVCMOS33 [get_ports rst_n]

#################################################
#                                               #
#                   Button                      #
#                                               #
#################################################

# Center Button
set_property PACKAGE_PIN U18 [get_ports enable]
set_property IOSTANDARD LVCMOS33 [get_ports enable]

#################################################
#                                               #
#            7-segment display                  #
#                                               #
#################################################

set_property PACKAGE_PIN W7 [get_ports hex0_a]
set_property IOSTANDARD LVCMOS33 [get_ports hex0_a]
set_property PACKAGE_PIN W6 [get_ports hex0_b]
set_property IOSTANDARD LVCMOS33 [get_ports hex0_b]
set_property PACKAGE_PIN U8 [get_ports hex0_c]
set_property IOSTANDARD LVCMOS33 [get_ports hex0_c]
set_property PACKAGE_PIN V8 [get_ports hex0_d]
set_property IOSTANDARD LVCMOS33 [get_ports hex0_d]
set_property PACKAGE_PIN U5 [get_ports hex0_e]
set_property IOSTANDARD LVCMOS33 [get_ports hex0_e]
set_property PACKAGE_PIN V5 [get_ports hex0_f]
set_property IOSTANDARD LVCMOS33 [get_ports hex0_f]
set_property PACKAGE_PIN U7 [get_ports hex0_g]
set_property IOSTANDARD LVCMOS33 [get_ports hex0_g]