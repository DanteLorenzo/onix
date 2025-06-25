#!/bin/bash

# Include logging functions
source "$(dirname "$0")/../utils/logging.sh"

log_info "Installing Hyprland and dependencies with pacman..."
sudo pacman -S --needed --noconfirm \
  base-devel hyprland hyprpaper waybar gdb ninja gcc cmake libxcb xcb-proto xcb-util \
  xcb-util-keysyms libxfixes libx11 libxcomposite xorg-xinput libxrender \
  pixman wayland-protocols cairo pango seatd libxkbcommon xcb-util-wm \
  xorg-xwayland cmake mesa git meson polkit
if [ $? -eq 0 ]; then
  log_success "Hyprland and dependencies installation complete."
else
  log_error "Hyprland and dependencies installation failed."
fi

