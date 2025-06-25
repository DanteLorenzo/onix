#!/bin/bash

# Подключаем функции логирования
source "$(dirname "$0")/../utils/logging.sh"

# Выводим информационное сообщение о начале настройки
log_info "Setting up GRUB themes and configurations..."

# Копируем шрифты Terminus в директорию шрифтов GRUB
log_info "Copying Terminus font to GRUB fonts directory..."
sudo cp ./fonts/* /boot/grub/fonts/

# Копируем тему GRUB
log_info "Copying GRUB theme configuration..."
sudo cp ./configs/grub/ameli_theme.txt /boot/grub/themes/

# Редактируем /etc/default/grub
log_info "Updating /etc/default/grub with new theme and font..."
sudo cp /etc/default/grub /etc/default/grub.bak
sudo awk '!/^GRUB_THEME/ && !/^GRUB_FONT/' /etc/default/grub.bak | \
  sudo tee /etc/default/grub > /dev/null

echo 'GRUB_THEME="/boot/grub/themes/ameli_theme.txt"' | sudo tee -a /etc/default/grub > /dev/null
echo 'GRUB_FONT="/boot/grub/fonts/terminus-18.pf2"' | sudo tee -a /etc/default/grub > /dev/null

# Обновляем GRUB
log_info "Updating GRUB..."
sudo grub-mkconfig -o /boot/grub/grub.cfg

# Проверяем успешность обновления
if [ $? -eq 0 ]; then
    log_success "GRUB configuration updated successfully."
else
    log_error "Failed to update GRUB configuration. Check for errors above."
fi