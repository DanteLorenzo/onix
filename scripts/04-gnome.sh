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

# 1. Theme Settings
log_info "Applying theme settings..."
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark'
log_success "Dark theme applied"

# 2. Keyboard Shortcuts
log_info "Configuring keyboard shortcuts..."

# Close window shortcut
gsettings set org.gnome.desktop.wm.keybindings close "['<Super>c']"

# Alacritty terminal shortcut setup
TERMINAL_CMD="alacritty"
if ! command -v $TERMINAL_CMD &>/dev/null; then
    log_error "Alacritty not found! Please install it first."
    log_info "You can install Alacritty with:"
    log_info "  Fedora: sudo dnf install alacritty"
    log_info "  Ubuntu/Debian: sudo apt install alacritty"
    log_info "  Arch: sudo pacman -S alacritty"
    exit 1
else
    log_info "Using Alacritty as default terminal"
    
    # Add custom keybinding
    CUSTOM_PATH="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
    CURRENT_KEYS=$(gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings)
    
    # Use alternative sed delimiter (|) to avoid slash conflicts
    if [[ "$CURRENT_KEYS" == "@as []" ]]; then
        NEW_KEYS="['$CUSTOM_PATH']"
    else
        NEW_KEYS=$(echo "$CURRENT_KEYS" | sed "s|]|, '$CUSTOM_PATH']|")
    fi
    
    gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "$NEW_KEYS"
    gsettings set "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$CUSTOM_PATH" name 'Terminal'
    gsettings set "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$CUSTOM_PATH" command "$TERMINAL_CMD"
    gsettings set "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$CUSTOM_PATH" binding '<Super>Return'
    log_success "Terminal shortcut configured (Super+Return)"
fi

# 3. Workspace Settings
log_info "Configuring workspaces..."
gsettings set org.gnome.mutter dynamic-workspaces false
gsettings set org.gnome.desktop.wm.preferences num-workspaces 5
log_success "5 static workspaces configured"

# 4. UI Preferences
log_info "Applying UI preferences..."
gsettings set org.gnome.desktop.interface enable-hot-corners false
gsettings set org.gnome.desktop.wm.preferences button-layout 'appmenu:minimize,maximize,close'
log_success "UI preferences applied"

# 5. Favorite Apps
log_info "Setting favorite apps..."
FAVORITES="['org.gnome.Terminal.desktop'"  # Fallback entry

# Check for Alacritty desktop file
if [ -f "/usr/share/applications/Alacritty.desktop" ]; then
    FAVORITES="['Alacritty.desktop'"
elif [ -f "/usr/share/applications/org.alacritty.Alacritty.desktop" ]; then
    FAVORITES="['org.alacritty.Alacritty.desktop'"
fi

# Check for Firefox
if [ -f "/usr/share/applications/org.mozilla.firefox.desktop" ]; then
    FAVORITES+=", 'org.mozilla.firefox.desktop'"
elif [ -f "/usr/share/applications/firefox.desktop" ]; then
    FAVORITES+=", 'firefox.desktop'"
fi

FAVORITES+="]"
gsettings set org.gnome.shell favorite-apps "$FAVORITES"
log_success "Favorite apps configured"

# 6. Optional: Configure Alacritty as default terminal
if command -v update-alternatives &>/dev/null; then
    log_info "Setting Alacritty as default terminal..."
    sudo update-alternatives --set x-terminal-emulator $(which alacritty)
fi

log_success "GNOME customization complete!"