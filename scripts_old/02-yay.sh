#!/bin/bash

# Include logging functions
source "$(dirname "$0")/../utils/logging.sh"

log_info "Checking if yay is already installed..."
if command -v yay >/dev/null 2>&1; then
    log_success "yay is already installed. Skipping installation."
    exit 0
fi

log_info "Installing dependencies (git, base-devel)..."
sudo pacman -S --needed --noconfirm git base-devel

log_info "Cloning yay repository from AUR..."
git clone https://aur.archlinux.org/yay.git /tmp/yay

log_info "Building and installing yay..."
cd /tmp/yay && makepkg -si --noconfirm

log_info "Cleaning up..."
cd ~
rm -rf /tmp/yay

log_success "yay installation complete!"