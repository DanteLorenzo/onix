#!/bin/bash

# Include logging functions
source "$(dirname "$0")/../utils/logging.sh"

log_info "Detecting system type..."

if [ -f /etc/debian_version ]; then
    log_success "Debian-based system detected"
    log_info "Updating package list..."
    sudo apt update
    log_info "Upgrading installed packages..."
    sudo apt upgrade -y
    log_info "Performing full system upgrade..."
    sudo apt full-upgrade -y
    log_info "Removing unused packages..."
    sudo apt autoremove -y
    log_info "Cleaning up cache..."
    sudo apt clean
elif [ -f /etc/arch-release ]; then
    log_success "Arch Linux-based system detected"
    log_info "Updating system and all packages..."
    sudo pacman -Syu --noconfirm
    log_info "Cleaning up package cache..."
    sudo pacman -Sc --noconfirm
else
    log_error "Could not detect system type. This script supports only Debian/Ubuntu and Arch Linux!"
    exit 1
fi

log_success "System update complete!"
exit 0 