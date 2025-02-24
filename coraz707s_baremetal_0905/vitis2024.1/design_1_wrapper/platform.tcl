# 
# Usage: To re-create this platform project launch xsct with below options.
# xsct /home/david/r09522848/vitis2024/design_1_wrapper/platform.tcl
# 
# OR launch xsct and run below command.
# source /home/david/r09522848/vitis2024/design_1_wrapper/platform.tcl
# 
# To create the platform in a different location, modify the -out option of "platform create" command.
# -out option specifies the output directory of the platform project.

platform create -name {design_1_wrapper}\
-hw {/home/david/r09522848/vivado2024/coraz707s_baremetal_0905/xsa/design_1_wrapper.xsa}\
-out {/home/david/r09522848/vitis2024}

platform write
domain create -name {standalone_ps7_cortexa9_0} -display-name {standalone_ps7_cortexa9_0} -os {standalone} -proc {ps7_cortexa9_0} -runtime {cpp} -arch {32-bit} -support-app {empty_application}
platform generate -domains 
platform active {design_1_wrapper}
domain active {zynq_fsbl}
domain active {standalone_ps7_cortexa9_0}
platform generate -quick
platform generate
platform generate -domains standalone_ps7_cortexa9_0,zynq_fsbl 
