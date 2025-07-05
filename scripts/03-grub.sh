#!/bin/bash

# Include logging functions
source "$(dirname "$0")/../utils/logging.sh"

# Display an informational message about the start of the setup
log_info "Setting up GRUB themes and configurations..."

# Create directories if they don't exist
log_info "Creating necessary directories..."
sudo mkdir -p /boot/grub2/fonts/
sudo mkdir -p /boot/grub2/themes/

# Verify directories were created
if [ ! -d "/boot/grub2/fonts" ] || [ ! -d "/boot/grub2/themes" ]; then
    log_error "Failed to create required directories"
    exit 1
fi

# Copy Terminus fonts to the GRUB fonts directory
log_info "Copying Terminus font to GRUB fonts directory..."
if sudo cp ./fonts/* /boot/grub2/fonts/; then
    log_success "Fonts copied successfully"
else
    log_error "Failed to copy fonts"
    exit 1
fi

# Copy the GRUB theme
log_info "Copying GRUB theme configuration..."
if sudo cp ./configs/grub/AmeliTheme.txt /boot/grub2/themes/; then
    log_success "Theme copied successfully"
else
    log_error "Failed to copy theme"
    exit 1
fi

# Edit /etc/default/grub
log_info "Updating /etc/default/grub with new theme and font..."
sudo cp /etc/default/grub /etc/default/grub.bak
sudo awk '!/^GRUB_THEME/ && !/^GRUB_FONT/' /etc/default/grub.bak | \
sudo tee /etc/default/grub > /dev/null

echo 'GRUB_THEME="/boot/grub2/themes/AmeliTheme.txt"' | sudo tee -a /etc/default/grub > /dev/null
echo 'GRUB_FONT="/boot/grub2/fonts/terminus-30.pf2"' | sudo tee -a /etc/default/grub > /dev/null

# Update GRUB (Fedora-specific)
log_info "Updating GRUB configuration..."
if command -v grub2-mkconfig >/dev/null 2>&1; then
    if sudo grub2-mkconfig -o /boot/grub2/grub.cfg; then
        log_success "GRUB configuration updated successfully."
    else
        log_error "Failed to update GRUB configuration. Check for errors above."
        exit 1
    fi
else
    log_error "grub2-mkconfig command not found. Is GRUB installed?"
    exit 1
fi

log_success "GRUB theme installation completed!"