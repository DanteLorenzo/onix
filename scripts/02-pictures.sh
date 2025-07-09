#!/bin/bash

# Include logging functions
source "$(dirname "$0")/../utils/logging.sh"

# Create default directories
log_info "Creating default user directories..."
folders=("Downloads" "Music" "Pictures" "Movies" "Projects")

for folder in "${folders[@]}"; do
    if [ ! -d ~/$folder ]; then
        mkdir ~/$folder
        log_success "Created directory: ~/$folder"
    else
        log_info "Directory already exists: ~/$folder"
    fi
done

# Copy pictures
log_info "Copying picture files..."
if [ -d ./pic ]; then
    if [ -d ~/Pictures ]; then
        cp -r ./pic/* ~/Pictures/
        log_success "Copied all files from ./pic to ~/Pictures"
    else
        log_error "Target directory ~/Pictures does not exist"
    fi
else
    log_warning "Source directory ./pic not found - skipping picture copy"
fi