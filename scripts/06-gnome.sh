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
    else
        log_warning "Wallpaper not found at $wallpaper_path"
    fi
    
    # Set avatar
    if [ -f "$avatar_path" ]; then
        log_info "Setting user avatar from $avatar_path"
        local avatar_dir="/var/lib/AccountsService/icons"
        local avatar_dest="$avatar_dir/$(id -un)"
        
        if [ ! -d "$avatar_dir" ]; then
            sudo mkdir -p "$avatar_dir"
            sudo chmod 755 "$avatar_dir"
        fi
        
        if sudo cp "$avatar_path" "$avatar_dest"; then
            sudo chmod 644 "$avatar_dest"
            log_success "Avatar set successfully"
        else
            log_error "Failed to set avatar"
        fi
    else
        log_warning "Avatar not found at $avatar_path"
    fi
}

# 1. Theme Settings
log_info "Applying theme settings..."
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark'
log_success "Dark theme applied"

# Set wallpaper and avatar before other customizations
set_wallpaper_avatar

# 2. Keyboard Shortcuts
log_info "Configuring keyboard shortcuts..."

# Close window shortcut
gsettings set org.gnome.desktop.wm.keybindings close "['<Super>c']"

# File Manager shortcut (Windows+E)
CUSTOM_PATH1="org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
CUSTOM_PATH2="org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/"

# Get current keybindings and update the array
CURRENT_KEYS=$(gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings)

# Initialize with both custom keybindings
if [[ "$CURRENT_KEYS" == "@as []" ]]; then
    NEW_KEYS="['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/', '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/']"
else
    NEW_KEYS=$(echo "$CURRENT_KEYS" | sed "s|]|, '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/', '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/']|")
fi

gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "$NEW_KEYS"

# Terminal shortcut setup
TERMINAL_CMD=""
for term in ptyxis gnome-terminal kgx tilix xterm; do
    if command -v $term &>/dev/null; then
        TERMINAL_CMD=$term
        break
    fi
done

if [ -z "$TERMINAL_CMD" ]; then
    log_error "No terminal emulator found"
else
    log_info "Using $TERMINAL_CMD as default terminal"
    
    # Configure terminal shortcut (custom0)
    gsettings set "$CUSTOM_PATH1" name 'Terminal'
    gsettings set "$CUSTOM_PATH1" command "$TERMINAL_CMD --new-window"
    gsettings set "$CUSTOM_PATH1" binding '<Super>q'
    log_success "Terminal shortcut configured"
fi

# Configure file manager shortcut (custom1)
gsettings set "$CUSTOM_PATH2" name 'File Manager'
gsettings set "$CUSTOM_PATH2" command 'nautilus --new-window'
gsettings set "$CUSTOM_PATH2" binding '<Super>e'
log_success "File manager shortcut configured"

# 3. Workspace Settings
log_info "Configuring workspaces..."
gsettings set org.gnome.mutter dynamic-workspaces false
gsettings set org.gnome.desktop.wm.preferences num-workspaces 5
log_success "5 static workspaces configured"

# 4. UI Preferences
log_info "Applying UI preferences..."
gsettings set org.gnome.desktop.interface enable-hot-corners false
gsettings set org.gnome.desktop.wm.preferences button-layout 'appmenu:minimize,maximize,close'
# Show hidden files in file chooser
gsettings set org.gtk.Settings.FileChooser show-hidden true
log_success "UI preferences applied"

# 5. Favorite Apps
log_info "Setting favorite apps..."
FAVORITES="['org.gnome.Terminal.desktop'"

# Check for Ptyxis
if [ -f "/usr/share/applications/org.gnome.Ptyxis.desktop" ] || 
   [ -f "/usr/local/share/applications/org.gnome.Ptyxis.desktop" ] ||
   [ -f "/var/lib/flatpak/exports/share/applications/org.gnome.Ptyxis.desktop" ]; then
    FAVORITES+=", 'org.gnome.Ptyxis.desktop'"
    log_info "Added Ptyxis to favorites"
fi

# Check for Firefox
if [ -f "/usr/share/applications/org.mozilla.firefox.desktop" ] || 
   [ -f "/var/lib/flatpak/exports/share/applications/org.mozilla.firefox.desktop" ]; then
    FAVORITES+=", 'org.mozilla.firefox.desktop'"
fi

FAVORITES+="]"
gsettings set org.gnome.shell favorite-apps "$FAVORITES"
log_success "Favorite apps configured"

log_success "GNOME customization complete! Some changes may require logout to take effect."