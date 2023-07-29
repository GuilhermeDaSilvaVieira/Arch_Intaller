# (for BIOS systems only)
parted /dev/sda -- mklabel msdos
parted /dev/sda -- mkpart primary 1MB -4GB
parted /dev/sda -- mkpart primary linux-swap -4GB 100%

mkfs.ext4 -L nixos /dev/sda1
mkswap -L swap /dev/sda2
swapon /dev/sda2
mount /dev/disk/by-label/nixos /mnt

git clone https://github.com/guilhermedasilvavieira/.setup

nixos-install --flake .#nami

reboot
