#!/usr/bin/env bash

CONFIG_FILE="options.conf"

INSTALL_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DISK=/dev/sda

UUID=$(basename "$(readlink -f /dev/disk/by-uuid/* | grep "$DISK")")

if [ ! -f "$CONFIG_FILE" ]; then
    echo "Configuration file not found: $CONFIG_FILE"
    exit 1
fi

config=$(grep -v '^#' "$CONFIG_FILE" | awk -F= '{print $1"="$2}')
eval "$config"

setfont ter-128b
refector --latest 5 --sort rate --save /etc/pacman.d/mirrorlist

sgdisk -Z ${DISK}
sgdisk -a 2048 -o ${DISK}
sgdisk -n 1::+1G --typecode=1:ef00 --change-name=1:'EFIBOOT' ${DISK}
sgdisk -n 2::-0 --typecode=2:8300 --change-name=2:'ROOT' ${DISK}

partprobe ${DISK}

mkfs.vfat -F32 -n "EFIBOOT" ${DISK}1
mkfs.ext4 -L ROOT ${DISK}2
mount -t ext4 ${DISK}2 /mnt

mkdir -p /mnt/boot/efi
mount -t vfat -L EFIBOOT /mnt/boot/

pacstrap -K /mnt base linux linux-firmware sudo
genfstab -U /mnt >> /mnt/etc/fstab

arch-chroot /mnt
ln -sf /usr/share/zoneinfo/Europe/Vilnius /etc/localtime
hwclock --systohc

sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen

sed -i 's/^#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf
sed -i 's/^#Color/Color/' /etc/pacman.conf

echo "$HOSTNAME" > /etc/hostname

#
# Bootloader
#
bootctl install
echo "default arch.conf" >> /boot/loader/loader.conf
echo "timeout 1" >> /boot/loader/loader.conf

# Main entry
cp /usr/share/systemd/bootctl/arch.conf /boot/loader/entries/arch.conf
sed -i "s|root=PARTUUID=XXXX|PARTUUID=/dev/dev/disk/by-uuid/$UUID|" /boot/loader/entries/arch.conf
sed -i "s|roofstyoe=XXXX|roofstyoe=ext4|" /boot/loader/entries/arch.conf

# Fallback entry
cp /boot/loader/entries/arch.conf /boot/loader/entries/arch-fallback.conf
sed -i 's|/initramfs-linux.img|/initramfs-linux-fallback.img|' /boot/loader/entries/arch-fallback.conf

systemctl enable systemd-boot-update

systemctl enable fstrim.timer

useradd -m -G wheel video -s /bin/bash "$USER"

rsync -av --relative "$INSTALL_SCRIPT_DIR/root" /