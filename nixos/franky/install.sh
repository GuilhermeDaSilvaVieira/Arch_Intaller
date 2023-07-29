# (for UEFI systems only)
parted /dev/vda -- mklabel gpt
parted /dev/vda -- mkpart primary 512MB -4GB
parted /dev/vda -- mkpart primary linux-swap -4GB 100%
parted /dev/vda -- mkpart ESP fat32 1MB 512MB
parted /dev/vda -- set 3 esp on

mkfs.ext4 -L nixos /dev/vda1
mkswap -L swap /dev/vda2
swapon /dev/vda2
mount /dev/disk/by-label/nixos /mnt
mkfs.fat -F 32 -n boot /dev/vda3
mkdir -p /mnt/boot
mount /dev/disk/by-label/boot /mnt/boot

lsblk -f
read

git clone https://github.com/guilhermedasilvavieira/.setup

nixos-install --flake .setup#franky

reboot
