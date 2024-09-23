# Petalinux

```
source /Xilinx/PetaLinux/2024.1/tool/settings.sh
petalinux-create -t project -n plnx_coraz070s_0909 --template zynq --tmpdir ~/r09522848/petalinux2024/coraz707s_0909/
petalinux-config --get-hw-description=/home/david/Downloads/design_1_wrapper.xsa
petalinux-create apps -n app-test-01 --template c --enable
petalinux-build
```

## Environment
* On the [AMD Download Website](https://www.xilinx.com/support/download/index.html/content/xilinx/en/downloadNav/embedded-design-tools.html), Download two files: 
	- arm sstate-cache (TAR/GZIP - 12.14 GB) 
	- Downloads (TAR/GZIP - 53.48 GB) 
	- For example, sstate mirrors for Zynq 7000 SoCs are <b>arm</b> mirror servers. 
* Extract the above two *.tar.gz files. 
* Refer to the website: https://docs.amd.com/r/en-US/ug1144-petalinux-tools-reference-guide/Build-Optimizations
* Set source mirrors
	- petalinux-config > Yocto-settings > Add pre-mirror URL
	- file:///home/david/r09522848/petalinux2024/downloads/downloads
* Disable the network sstate feeds to reduce the build time
	- petalinux-config > Yocto Settings > Enable Network sstate feeds (<b>de</b>-select it).
* Set sstate feeds
	- petalinux-config > Yocto Settings > Local sstate feeds settings ---> local sstate feeds url 
	- file:///home/david/r09522848/petalinux2024/downloads/arm
* Disable BB Network
	- petalinux-config > Yocto Settings > Enable BB NO NETWORK
* Set the temporary location
	- petalinux-config > Yocto Settings > TEMPDIR Location >
	- ${PROOT}/build/tmp
* Using External Kernel and U-Boot with PetaLinux [Document](https://docs.amd.com/r/en-US/ug1144-petalinux-tools-reference-guide/Using-External-Kernel-and-U-Boot-with-PetaLinux)
```
cd ~/r09522848/petalinux2024/coraz707s_0909/plnx_coraz070s_0909/components/ext_sources
git clone --branch xlnx_rebase_v2024.01 https://github.com/Xilinx/u-boot-xlnx.git
git clone --branch xlnx_rebase_v6.6_LTS https://github.com/Xilinx/linux-xlnx.git
```
And then, 
	- Linux Components Selection > linux-kernel > ext-local-src
	- Linux Components Selection > External linux-kernel local source settings >
	- file:///home/david/r09522848/petalinux2024/coraz707s_0909/plnx_coraz070s_0909/components/ext_sources/linux-xlnx
	- Linux Components Selection > u-boot > ext-local-src
	- Linux Components Selection > External u-boot local source settings >
	- file:///home/david/r09522848/petalinux2024/coraz707s_0909/plnx_coraz070s_0909/components/ext_sources/u-boot-xlnx
* Device tree
	- petalinux-config > Auto Config Settings > Specify a manual device tree include directory 
	- ${PROOT}/components/ext_sources/linux-xlnx/arch/arm/include
* petalinux-build
* petalinux-package boot --u-boot --kernel --force
---

# Partition the SD card

```
#!/bin/bash

# Define the device
DEVICE="/dev/sdb"

# Unmount the existing partition if it's mounted
sudo umount ${DEVICE}1

# Create a new GPT partition table
sudo parted -s ${DEVICE} mklabel gpt

# Create the first partition (BOOT) with 4 MB alignment, size at least 500 MB
sudo parted -s ${DEVICE} mkpart primary fat32 4MiB 504MiB

# Create the second partition (RootFS) with the remaining space
sudo parted -s ${DEVICE} mkpart primary ext4 504MiB 100%

# Set the boot flag for the first partition
sudo parted -s ${DEVICE} set 1 boot on

# Format the first partition as FAT32 and label it BOOT
sudo mkfs.fat -F 32 -n "BOOT" ${DEVICE}1

# Format the second partition as EXT4 and label it RootFS
sudo mkfs.ext4 -F -L "RootFS" ${DEVICE}2

# (Optional) Create mount points
sudo mkdir -p /mnt/boot
sudo mkdir -p /mnt/rootfs

# Mount the partitions
sudo mount ${DEVICE}1 /mnt/boot
sudo mount ${DEVICE}2 /mnt/rootfs

# Copy files to the FAT partition (BOOT)
# Make sure to replace these paths with the actual paths to your files
# sudo cp /path/to/BOOT.BIN /mnt/boot/
# sudo cp /path/to/boot.scr /mnt/boot/
# sudo cp /path/to/Image /mnt/boot/
# sudo cp /path/to/ramdisk.cpio.gz.u-boot /mnt/boot/

# Copy files to the EXT4 partition (RootFS)
# Extract the root filesystem archive (replace with actual path to the tarball)
# sudo tar -xzvf /path/to/rootfs.tar.gz -C /mnt/rootfs/

# Unmount the partitions
sudo umount /mnt/boot
sudo umount /mnt/rootfs

# Remove the mount points (optional)
sudo rmdir /mnt/boot
sudo rmdir /mnt/rootfs

```

---

# References
https://docs.amd.com/r/en-US/ug1144-petalinux-tools-reference-guide/PetaLinux-Commands
