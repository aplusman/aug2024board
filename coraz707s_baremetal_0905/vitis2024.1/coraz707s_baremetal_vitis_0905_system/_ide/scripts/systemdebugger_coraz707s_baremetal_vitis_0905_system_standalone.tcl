# Usage with Vitis IDE:
# In Vitis IDE create a Single Application Debug launch configuration,
# change the debug type to 'Attach to running target' and provide this 
# tcl script in 'Execute Script' option.
# Path of this script: /home/david/r09522848/vitis2024/coraz707s_baremetal_vitis_0905_system/_ide/scripts/systemdebugger_coraz707s_baremetal_vitis_0905_system_standalone.tcl
# 
# 
# Usage with xsct:
# To debug using xsct, launch xsct and run below command
# source /home/david/r09522848/vitis2024/coraz707s_baremetal_vitis_0905_system/_ide/scripts/systemdebugger_coraz707s_baremetal_vitis_0905_system_standalone.tcl
# 
connect -url tcp:127.0.0.1:3121
targets -set -nocase -filter {name =~"APU*"}
rst -system
after 3000
targets -set -filter {jtag_cable_name =~ "Digilent Cora Z7 - 7007S 210370BCC92CA" && level==0 && jtag_device_ctx=="jsn-Cora Z7 - 7007S-210370BCC92CA-13723093-0"}
fpga -file /home/david/r09522848/vitis2024/coraz707s_baremetal_vitis_0905/_ide/bitstream/design_1_wrapper.bit
targets -set -nocase -filter {name =~"APU*"}
loadhw -hw /home/david/r09522848/vitis2024/design_1_wrapper/export/design_1_wrapper/hw/design_1_wrapper.xsa -mem-ranges [list {0x40000000 0xbfffffff}] -regs
configparams force-mem-access 1
targets -set -nocase -filter {name =~"APU*"}
source /home/david/r09522848/vitis2024/coraz707s_baremetal_vitis_0905/_ide/psinit/ps7_init.tcl
ps7_init
ps7_post_config
targets -set -nocase -filter {name =~ "*A9*#0"}
dow /home/david/r09522848/vitis2024/coraz707s_baremetal_vitis_0905/Debug/coraz707s_baremetal_vitis_0905.elf
configparams force-mem-access 0
targets -set -nocase -filter {name =~ "*A9*#0"}
con
