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

time_and_locale(){
    # Links to your timezone
    ln -sf /mnt/usr/share/zoneinfo/America/Sao_Paulo /mnt/etc/localtime

    # generate /etc/adjtime
    arch-chroot /mnt hwclock --systohc

    # Set locale to br
    echo 'pt_BR.UTF-8 UTF-8' >> /mnt/etc/locale.gen
    arch-chroot /mnt locale-gen
    echo 'LANG=pt_BR.UTF-8' >> /mnt/etc/locale.conf
}

packages(){
    # Pacman config
    sed -i 's/#Color/Color/' /mnt/etc/pacman.conf
    sed -i 's/#ParallelDownloads/ParallelDownloads/' /mnt/etc/pacman.conf
    sed -i "/\[multilib\]/,/Include/"'s/^#//' /mnt/etc/pacman.conf

    # Install all needed packages
    arch-chroot /mnt pacman -Sy --noconfirm --needed - < packages.txt
}

grub(){
    # Set timeout = 0
    sed -i 's/GRUB_TIMEOUT=5/GRUB_TIMEOUT=0/' /mnt/etc/default/grub
    # Enable os-prober
    sed -i 's/\#GRUB_DISABLE_OS_PROBER/GRUB_DISABLE_OS_PROBER/' /mnt/etc/default/grub

    # Mount boot/EFI partition
    arch-chroot /mnt mount --mkdir /dev/sda1 /boot/EFI

    # Print partition table
    arch-chroot /mnt lsblk -f

    # Install grub with uefi
    arch-chroot /mnt grub-install --target=x86_64-efi --bootloader-id=grub_uefi --recheck
    arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg
}

systems(){
    # Enable internet, VM, Printing, Bluetooth
    for system in NetworkManager libvirtd cups bluetooth;
    do
        arch-chroot /mnt systemctl enable $system
    done
}

create_user(){
    for user in work fun;
    do
        arch-chroot /mnt useradd -m -G wheel,audio,video,optical,storage,libvirt -s /bin/fish $user
        echo $user:1234 >> passwords.txt
    done
}

aur(){
    # Install Paru
    arch-chroot -u work /mnt sh -c '
    cd /home/work;
    rustup default stable;
    git clone https://aur.archlinux.org/paru-bin.git;
    cd paru-bin;
    makepkg -si;
    cd ..;
    rm paru-bin -rf;
    '

    # Paru config
    sed -i 's/\#BottomUp/BottomUp/' /mnt/etc/paru.conf
    sed -i 's/\#RemoveMake/RemoveMake/' /mnt/etc/paru.conf
    sed -i 's/\#CleanAfter/CleanAfter/' /mnt/etc/paru.conf
    sed -i 's/\#\[bin\]/\[bin\]/' /mnt/etc/paru.conf
    sed -i 's/\#FileManager = vifm/FileManager = lf/' /mnt/etc/paru.conf
    sed -i 's/\#Sudo = doas/Sudo = \/bin\/doas/' /mnt/etc/paru.conf

    # Install aur packages
    cp -v aur_packages.txt /mnt/home/work/
    arch-chroot -u work /mnt sh -c '
    cd /home/work;
    paru --noconfirm --needed -S - < aur_packages.txt;
    '
}

x11_keymap(){
    # Change keyboard to br
    arch-chroot -u work /mnt sh -c '
    cd /home/work;
    localectl set-x11-keymap br;
    '
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
time_and_locale
# Set console keyboard to br
echo 'KEYMAP=br-abnt2' >> /mnt/etc/vconsole.conf
# Host name
echo 'arch' >> /mnt/etc/hostname
packages
# Only the group wheel has superuser permission
echo 'permit keepenv persist :wheel' >> /mnt/etc/doas.conf
# Blacklists nouveau in case nvidia-utils doesn't
echo 'blacklist nouveau' >> /mnt/etc/modprobe.d/blacklist.conf
# Change shell to fish
arch-chroot /mnt chsh -s /bin/fish
grub
systems
create_user
# Root password
echo root:1234 >> passwords.txt
# Copy passwords to new system
cp -v passwords.txt /mnt
# User Passowrds
arch-chroot /mnt chpasswd < passwords.txt
# Ensure blacklist works
arch-chroot /mnt mkinitcpio -P
# Save any logs in home
cp -v *.log /mnt/home/work/
aur
x11_keymap
