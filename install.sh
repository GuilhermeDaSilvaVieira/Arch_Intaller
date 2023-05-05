#! /bin/bash

# TODO: No input installer
# TODO: Minimal input installer

GREEN='\033[0;32m'
BLUE='\033[1;36m'
RED='\033[0;31m'
NO_COLOR='\033[0m'

is_uefi() {
	DIRECTORY_UEFI="/sys/firmware/efi/efivars/"
	if [ -d $DIRECTORY_UEFI ]; then
		echo -e "${GREEN}Supports UEFI${NO_COLOR}"
		echo ""
	else
		echo -e "${RED}Doesn't Support UEFI${NO_COLOR}"
		echo -e "${RED}This is a UEFI only script${NO_COLOR}"
		exit 0
	fi
}

partition(){
	# /boot/EFI [SWAP] /
	fdisk /dev/sda < fdisk_cmds  
	# /home
	fdisk /dev/nvme0n1 < home_fdisk_cmds 
}

format(){
	# System
	mkfs.ext4 /dev/sda3
	# Boot
	mkfs.fat -F32 /dev/sda1
	# Swap
	mkswap /dev/sda2
	# Home
	mkfs.ext4 /dev/nvme0n1p1
}

mount_disk(){
	# System
	mount /dev/sda3 /mnt
	# Boot
	mount --mkdir /dev/sda1 /mnt/boot/EFI
	# Swap
	swapon /dev/sda2
	# Home
	mount --mkdir /dev/nvme0n1p1 /mnt/home
	# Prints partition table
	lsblk -f
}

is_uefi
partition
format
mount_disk
# Change Keyboard
loadkeys br-abnt2
# Sync Time
timedatectl set-ntp true
# Install system foundation
pacstrap -K /mnt base linux linux-firmware
# Permanent mount partitions
genfstab -U /mnt >> /mnt/etc/fstab 
