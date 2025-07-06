#!/bin/bash

# Include logging functions
source "$(dirname "$0")/../utils/logging.sh"

log_info "Starting GNOME customization..."

# Verify GNOME environment
if ! command -v gsettings &>/dev/null; then
    log_error "gsettings not found. This script requires GNOME desktop."
    exit 1
fi

if [ "$XDG_CURRENT_DESKTOP" != "GNOME" ]; then
    log_warning "Not running in GNOME session (XDG_CURRENT_DESKTOP=$XDG_CURRENT_DESKTOP)"
fi

# Set wallpaper and avatar
set_wallpaper_avatar() {
    local wallpaper_path="$HOME/Pictures/Wallpapers/default.jpg"
    local avatar_path="$HOME/Pictures/Avatars/default.png"
    
    # Set wallpaper for user session
    if [ -f "$wallpaper_path" ]; then
        log_info "Setting wallpaper from $wallpaper_path"
        gsettings set org.gnome.desktop.background picture-uri "file://$wallpaper_path"
        gsettings set org.gnome.desktop.background picture-uri-dark "file://$wallpaper_path"
        gsettings set org.gnome.desktop.screensaver picture-uri "file://$wallpaper_path"
        log_success "User wallpaper set successfully"
        
        # Set the same wallpaper for GDM login screen (requires sudo)
        local gdm_wallpaper="/usr/share/gnome-background-properties/custom-wallpaper.jpg"
        log_info "Setting login screen wallpaper..."
        if sudo cp "$wallpaper_path" "$gdm_wallpaper"; then
            sudo chmod 644 "$gdm_wallpaper"
            sudo dbus-launch gsettings set org.gnome.desktop.background picture-uri "file://$gdm_wallpaper"
            log_success "Login screen wallpaper set successfully"
        else
            log_error "Failed to set login screen wallpaper (permission issue?)"
        fi
    else
        log_warning "Wallpaper not found at $wallpaper_path"
    fi
    
    # Set avatar
    if [ -f "$avatar_path" ]; then
        log_info "Setting user avatar from $avatar_path"
        local avatar_dir="/var/lib/AccountsService/icons"
        local avatar_dest="$avatar_dir/$(id -un)"
        
        # Create directory if needed
        if [ ! -d "$avatar_dir" ]; then
            sudo mkdir -p "$avatar_dir"
            sudo chmod 755 "$avatar_dir"
        fi
        
        # Copy avatar (requires sudo)
        if sudo cp "$avatar_path" "$avatar_dest"; then
            sudo chmod 644 "$avatar_dest"
            log_success "Avatar set successfully"
        else
            log_error "Failed to set avatar (permission issue?)"
        fi
    else
        log_warning "Avatar not found at $avatar_path"
    fi
}

# [Остальная часть скрипта остается без изменений...]