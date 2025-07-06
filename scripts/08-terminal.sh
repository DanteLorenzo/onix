#!/bin/bash

# Include logging functions
source "$(dirname "$0")/../utils/logging.sh"

log_info "Starting Ptyxis blur support diagnostics..."

# 1. Session type check
SESSION_TYPE="${XDG_SESSION_TYPE:-unknown}"
log_info "Session Type: $SESSION_TYPE"

if [[ "$SESSION_TYPE" != "wayland" ]]; then
    log_error "Wayland is not active. Blur only works on Wayland."
else
    log_success "Wayland session detected."
fi

# 2. GNOME version check
GNOME_VERSION=$(gnome-shell --version 2>/dev/null)
if [[ -z "$GNOME_VERSION" ]]; then
    log_error "Unable to determine GNOME version. gnome-shell not found."
else
    log_info "GNOME Version: $GNOME_VERSION"
fi

# 3. Mutter package check
if command -v rpm &>/dev/null; then
    MUTTER_VERSION=$(rpm -q mutter)
elif command -v pacman &>/dev/null; then
    MUTTER_VERSION=$(pacman -Q mutter 2>/dev/null)
else
    MUTTER_VERSION="Package manager not supported"
fi

log_info "Mutter version: $MUTTER_VERSION"

# 4. Check if blur-background is set in current Ptyxis profile
UUID=$(dconf read /org/gnome/Ptyxis/default-profile-uuid | tr -d "'")

if [[ -z "$UUID" ]]; then
    log_error "Could not find Ptyxis default profile UUID."
    exit 1
fi

PROFILE_PATH="/org/gnome/Ptyxis/Profiles/$UUID"
OPACITY=$(dconf read "$PROFILE_PATH/opacity" 2>/dev/null)
BLUR_ENABLED=$(dconf read "$PROFILE_PATH/blur-background" 2>/dev/null)

log_info "Ptyxis profile UUID: $UUID"
log_info "Opacity: ${OPACITY:-not set}"
log_info "Blur enabled: ${BLUR_ENABLED:-not set}"

# Final check
if [[ "$SESSION_TYPE" == "wayland" && "$BLUR_ENABLED" == "true" ]]; then
    log_success "Configuration seems correct. If blur still doesn't work, it's likely a Mutter or Ptyxis bug."
else
    log_error "Blur might not be applied correctly. Check the configuration above."
fi
