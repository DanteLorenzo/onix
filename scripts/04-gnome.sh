#!/bin/bash

# Include logging functions
source "$(dirname "$0")/../utils/logging.sh"

# Display an informational message about the start of the setup
log_info "Starting GNOME customization..."

# Function to check if GNOME is running under Wayland or X11
check_gnome_session() {
    local session_type
    session_type=$(loginctl show-session $(loginctl | grep $(whoami) | awk '{print $1}') -p Type | cut -d= -f2)
    
    if [ "$session_type" != "wayland" ] && [ "$session_type" != "x11" ]; then
        log_error "Could not determine session type. Some GNOME settings might not apply."
        return 1
    fi
    log_info "Detected GNOME running on $session_type"
}

# Check if GNOME is installed and running
if ! command -v gsettings &> /dev/null; then
    log_error "GNOME is not installed. This script only works with GNOME desktop."
    exit 1
fi

# Verify we're in a GNOME session
if [ "$XDG_CURRENT_DESKTOP" != "GNOME" ]; then
    log_warning "Not running in GNOME session (XDG_CURRENT_DESKTOP=$XDG_CURRENT_DESKTOP). Some settings might not apply."
fi

check_gnome_session

# 1. Enable Dark Mode
log_info "Enabling dark mode..."
if gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' && \
   gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark'; then
    log_success "Dark mode enabled successfully"
else
    log_error "Failed to enable dark mode"
fi

# 2. Set keyboard shortcuts
log_info "Configuring keyboard shortcuts..."

# Windows + C to close window
if gsettings set org.gnome.desktop.wm.keybindings close "['<Super>c']"; then
    log_success "Configured Super+C to close window"
else
    log_error "Failed to set window close shortcut"
fi

# Windows + Q to open terminal (custom keybinding)
log_info "Adding custom shortcut for terminal..."

CUSTOM_KEYBINDINGS_PATH="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings"
CUSTOM0="${CUSTOM_KEYBINDINGS_PATH}/custom0/"

# Check if terminal is available
if ! command -v gnome-terminal &> /dev/null; then
    log_warning "gnome-terminal not found, using fallback terminal"
    TERMINAL_CMD="xterm"
else
    TERMINAL_CMD="gnome-terminal"
fi

# Add custom0 to the list of keybindings
CURRENT=$(gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings)
if [[ "$CURRENT" != *"$CUSTOM0"* ]]; then
    if [[ "$CURRENT" == "@as []" ]]; then
        if ! gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['$CUSTOM0']"; then
            log_error "Failed to initialize custom keybindings array"
        fi
    else
        MODIFIED=$(echo "$CURRENT" | sed "s/]$/, '$CUSTOM0']/")
        if ! gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "$MODIFIED"; then
            log_error "Failed to update custom keybindings array"
        fi
    fi
fi

# Set the custom0 keybinding
if gsettings set "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$CUSTOM0" name 'Terminal' && \
   gsettings set "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$CUSTOM0" command "$TERMINAL_CMD" && \
   gsettings set "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$CUSTOM0" binding '<Super>q'; then
    log_success "Configured Super+Q to open terminal"
else
    log_error "Failed to set terminal shortcut"
fi

# 3. Set up 5 workspaces (without names)
log_info "Configuring 5 workspaces..."
if gsettings set org.gnome.mutter dynamic-workspaces false && \
   gsettings set org.gnome.desktop.wm.preferences num-workspaces 5; then
    log_success "5 workspaces configured"
else
    log_error "Failed to configure workspaces"
fi

# 4. Disable hot corner
log_info "Disabling hot corner..."
if gsettings set org.gnome.desktop.interface enable-hot-corners false; then
    log_success "Hot corner disabled"
else
    log_error "Failed to disable hot corner"
fi

# Additional useful GNOME tweaks
log_info "Applying additional GNOME tweaks..."

# Set favorite apps (check if applications exist first)
FAVORITE_APPS="['org.gnome.Terminal.desktop'"
if [ -f /usr/share/applications/firefox.desktop ] || [ -f /usr/share/applications/firefox-esr.desktop ]; then
    FAVORITE_APPS+=", 'firefox.desktop'"
fi
FAVORITE_APPS+="]"

if gsettings set org.gnome.shell favorite-apps "$FAVORITE_APPS"; then
    log_success "Favorite apps configured"
else
    log_error "Failed to set favorite apps"
fi

# Enable minimize on click
if gsettings set org.gnome.desktop.wm.preferences button-layout 'appmenu:minimize,maximize,close'; then
    log_success "Window button layout configured"
else
    log_error "Failed to configure window buttons"
fi

# Refresh GNOME Shell (might require restart in some cases)
if command -v gnome-shell &> /dev/null; then
    log_info "Refreshing GNOME Shell..."
    gnome-shell --replace &>/dev/null & disown
fi

log_success "GNOME customization completed successfully!"