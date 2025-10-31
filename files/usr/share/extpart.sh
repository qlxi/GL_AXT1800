#!/bin/sh

if [ -x "$(command -v opkg)" ]; then
    PACKAGE_MANAGER="opkg list-installed"
    echo "opkg package manager detected." >&2
elif [ -x "$(command -v apk)" ]; then
    PACKAGE_MANAGER="apk list --installed"
    echo "apk package manager detected." >&2
else
    echo "No supported package manager (opkg, apk) found." >&2
    exit 1
fi

if [ "$( $PACKAGE_MANAGER 2>/dev/null| grep -c "block-mount")" -ne '0' ] && [ "$( $PACKAGE_MANAGER 2>/dev/null| grep -c "e2fsprogs")" -ne '0' ] && [ "$( $PACKAGE_MANAGER 2>/dev/null| grep -c "kmod-usb-storage")" -ne '0' ] && [ "$( $PACKAGE_MANAGER 2>/dev/null| grep -c "kmod-fs-vfat")" -ne '0' ];then
  echo "Required packages are installed."
else
  echo "Required packages are not installed. Please install: block-mount kmod-usb-storage kmod-fs-ext4 e2fsprogs kmod-fs-vfat"
  exit 1
fi

# List available block devices
echo "Available block devices:"
blkid /dev/mmcblk0* || blkid /dev/sd*

# Prompt user to enter the partition to be formatted
echo "Enter the partition to be formatted (e.g., /dev/mmcblk0p1, default is /dev/mmcblk0p1):"
read partition

# Set default partition if input is empty
if [ -z "$partition" ]; then
    partition="/dev/mmcblk0p1"
fi

# Warning message
echo "Warning: This will format $partition. All data will be lost. This script is intended for new installations and not for tf card overlays."
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

# Mount the new partition
mount -t ext4 $partition /mnt

# Create a temporary root mount
mkdir /tmp/root
# Bind mount the current root
mount -o bind / /tmp/root

# Copy all data from root to the new partition
cp /tmp/root/* /mnt -a

# Wait 2 seconds for copy to complete
sleep 2s

# Unmount temporary directories
umount /tmp/root
umount /mnt

# Configure fstab for the new overlay
block detect > /etc/config/fstab
uci set fstab.@mount[0].target='/overlay'
uci set fstab.@mount[0].enabled='1'
uci commit fstab

# Reboot
reboot && echo "Rebooting..."