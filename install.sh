#!/usr/bin/env bash

INSTALL_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DISK=/dev/sda

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

echo "localhost" > /etc/hostname

bootctl install
cp /usr/share/systemd/bootctl/arch.conf /boot/loader/entries/arch.conf
echo "default arch.conf" >> /boot/loader/loader.conf
echo "timeout 1" >> /boot/loader/loader.conf
systemctl enable systemd-boot-update

systemvtl enable fstrim.timer

useradd -m -G wheel video -s /bin/bash mantas

rsync -av --relative "$INSTALL_SCRIPT_DIR/root" /