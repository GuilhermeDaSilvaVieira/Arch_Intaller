#! /bin/bash

# TODO: No input installer
# TODO: Minimal input installer

GREEN='\033[0;32m'
BLUE='\033[1;36m'
RED='\033[0;31m'
NO_COLOR='\033[0m'

CHROOT="arch-chroot /mnt"

# Cleanup from previous runs.
cleanup(){
    swapoff /dev/sda2
    umount -R /mnt
}

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
    $CHROOT hwclock --systohc

    # Set locale to br
    echo 'pt_BR.UTF-8 UTF-8' >> /mnt/etc/locale.gen
    $CHROOT locale-gen
    echo 'LANG=pt_BR.UTF-8' >> /mnt/etc/locale.conf
}

packages(){
    # Pacman config
    sed -i 's/#Color/Color/' /mnt/etc/pacman.conf
    sed -i 's/#ParallelDownloads/ParallelDownloads/' /mnt/etc/pacman.conf
    sed -i "/\[multilib\]/,/Include/"'s/^#//' /mnt/etc/pacman.conf

    # Install all needed packages
    $CHROOT pacman -Sy --noconfirm --needed - < packages.txt
}

grub(){
    # Set timeout = 0
    sed -i 's/GRUB_TIMEOUT=5/GRUB_TIMEOUT=0/' /mnt/etc/default/grub
    # Enable os-prober
    sed -i 's/\#GRUB_DISABLE_OS_PROBER/GRUB_DISABLE_OS_PROBER/' /mnt/etc/default/grub

    # Mount boot/EFI partition
    $CHROOT mount --mkdir /dev/sda1 /boot/EFI

    # Print partition table
    $CHROOT lsblk -f

    # Install grub with uefi
    $CHROOT grub-install --target=x86_64-efi --bootloader-id=grub_uefi --recheck
    $CHROOT grub-mkconfig -o /boot/grub/grub.cfg
}

systems(){
    # Enable internet, VM, Printing, Bluetooth
    for system in NetworkManager libvirtd cups bluetooth;
    do
        $CHROOT systemctl enable $system
    done
}

create_user(){
    for user in work fun;
    do
        $CHROOT useradd -m -G wheel,audio,video,optical,storage,libvirt -s /bin/fish $user
        echo $user:1234 >> passwords.txt
    done
}

aur(){
    arch-chroot -u work /mnt sh -c "
    cd /home/work;
    git clone https://aur.archlinux.org/paru-bin.git;
    cd paru-bin;
    makepkg -sri --noconfirm;
    cd /home/work;
    rm -rf paru-bin;
    "

    # Paru config
    sed -i 's/\#BottomUp/BottomUp/' /mnt/etc/paru.conf
    sed -i 's/\#RemoveMake/RemoveMake/' /mnt/etc/paru.conf
    sed -i 's/\#CleanAfter/CleanAfter/' /mnt/etc/paru.conf
    sed -i 's/\#\[bin\]/\[bin\]/' /mnt/etc/paru.conf
    sed -i 's/\#FileManager = vifm/FileManager = lf/' /mnt/etc/paru.conf
    sed -i 's/\#Sudo = doas/Sudo = \/bin\/doas/' /mnt/etc/paru.conf

    # Install aur packages
    cp -v aur_packages.txt /mnt
    echo "paru --noconfirm --needed -S - < aur_packages.txt" | $CHROOT su work
    rm /mnt/aur_packages.txt
}

# Make startx works with awesome
setup_startx(){
    for user in work fun;
    do
        echo "cp /etc/X11/xinit/xinitrc ~/.xinitrc &&
        head -n -5 ~/.xinitrc > ~/temp &&
        echo 'exec awesome' >> ~/temp &&
        mv ~/temp ~/.xinitrc" | $CHROOT su $user
    done
}

setup_default_apps(){
    for user in work fun;
    do
        echo "xdg-mime default org.pwmt.zathura.desktop application/pdf &&
            xdg-mime default librewolf.desktop x-scheme-handler/https &&
        xdg-mime default librewolf.desktop x-scheme-handler/http" | $CHROOT su $user
    done
}

dotfiles(){
    for user in root work fun;
    do
        echo "cd ~/ &&
        git clone https://github.com/guilhermedasilvavieira/.dotfiles &&
        .dotfiles/install.sh" | $CHROOT su $user
    done
}

is_uefi
cleanup
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
$CHROOT chsh -s /bin/fish
grub
systems
create_user
# Root password
echo root:1234 >> passwords.txt
# User Passowrds
cp -v passwords.txt /mnt
$CHROOT chpasswd < passwords.txt
rm /mnt/passwords.txt
# Ensure blacklist works
$CHROOT mkinitcpio -P
# Set stable rust
echo "rustup default stable" | $CHROOT su work
aur
# Change keyboard to br
echo "localectl set-x11-keymap br" | $CHROOT su work
setup_startx
setup_default_apps
dotfiles
# Save any logs
cp -v *.log /mnt
