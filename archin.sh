#!/bin/bash

# Форматирование разделов
mkfs.fat -F32 /dev/nvme0n1p6
mkfs.ext4 /dev/nvme0n1p9

# Монтирование
mount /dev/nvme0n1p9 /mnt
mkdir -p /mnt/boot/efi  # Создаем директорию перед монтированием
mount /dev/nvme0n1p6 /mnt/boot/efi

# Установка базовой системы
pacstrap -K /mnt base linux-zen linux-zen-headers linux-firmware

# Генерация fstab
genfstab -U /mnt >> /mnt/etc/fstab

# Выполняем команды в chroot через arch-chroot
arch-chroot /mnt << 'EOF'

# Установка пакетов
pacman -S --noconfirm nano sudo grub efibootmgr networkmanager

# Настройка времени
ln -sf /usr/share/zoneinfo/Europe/Moscow /etc/localtime
hwclock --systohc

# Локализация
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

# Пароль root
echo "Установка пароля root:"
passwd

# Создание пользователя
useradd -m -G wheel -s /bin/bash hz
echo "Установка пароля пользователя hz:"
passwd hz

# Настройка sudo
echo "%wheel ALL=(ALL:ALL) ALL" >> /etc/sudoers

# Установка GRUB
grub-install --target=x86_64-efi --efi-directory=/boot/efi
grub-mkconfig -o /boot/grub/grub.cfg

# Включение NetworkManager
systemctl enable NetworkManager

# Установка графических драйверов
pacman -S --noconfirm mesa vulkan-intel intel-compute-runtime intel-media-driver libva-utils

EOF

# Размонтирование и перезагрузка
umount -R /mnt
reboot
