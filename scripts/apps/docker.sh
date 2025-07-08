#!/bin/bash

source "$(dirname "$0")/../utils/logging.sh"

# Docker Installation
# ==================
log_info "Installing Docker..."
if curl -sSL https://get.docker.com/ | bash; then
    log_success "Docker installation completed successfully."

    # Add user to docker group
    log_info "Adding user to the docker group..."
    if sudo usermod -aG docker $USER; then
        log_success "User added to docker group. Please restart your session or run 'newgrp docker' to apply changes."
        echo "Note: You may need to log out and back in for changes to take effect."
    else
        log_error "Failed to add user to docker group."
    fi
else
    log_error "Docker installation failed. Please check the installation process."
    exit 1
fi