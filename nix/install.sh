# (for BIOS systems only)
# parted /dev/sda -- mklabel msdos
# parted /dev/sda -- mkpart primary 1MB -16GB
# parted /dev/sda -- mkpart primary linux-swap -16GB 100%

# (for UEFI systems only)
parted /dev/sda -- mklabel gpt
parted /dev/sda -- mkpart primary 512MB -16GB
parted /dev/sda -- mkpart primary linux-swap -16GB 100%
parted /dev/sda -- mkpart ESP fat32 1MB 512MB
parted /dev/sda -- set 3 esp on

mkfs.ext4 -L nixos /dev/sda1
mkswap -L swap /dev/sda2
swapon /dev/sda2
mkfs.fat -F 32 -n boot /dev/sda3        # (for UEFI systems only)
mount /dev/disk/by-label/nixos /mnt
mkdir -p /mnt/boot                      # (for UEFI systems only)
mount /dev/disk/by-label/boot /mnt/boot # (for UEFI systems only)
nixos-generate-config --root /mnt
vim /mnt/etc/nixos/configuration.nix
nixos-install
reboot
