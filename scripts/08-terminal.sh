#!/bin/bash

# Include logging functions
source "$(dirname "$0")/../utils/logging.sh"

log_info "Configuring GNOME terminal opacity for Ptyxis..."

# Check if dconf is available
if ! command -v dconf &>/dev/null; then
    log_error "dconf not found. This script requires GNOME with dconf."
    exit 1
fi

# Try to get the default UUID for Ptyxis profile
DEFAULT_UUID=$(dconf read /org/gnome/Ptyxis/default-profile-uuid | tr -d "'")

if [[ -z "$DEFAULT_UUID" ]]; then
    log_error "Failed to retrieve default profile UUID. Make sure Ptyxis is configured."
    exit 1
fi

log_info "Default Ptyxis profile UUID: $DEFAULT_UUID"

# Set opacity (0.0 = fully transparent, 1.0 = fully opaque)
OPACITY_VALUE=0.85
PROFILE_PATH="/org/gnome/Ptyxis/Profiles/$DEFAULT_UUID"

log_info "Setting opacity to $OPACITY_VALUE for profile $DEFAULT_UUID..."

dconf write "$PROFILE_PATH/opacity" "$OPACITY_VALUE"

if [[ $? -eq 0 ]]; then
    log_success "Terminal opacity successfully set to $OPACITY_VALUE"
else
    log_error "Failed to set terminal opacity"
fi
