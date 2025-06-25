#!/bin/bash

# Include logging functions
source "$(dirname "$0")/../utils/logging.sh"

# Display an informational message about the start of the setup
log_info "Setting up GRUB themes and configurations..."

# Copy Terminus fonts to the GRUB fonts directory
log_info "Copying Terminus font to GRUB fonts directory..."
sudo cp ./fonts/* /boot/grub/fonts/

# Copy the GRUB theme
log_info "Copying GRUB theme configuration..."
sudo cp ./configs/grub/AmeliTheme.txt /boot/grub/themes/

# Edit /etc/default/grub
log_info "Updating /etc/default/grub with new theme and font..."
sudo cp /etc/default/grub /etc/default/grub.bak
sudo awk '!/^GRUB_THEME/ && !/^GRUB_FONT/' /etc/default/grub.bak | \
  sudo tee /etc/default/grub > /dev/null

echo 'GRUB_THEME="/boot/grub/themes/AmeliTheme.txt"' | sudo tee -a /etc/default/grub > /dev/null
echo 'GRUB_FONT="/boot/grub/fonts/terminus-30.pf2"' | sudo tee -a /etc/default/grub > /dev/null

# Update GRUB
log_info "Updating GRUB..."
sudo grub-mkconfig -o /boot/grub/grub.cfg

# Check if the update was successful
if [ $? -eq 0 ]; then
    log_success "GRUB configuration updated successfully."
else
    log_error "Failed to update GRUB configuration. Check for errors above."
fi