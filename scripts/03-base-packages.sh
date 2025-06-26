#!/bin/bash

# Include logging functions
source "$(dirname "$0")/../utils/logging.sh"

# Base
log_info "Installing base packages with pacman..."
sudo pacman -S --needed --noconfirm base-devel gcc cmake git mesa gdb nano vim ninja vulkan-radeon timeshift firefox pipewire wireplumber pipewire-pulse pipewire-alsa

# Fonts
sudo pacman -S --noconfirm ttf-nerd-fonts-symbols ttf-font-awesome noto-fonts noto-fonts-emoji

if [ $? -eq 0 ]; then
  log_success "Base packages installation complete."
else
  log_error "Base packages installation failed."
fi

