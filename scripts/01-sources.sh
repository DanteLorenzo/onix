#!/bin/bash

# Include logging functions
source "$(dirname "$0")/../utils/logging.sh"

# Target file path
TARGET_FILE="/etc/apt/sources.list.d/debian.sources"

# Content to be written
CONTENT='Types: deb deb-src
URIs: https://deb.debian.org/debian
Suites: bookworm bookworm-updates
Components: main non-free-firmware
Enabled: yes
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg

Types: deb deb-src
URIs: https://security.debian.org/debian-security
Suites: bookworm-security
Components: main non-free-firmware
Enabled: yes
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg'

log_info "Starting Debian sources configuration..."

# Check if file already exists
if [ -f "$TARGET_FILE" ]; then
    log_warning "File $TARGET_FILE already exists."
    read -p "Do you want to overwrite it? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Operation cancelled."
        exit 0
    fi
fi

# Create backup if file exists
if [ -f "$TARGET_FILE" ]; then
    BACKUP_FILE="${TARGET_FILE}.bak-$(date +%Y%m%d%H%M%S)"
    log_info "Creating backup: $BACKUP_FILE"
    sudo cp "$TARGET_FILE" "$BACKUP_FILE" || {
        log_error "Failed to create backup"
        exit 1
    }
fi

# Write new content
log_info "Creating/updating $TARGET_FILE"
echo "$CONTENT" | sudo tee "$TARGET_FILE" > /dev/null || {
    log_error "Failed to write to $TARGET_FILE"
    exit 1
}

# Verify file was created
if [ -f "$TARGET_FILE" ]; then
    log_success "File successfully created/updated: $TARGET_FILE"
    log_info "You may want to run: sudo apt update"
else
    log_error "Failed to verify file creation"
    exit 1
fi