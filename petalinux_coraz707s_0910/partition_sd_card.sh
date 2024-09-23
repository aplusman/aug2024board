#!/bin/bash

# Define the device
DEVICE="/dev/sdb"

# Define the Path to store the related images
ImagePath="/home/david/r09522848/petalinux2024/coraz707s_0909/plnx_coraz070s_0910/images/linux"

# Unmount the existing partition if it's mounted
echo "Unmounting existing partitions..."
sudo umount ${DEVICE}1 2>/dev/null || true

# Create a new GPT partition table
echo "Creating GPT partition table..."
sudo parted -s ${DEVICE} mklabel gpt

# Create the first partition (BOOT) with 4 MB alignment, size of 1 GB
echo "Creating 1 GB FAT32 partition..."
sudo parted -s ${DEVICE} mkpart primary fat32 4MiB 1004MiB

# Create the second partition (RootFS) using the remaining space
echo "Creating EXT4 partition with remaining space..."
sudo parted -s ${DEVICE} mkpart primary ext4 1004MiB 100%

# Set the boot flag for the first partition
echo "Setting boot flag on the first partition..."
sudo parted -s ${DEVICE} set 1 boot on

# Format the first partition as FAT32 and label it BOOT
echo "Formatting the first partition as FAT32..."
sudo mkfs.fat -F 32 -n "BOOT" ${DEVICE}1

# Format the second partition as EXT4 and label it RootFS
echo "Formatting the second partition as EXT4..."
sudo mkfs.ext4 -F -L "RootFS" ${DEVICE}2

# (Optional) Create mount points
echo "Creating mount points..."
sudo mkdir -p /mnt/boot
sudo mkdir -p /mnt/rootfs

# Mount the partitions
echo "Mounting partitions..."
sudo mount ${DEVICE}1 /mnt/boot
sudo mount ${DEVICE}2 /mnt/rootfs

# Copy files to the FAT partition (BOOT)
# Uncomment and replace the following lines with actual file paths
echo "Copying files to the FAT32 partition..."
# Reference: https://docs.amd.com/r/en-US/ug1144-petalinux-tools-reference-guide/Copying-Image-Files
# sudo cp /path/to/BOOT.BIN /mnt/boot/
# sudo cp /path/to/boot.scr /mnt/boot/
# sudo cp /path/to/Image /mnt/boot/
# sudo cp /path/to/ramdisk.cpio.gz.u-boot /mnt/boot/
sudo cp ${ImagePath}/BOOT.BIN  /mnt/boot/
sudo cp ${ImagePath}/boot.scr /mnt/boot/

# Copy files to the EXT4 partition (RootFS)
# Uncomment and replace the following line with actual path to the root filesystem tarball
echo "Extracting root filesystem to EXT4 partition..."
# sudo tar -xzvf /path/to/rootfs.tar.gz -C /mnt/rootfs/
sudo tar -xzf ${ImagePath}/rootfs.tar.gz -C /mnt/rootfs/

# Unmount the partitions
echo "Unmounting partitions..."
sudo umount /mnt/boot
sudo umount /mnt/rootfs

# Remove the mount points (optional)
echo "Removing mount points..."
sudo rmdir /mnt/boot
sudo rmdir /mnt/rootfs

echo "Partitioning and formatting complete."

