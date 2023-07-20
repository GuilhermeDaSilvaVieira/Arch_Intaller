# (for BIOS systems only)
# parted /dev/vda -- mklabel msdos
# parted /dev/vda -- mkpart primary 1MB -16GB
# parted /dev/vda -- mkpart primary linux-swap -16GB 100%

# (for UEFI systems only)
parted /dev/vda -- mklabel gpt
parted /dev/vda -- mkpart primary 512MB -16GB
parted /dev/vda -- mkpart primary linux-swap -16GB 100%
parted /dev/vda -- mkpart ESP fat32 1MB 512MB
parted /dev/vda -- set 3 esp on

mkfs.ext4 -L nixos /dev/vda1
mkswap -L swap /dev/vda2
swapon /dev/vda2
mkfs.fat -F 32 -n boot /dev/vda3        # (for UEFI systems only)
mount /dev/disk/by-label/nixos /mnt
mkdir -p /mnt/boot                      # (for UEFI systems only)
mount /dev/disk/by-label/boot /mnt/boot # (for UEFI systems only)
nixos-generate-config --root /mnt
vim /mnt/etc/nixos/configuration.nix
nixos-install
reboot
