#!/bin/bash

# Include logging functions
source "$(dirname "$0")/../utils/logging.sh"

log_info "Configuring keyboard layout..."

# Verify GNOME environment
if ! command -v gsettings &>/dev/null; then
    log_error "gsettings not found. This script requires GNOME desktop."
    exit 1
fi

# Configure input sources (keyboard layouts only)
configure_keyboard_layouts() {
    log_info "Setting up English + Russian keyboard layouts..."
    
    # Current layouts
    CURRENT_LAYOUTS=$(gsettings get org.gnome.desktop.input-sources sources)
    
    # Check if Russian layout already exists
    if [[ $CURRENT_LAYOUTS == *"'ru'"* ]]; then
        log_success "Russian layout already configured"
        return 0
    fi
    
    # Add Russian layout while preserving existing ones
    if [[ $CURRENT_LAYOUTS == "@a []" ]]; then
        NEW_LAYOUTS="[('xkb', 'us'), ('xkb', 'ru')]"
    else
        NEW_LAYOUTS=$(echo "$CURRENT_LAYOUTS" | sed "s/]/, ('xkb', 'ru')]/")
    fi
    
    gsettings set org.gnome.desktop.input-sources sources "$NEW_LAYOUTS"
    log_success "Keyboard layouts configured: English + Russian"
}

# Set Alt+Shift switching
set_switch_shortcut() {
    log_info "Configuring Alt+Shift layout switching..."
    
    gsettings set org.gnome.desktop.wm.keybindings switch-input-source "['<Alt>Shift_L', '<Alt>Shift_R']"
    gsettings set org.gnome.desktop.wm.keybindings switch-input-source-backward "['<Shift>Alt_L', '<Shift>Alt_R']"
    
    log_success "Layout switch shortcut set to Alt+Shift"
}

set_regional_formats() {
    log_info "Setting regional formats..."

    gsettings set org.gnome.desktop.interface clock-format '24h'
    gsettings set org.gnome.desktop.interface clock-show-date true
    gsettings set org.gnome.desktop.interface clock-show-weekday true
    
    log_success "Regional formats set to Russian"
}

# Main execution
configure_keyboard_layouts
set_switch_shortcut
set_regional_formats

log_success "Keyboard configuration complete! System language remains unchanged."