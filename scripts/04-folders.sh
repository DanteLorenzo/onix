#!/bin/bash

# Include logging functions
source "$(dirname "$0")/../utils/logging.sh"

# Base
log_info "Installing base packages with pacman..."


# List of folders to create
folders=("Downloads" "Music" "Pictures" "Movies" "Projects")

for folder in "${folders[@]}"; do
    if [ ! -d ~/$folder ]; then
        mkdir ~/$folder
        log_success "Created folder: $folder"
    else
        log_warning "Folder already exists: $folder"
    fi
done

# Copy all files from ./pic to ~/Pictures
if [ -d ./pic ]; then
    cp -r ./pic/* ~/Pictures/
    log_success "Copied all files from ./pic to ~/Pictures"
else
    log_error "Source folder ./pic does not exist"
fi

# Copy all cursor themes to /usr/share/icons/ under sudo
sudo cp -r ./cursors/* /usr/share/icons/

