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
    
    # Add custom keybinding with proper path escaping
    CUSTOM_PATH="org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
    
    # Get current keybindings and update the array
    CURRENT_KEYS=$(gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings)
    
    # Use alternative sed delimiter (|) to avoid slash conflicts
    if [[ "$CURRENT_KEYS" == "@as []" ]]; then
        NEW_KEYS="['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/']"
    else
        NEW_KEYS=$(echo "$CURRENT_KEYS" | sed "s|]|, '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/']|")
    fi
    
    gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "$NEW_KEYS"
    gsettings set "$CUSTOM_PATH" name 'Terminal'
    gsettings set "$CUSTOM_PATH" command "$TERMINAL_CMD"
    gsettings set "$CUSTOM_PATH" binding '<Super>q'
    log_success "Terminal shortcut configured"
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

log_success "GNOME customization complete!"