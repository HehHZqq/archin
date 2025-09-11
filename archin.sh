mkfs.fat -F32 /dev/nvme0n1p6
mkfs.ext4 /dev/nvme0n1p9

mount /dev/nvme0n1p9 /mnt
mount --mkdir /dev/nvme0n1p6 /mnt/boot/efi

pacstrap -K /mnt base linux-zen linux-zen-headers linux-firmware
genfstab -U /mnt >> /mnt/etc/fstab
arch-chroot /mnt

# Установка необходимых пакетов
pacman -S nano sudo grub efibootmgr networkmanager

# Настройка времени (замените регион)
ln -sf /usr/share/zoneinfo/Europe/Moscow /etc/localtime
hwclock --systohc

# Локализация
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

# Пароль root
passwd

# Создание пользователя
useradd -m -G wheel -s /bin/bash hz
passwd hz

# Настройка sudo
EDITOR=nano visudo
# Раскомментируйте строку: %wheel ALL=(ALL:ALL) ALL


grub-install --target=x86_64-efi --efi-directory=/boot/efi
grub-mkconfig -o /boot/grub/grub.cfg

systemctl enable NetworkManager

pacman -S mesa vulkan-intel intel-compute-runtime intel-media-driver libva-utils

exit
umount -R /mnt
reboot
