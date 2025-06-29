#!/bin/bash

# Include logging functions
source "$(dirname "$0")/../utils/logging.sh"

log_info "Installing Hyprland and dependencies with pacman..."
sudo pacman -Sy --needed --noconfirm hyprland kitty waybar hyprpaper bc brightnessctl dunst libnotify pipewire wireplumber pipewire-pulse pipewire-alsa pavucontrol alacritty nautilus fastfetch hyprlock
# libxcb xcb-proto xcb-util libx11 libxfixes libxcomposite xorg-xinput libxrender wayland-protocols xcb-util-keysyms xcb-util-wm cairo polkit meson seatd libxkbcommon

#   wofi

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
  # After copying all folders, make all .sh scripts in ~/.config/*/scripts/ executable
  find "$HOME/.config" -type f -path '*/scripts/*.sh' -exec chmod +x {} \;
  log_info "Set executable permissions for all scripts in ~/.config/*/scripts/"
else
  log_error "Hyprland and dependencies installation failed."
fi

# Reload Hyprland config if Hyprland is running
if pgrep -x "Hyprland" > /dev/null; then
  hyprctl reload
  log_info "Hyprland config reloaded."
else
  log_info "Hyprland is not running, config not reloaded."
fi

