#!/bin/bash

# Include logging functions
source "$(dirname "$0")/../utils/logging.sh"

# Get absolute path to user's home directory
USER_HOME=$(getent passwd "$(whoami)" | cut -d: -f6)
log_info "User home directory: $USER_HOME"

# Create default directories in user's HOME
log_info "Creating default user directories..."
folders=("Downloads" "Music" "Pictures" "Movies" "Projects")

for folder in "${folders[@]}"; do
    target_dir="${USER_HOME}/${folder}"
    if [ ! -d "${target_dir}" ]; then
        if mkdir -p "${target_dir}"; then
            log_success "Created directory: ${target_dir}"
        else
            log_error "Failed to create directory: ${target_dir}"
            exit 1
        fi
    else
        log_info "Directory already exists: ${target_dir}"
    fi
done

# Copy pictures from ~/onix/pic to ~/Pictures
log_info "Copying picture files..."
ONIX_DIR=$(dirname "$(realpath "$0")")  # Absolute path to onix directory
SOURCE_PIC_DIR="${ONIX_DIR}/pic"
TARGET_PIC_DIR="${USER_HOME}/Pictures"

log_info "Source pictures directory: $SOURCE_PIC_DIR"
log_info "Target pictures directory: $TARGET_PIC_DIR"

if [ -d "${SOURCE_PIC_DIR}" ]; then
    # Ensure target directory exists
    mkdir -p "${TARGET_PIC_DIR}" || {
        log_error "Failed to create target directory ${TARGET_PIC_DIR}"
        exit 1
    }

    # Count files before copying
    file_count=$(find "${SOURCE_PIC_DIR}" -type f | wc -l)
    [ "$file_count" -eq 0 ] && {
        log_warning "No files found in ${SOURCE_PIC_DIR}"
        exit 0
    }

    log_info "Found $file_count files to copy"

    # Copy with progress reporting
    if cp -vr "${SOURCE_PIC_DIR}"/* "${TARGET_PIC_DIR}"/ | while read -r line; do
        log_info "$line"
    done; then
        copied_count=$(find "${TARGET_PIC_DIR}" -maxdepth 1 -type f | wc -l)
        log_success "Successfully copied $copied_count files to user's Pictures directory"
    else
        log_error "Failed to copy files"
        exit 1
    fi
else
    log_warning "Source directory ${SOURCE_PIC_DIR} not found - skipping picture copy"
fi

log_success "All operations completed in user space"