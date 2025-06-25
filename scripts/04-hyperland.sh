#!/bin/bash

# Include logging functions
source "$(dirname "$0")/../utils/logging.sh"

log_info "Installing Hyprland and dependencies with pacman..."
sudo pacman -Rs --needed --noconfirm  cmake hyprland kitty git mesa gdb ninja libxcb xcb-proto xcb-util libx11 libxfixes libxcomposite xorg-xinput libxrender wayland-protocols xcb-util-keysyms xcb-util-wm cairo polkit meson seatd libxkbcommon vulkan-radeon

#     hyprpaper waybar wofi alacritty
if [ $? -eq 0 ]; then
  log_success "Hyprland and dependencies installation complete."
  
  # Copy config folders to ~/.config, overwriting if they exist
  for folder in alacritty hypr hyprpaper waybar wofi; do
    src_dir="$(dirname "$0")/../configs/$folder"
    dest_dir="$HOME/.config/$folder"
    rm -rf "$dest_dir"
    cp -r "$src_dir" "$HOME/.config/"
    log_info "Copied $folder config to ~/.config/"
  done
else
  log_error "Hyprland and dependencies installation failed."
fi

