#!/bin/bash

# Include logging functions
source "$(dirname "$0")/../utils/logging.sh"

# Base
log_info "Installing base packages with pacman..."
sudo pacman -S --needed --noconfirm base-devel gcc cmake git mesa mesa-utils gdb nano vim ninja vulkan-radeon vulkan-tools timeshift xorg-xkbcomp jq btop htop networkmanager bluez bluez-utils blueman

# Start bluetooth
sudo systemctl enable bluetooth.service --now

# Fonts
sudo pacman -S --needed --noconfirm ttf-nerd-fonts-symbols ttf-font-awesome noto-fonts noto-fonts-emoji ttf-hack-nerd

if [ $? -eq 0 ]; then
  log_success "Base packages installation complete."
else
  log_error "Base packages installation failed."
fi

