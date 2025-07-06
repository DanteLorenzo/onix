#!/bin/bash

# Include logging functions
source "$(dirname "$0")/../utils/logging.sh"

# Create default directories
log_info "Creating default user directories..."
folders=("Downloads" "Music" "Pictures" "Movies" "Projects")

for folder in "${folders[@]}"; do
    target_dir="$HOME/$folder"
    if [ ! -d "$target_dir" ]; then
        if mkdir -p "$target_dir"; then
            log_success "Created directory: $target_dir"
        else
            log_error "Failed to create directory: $target_dir"
        fi
    else
        log_info "Directory already exists: $target_dir"
    fi
done

# Copy pictures
log_info "Copying picture files..."
source_pic_dir="./pic"
target_pic_dir="$HOME/Pictures"

if [ -d "$source_pic_dir" ]; then
    if [ ! -d "$target_pic_dir" ]; then
        log_warning "Target directory $target_pic_dir does not exist - creating it"
        mkdir -p "$target_pic_dir" || {
            log_error "Failed to create target directory $target_pic_dir"
            exit 1
        }
    fi

    if [ "$(ls -A "$source_pic_dir")" ]; then
        log_info "Found $(ls -1 "$source_pic_dir" | wc -l) files in $source_pic_dir"
        
        if cp -vr "$source_pic_dir"/* "$target_pic_dir"/; then
            copied_count=$(ls -1 "$target_pic_dir" | wc -l)
            log_success "Successfully copied $copied_count files to $target_pic_dir"
        else
            log_error "Failed to copy some files from $source_pic_dir to $target_pic_dir"
        fi
    else
        log_warning "Source directory $source_pic_dir is empty - nothing to copy"
    fi
else
    log_warning "Source directory $source_pic_dir not found - skipping picture copy"
fi