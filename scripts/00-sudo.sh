#!/bin/bash

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Include logging functions
if [ -f "$SCRIPT_DIR/../utils/logging.sh" ]; then
    source "$SCRIPT_DIR/../utils/logging.sh"
else
    echo "ERROR: Could not find logging.sh"
    exit 1
fi

# --- Function to add user to sudo ---
add_user_to_sudo() {
    local username="$1"
    
    log_info "Checking if user '$username' is already in sudo group..."
    if groups "$username" | grep -q '\bsudo\b'; then
        log_info "User '$username' is already in the sudo group."
        return 0
    fi

    log_info "Adding user '$username' to sudo group..."
    if usermod -aG sudo "$username"; then
        log_success "Successfully added '$username' to sudo group."
        log_info "Note: User may need to log out and back in for changes to take effect."
        return 0
    else
        log_error "Failed to add '$username' to sudo group."
        return 1
    fi
}

# --- Main Script ---
log_info "Starting sudo configuration..."

# Get the current user (even if script is run with sudo)
CURRENT_USER=${SUDO_USER:-$(logname 2>/dev/null || whoami)}

# Check if script is run as root (if yes, skip sudo prompt)
if [[ $EUID -ne 0 ]]; then
    log_info "Requesting root privileges to modify sudo group..."
    if sudo true; then
        log_success "Root access granted."
    else
        log_error "Root access denied. Aborting."
        exit 1
    fi
fi

# Add user to sudo group (now running as root)
add_user_to_sudo "$CURRENT_USER"

# Exit root mode (if script was elevated)
if [[ $EUID -eq 0 ]] && [[ -n "$SUDO_USER" ]]; then
    log_info "Exiting root mode. Subsequent commands will run under sudo."
    exit 0
fi

log_info "You can now run commands with sudo."