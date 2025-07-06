#!/bin/bash

# Include logging functions
source "$(dirname "$0")/../utils/logging.sh"

log_info "Configuring GNOME terminal opacity and blur for Ptyxis..."

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

# Set variables
OPACITY_VALUE=0.85
PROFILE_PATH="/org/gnome/Ptyxis/Profiles/$DEFAULT_UUID"

# Set opacity
log_info "Setting opacity to $OPACITY_VALUE..."
dconf write "$PROFILE_PATH/opacity" "$OPACITY_VALUE"

# Enable blur
log_info "Enabling background blur..."
dconf write "$PROFILE_PATH/blur-background" true

# Final result
if [[ $? -eq 0 ]]; then
    log_success "Ptyxis opacity and blur configured successfully."
else
    log_error "Failed to configure opacity or blur."
fi
