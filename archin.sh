#!/bin/bash

# Запрос информации у пользователя
read -p "Enter PC name (hostname): " hostname
read -sp "Enter root password: " root_password
echo
read -p "Enter username: " username
read -sp "Enter user's password: " user_password
echo

# Форматирование разделов
mkfs.fat -F32 /dev/nvme0n1p6
mkfs.ext4 /dev/nvme0n1p7

# Монтирование
mount /dev/nvme0n1p7 /mnt
mkdir -p /mnt/boot/efi
mount /dev/nvme0n1p6 /mnt/boot/efi

# Установка базовой системы
pacstrap -K /mnt base linux-zen linux-zen-headers linux-firmware

# Генерация fstab
genfstab -U /mnt >> /mnt/etc/fstab

# Создание скрипта для выполнения внутри chroot
cat > /mnt/install_chroot.sh << EOF
#!/bin/bash

# Установка пакетов
pacman -S --noconfirm nano sudo grub efibootmgr networkmanager bluez bluez-utils pipewire pipewire-pulse pipewire-alsa

# Настройка времени
ln -sf /usr/share/zoneinfo/Europe/Moscow /etc/localtime
hwclock --systohc

# Локализация
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

# Настройка хоста
echo "$hostname" > /etc/hostname

# Установка пароля root
echo "root:$root_password" | chpasswd

# Создание пользователя
useradd -m -G wheel -s /bin/bash $username
echo "$username:$user_password" | chpasswd

# Настройка sudo
echo "%wheel ALL=(ALL:ALL) ALL" >> /etc/sudoers

# Установка GRUB
grub-install --target=x86_64-efi --efi-directory=/boot/efi
grub-mkconfig -o /boot/grub/grub.cfg

# Включение сервисов
systemctl enable NetworkManager
systemctl enable bluetooth

# Установка графических драйверов
pacman -S --noconfirm mesa vulkan-intel intel-compute-runtime intel-media-driver libva-utils

# Очистка
rm /install_chroot.sh
EOF

# Выполнение скрипта внутри chroot
chmod +x /mnt/install_chroot.sh
arch-chroot /mnt /install_chroot.sh

# Размонтирование и перезагрузка
umount -R /mnt
reboot
