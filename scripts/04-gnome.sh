#!/bin/bash

# Include logging functions
source "$(dirname "$0")/../utils/logging.sh"

# Display an informational message about the start of the setup
log_info "Starting GNOME customization..."

# Check if GNOME is installed
if ! command -v gsettings &> /dev/null; then
    log_error "GNOME is not installed. This script only works with GNOME desktop."
    exit 1
fi

# 1. Enable Dark Mode
log_info "Enabling dark mode..."
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark'
log_success "Dark mode enabled successfully"

# 2. Set keyboard shortcuts
log_info "Configuring keyboard shortcuts..."

# Initialize custom keybindings array
gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "[]"

# Windows + C to close window
gsettings set org.gnome.desktop.wm.keybindings close "['<Super>c']"

# Windows + Q to open terminal (custom keybinding)
TERMINAL_KEYBINDING_PATH="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['$TERMINAL_KEYBINDING_PATH']"
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding "$TERMINAL_KEYBINDING_PATH" name 'Terminal'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding "$TERMINAL_KEYBINDING_PATH" command 'gnome-terminal'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding "$TERMINAL_KEYBINDING_PATH" binding '<Super>q'

log_success "Keyboard shortcuts configured:"
log_success "  - Super+C: Close window"
log_success "  - Super+Q: Open terminal"

# 3. Set up 5 workspaces (without names)
log_info "Configuring 5 workspaces..."
gsettings set org.gnome.mutter dynamic-workspaces false
gsettings set org.gnome.desktop.wm.preferences num-workspaces 5
log_success "5 workspaces configured"

# 4. Disable hot corner
log_info "Disabling hot corner..."
gsettings set org.gnome.desktop.interface enable-hot-corners false
log_success "Hot corner disabled"

# Additional useful GNOME tweaks
log_info "Applying additional GNOME tweaks..."

# Enable minimize on click
gsettings set org.gnome.desktop.wm.preferences button-layout 'appmenu:minimize,maximize,close'

log_success "Additional GNOME tweaks applied"

log_success "GNOME customization completed successfully!"