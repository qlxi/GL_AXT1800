#!/bin/sh

if [ -x "$(command -v opkg)" ]; then
    PACKAGE_MANAGER="opkg list-installed"
    echo "opkg package manager detected." >&2
elif [ -x "$(command -v apk)" ]; then
    PACKAGE_MANAGER="apk list --installed"
    echo "apk package manager detected." >&2
else
    echo "Could not find a valid package manager." >&2
    exit 1
fi

# Check for dependencies
if [ "$( $PACKAGE_MANAGER 2>/dev/null| grep -c "block-mount")" -ne '0' ] && [ "$( $PACKAGE_MANAGER 2>/dev/null| grep -c "e2fsprogs")" -ne '0' ] && [ "$( $PACKAGE_MANAGER 2>/dev/null| grep -c "kmod-usb-storage")" -ne '0' ] && [ "$( $PACKAGE_MANAGER 2>/dev/null| grep -c "kmod-fs-vfat")" -ne '0' ];then
  echo "Dependency check complete."
else
  echo "Missing dependencies. Please install: block-mount kmod-usb-storage kmod-fs-ext4 e2fsprogs kmod-fs-vfat"
  exit 1
fi

# List existing partitions
echo "Existing partitions are as follows:"
blkid /dev/mmcblk0* || blkid /dev/sd*

# Prompt user to select a partition, with a default
echo "Please select the partition to use (e.g., /dev/mmcblk0p1, default is /dev/mmcblk0p1):"
read partition

# If user input is empty, use the default value
if [ -z "$partition" ]; then
    partition="/dev/mmcblk0p1"
fi

# Prompt user to confirm formatting
echo "You have selected partition $partition. Formatting this partition will erase all data. Ensure no important files are on the entire USB/TF card."
echo "Are you sure you want to continue? (y/n)"
read confirmation

if [ "$confirmation" != "y" ]; then
    echo "Operation cancelled."
    exit 1
fi

# Unmount the partition
umount $partition

# Format the partition as ext4
mkfs.ext4 -F $partition

# Mount the partition
mount -t ext4 $partition /mnt

# Create temp directory and bind-mount the current root
mkdir /tmp/root
mount -o bind / /tmp/root

# Copy all files to the new partition
cp /tmp/root/* /mnt -a

# Wait 2 seconds
sleep 2s

# Unmount temp directory and new partition
umount /tmp/root
umount /mnt

# Update fstab configuration
block detect > /etc/config/fstab
uci set fstab.@mount[0].target='/overlay'
uci set fstab.@mount[0].enabled='1'
uci commit fstab

# Reboot system
reboot && echo "Rebooting..."
