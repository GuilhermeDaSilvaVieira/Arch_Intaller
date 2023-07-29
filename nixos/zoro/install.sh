# (for UEFI systems only)
parted /dev/sda -- mklabel gpt
parted /dev/sda -- mkpart primary 512MB -16GB
parted /dev/sda -- mkpart primary linux-swap -16GB 100%
parted /dev/sda -- mkpart ESP fat32 1MB 512MB
parted /dev/sda -- set 3 esp on

mkfs.ext4 -L nixos /dev/sda1
mkswap -L swap /dev/sda2
swapon /dev/sda2
mount /dev/disk/by-label/nixos /mnt
mkfs.fat -F 32 -n boot /dev/sda3
mkdir -p /mnt/boot
mount /dev/disk/by-label/boot /mnt/boot
# mkfs.ext4 -L home /dev/nvme0n1p1
mkdir -p /mnt/home
mount /dev/disk/by-label/home /mnt/home

lsblk -f
read

git clone https://github.com/guilhermedasilvavieira/.setup

nixos-install --flake .setup#zoro

reboot
