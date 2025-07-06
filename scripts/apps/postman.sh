#!/bin/bash

# Postman Installer for Fedora
# Downloads and installs the latest version from official source

# Load logging functions
SCRIPT_DIR=$(dirname "$0")
LOGGING_SCRIPT="$SCRIPT_DIR/../utils/logging.sh"

if [[ -f "$LOGGING_SCRIPT" ]]; then
    source "$LOGGING_SCRIPT"
else
    echo "[ERROR] Required logging.sh not found. Place it in ../utils/" >&2
    exit 1
fi

# Check preconditions
check_environment() {
    if [[ $EUID -eq 0 ]]; then
        log_error "This script should not be run as root. Please run as a normal user."
        return 1
    fi

    if ! command -v dnf &> /dev/null; then
        log_error "DNF package manager not found. This script is for Fedora only."
        return 1
    fi

    return 0
}

# Main installation function
install_postman() {
    local tmp_dir=$(mktemp -d)
    cd "$tmp_dir" || {
        log_error "Failed to enter temporary directory $tmp_dir"
        return 1
    }

    log_info "Downloading Postman..."
    if ! wget -q --show-progress https://dl.pstmn.io/download/latest/linux_64 -O postman.rpm; then
        log_error "Download failed"
        return 1
    fi

    log_info "Installing Postman..."
    if ! sudo dnf install -y postman.rpm; then
        log_error "Installation failed"
        return 1
    fi

    log_info "Cleaning up..."
    rm -rf "$tmp_dir"
}

# Execution flow
log_info "Starting Postman installation"

if ! check_environment; then
    exit 1
fi

if install_postman; then
    if command -v postman &> /dev/null; then
        log_success "Postman installed successfully"
        log_info "Run with: postman"
    else
        log_error "Postman binary not found after installation"
        exit 1
    fi
else
    log_error "Postman installation failed"
    exit 1
fi

exit 0