#!/usr/bin/env bash

setfont ter-128b
refector --latest 5 --sort rate --save /etc/pacman.d/mirrorlist

sgdisk -Z ${DISK}
sgdisk -a 2048 -o ${DISK}
sgdisk -n 1::+300M --typecode=1:ef00 --change-name=1:'EFIBOOT' ${DISK}
sgdisk -n 2::-0 --typecode=2:8300 --change-name=2:'ROOT' ${DISK}

partprobe ${DISK}

mkfs.vfat -F32 -n "EFIBOOT" ${DISK}1
mkfs.ext4 -L ROOT ${DISK}2
mount -t ext4 ${DISK}2 /mnt

mkdir -p /mnt/boot/efi
mount -t vfat -L EFIBOOT /mnt/boot/

pacstrap /mnt base
genfstab -L /mnt >> /mnt/etc/fstab
