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

# --- Function to add user to sudoers ---
add_user_to_sudoers() {
    local username="$1"
    
    log_info "Checking if user '$username' already has sudo privileges..."
    
    # Check if user is already in sudoers
    if sudo grep -q "^$username" /etc/sudoers || sudo grep -q "^$username" /etc/sudoers.d/* 2>/dev/null; then
        log_info "User '$username' already has sudo privileges."
        return 0
    fi

    log_info "Adding user '$username' to sudoers..."
    
    # Create a temporary sudoers entry
    SUDO_ENTRY="$username ALL=(ALL:ALL) ALL"
    
    # Add to sudoers file (using visudo for safety)
    if echo "$SUDO_ENTRY" | sudo EDITOR='tee -a' visudo >/dev/null; then
        log_success "Successfully added '$username' to sudoers."
        return 0
    else
        # Fallback to adding to sudoers.d directory
        log_info "Trying alternative method via /etc/sudoers.d/"
        SUDOERS_FILE="/etc/sudoers.d/$username"
        if echo "$SUDO_ENTRY" | sudo tee "$SUDOERS_FILE" >/dev/null && \
           sudo chmod 0440 "$SUDOERS_FILE"; then
            log_success "Successfully added '$username' to sudoers via $SUDOERS_FILE"
            return 0
        else
            log_error "Failed to add '$username' to sudoers."
            return 1
        fi
    fi
}

# --- Main Script ---
log_info "Starting sudo configuration..."

# Get the current user (even if script is run with sudo)
CURRENT_USER=${SUDO_USER:-$(logname 2>/dev/null || whoami)}

# Check if script is run as root (if yes, skip sudo prompt)
if [[ $EUID -ne 0 ]]; then
    log_info "Requesting root privileges to modify sudo configuration..."
    if sudo true; then
        log_success "Root access granted."
    else
        log_error "Root access denied. Aborting."
        exit 1
    fi
fi

# First try adding to sudoers directly
if ! add_user_to_sudoers "$CURRENT_USER"; then
    # Fallback to adding to sudo group if direct method fails
    log_info "Falling back to adding user to sudo group..."
    
    if ! command -v usermod >/dev/null; then
        log_error "usermod command not found. Cannot add to sudo group."
        exit 1
    fi
    
    log_info "Adding user '$CURRENT_USER' to sudo group..."
    if sudo usermod -aG sudo "$CURRENT_USER"; then
        log_success "Successfully added '$CURRENT_USER' to sudo group."
        log_info "Note: User may need to log out and back in for changes to take effect."
    else
        log_error "Failed to add '$CURRENT_USER' to sudo group."
        exit 1
    fi
fi

log_success "Sudo configuration completed successfully."
log_info "You can now run commands with sudo."