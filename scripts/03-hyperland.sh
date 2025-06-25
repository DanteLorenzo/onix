#!/bin/bash

# Include logging functions
source "$(dirname "$0")/../utils/logging.sh"

log_info "Installing Hyprland and dependencies with pacman..."
sudo pacman -S --needed --noconfirm \
  base-devel hyprland hyprpaper waybar wofi alacritty gdb ninja gcc cmake libxcb xcb-proto xcb-util \
  xcb-util-keysyms libxfixes libx11 libxcomposite xorg-xinput libxrender \
  pixman wayland-protocols cairo pango seatd libxkbcommon xcb-util-wm \
  xorg-xwayland cmake mesa git meson polkit
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

