#!/bin/bash

# Configuration Files Deployment Script
# Copies specified folders from configs directory to ~/.config

# Include logging functions
source "$(dirname "$0")/../utils/logging.sh"

# Array of folders to copy to ~/.config
CONFIG_FOLDERS=(
    "tmux"
)

log_section "Starting configuration deployment"

# Verify source configs directory exists
CONFIGS_ROOT="$(dirname "$0")/../configs"
if [[ ! -d "$CONFIGS_ROOT" ]]; then
    log_error "Configs directory not found: $CONFIGS_ROOT"
    exit 1
fi

log_info "Source configs directory: $CONFIGS_ROOT"

# Ensure .config directory exists
mkdir -p "$HOME/.config"

# Process each folder in the array
for folder in "${CONFIG_FOLDERS[@]}"; do
    src_dir="$CONFIGS_ROOT/$folder"
    dest_dir="$HOME/.config/$folder"
    
    log_info "Processing folder: $folder"
    
    # Verify source folder exists
    if [[ ! -d "$src_dir" ]]; then
        log_warning "Source folder not found - skipping: $src_dir"
        continue
    fi
    
    # Remove existing destination if present
    if [[ -d "$dest_dir" || -f "$dest_dir" ]]; then
        log_info "Removing existing: $dest_dir"
        if ! rm -rf "$dest_dir"; then
            log_error "Failed to remove - skipping: $dest_dir"
            continue
        fi
    fi
    
    # Copy new configuration
    log_info "Copying: $src_dir -> $dest_dir"
    if cp -r "$src_dir" "$dest_dir"; then
        log_success "Successfully deployed: $folder"
    else
        log_error "Failed to copy: $folder"
    fi
done

log_success "Configuration deployment complete"
exit 0