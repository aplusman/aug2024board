# config.tcl
namespace eval config {
    variable origin_dir "."
    variable xilinx_proj_name "counter4bit_proj"
    variable fpga_part_name "xc7a35tcpg236-1"
    variable default_lib "xil_defaultlib"
    variable top_tb_name "tb_jk_4bit_counter"

    # jk_4bit_counter is targeted in testbench in xsim
    # variable top_source_name "jk_4bit_counter"

    # jk_counter_wrapper is an experiment structure
    variable top_source_name "jk_counter_wrapper"
}

namespace eval files {
    variable vhdl_rel_files {
        imports/jk_ff.vhd
        imports/jk_4bit_counter.vhd
        imports/hex7seg_display.vhd
        imports/button_debouncer.vhd
        imports/jk_counter_wrapper.vhd
    }	
    # variable ip_file "imports/xilinx_ip_0.xci"
    variable xdc_file "imports/constr/basys3.xdc"
    variable tb_file  "imports/xsim/tb_jk_4bit_counter.vhd"
}
