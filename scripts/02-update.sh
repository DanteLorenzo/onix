#!/bin/bash

# Include logging functions
source "$(dirname "$0")/../utils/logging.sh"

log_info "Detecting system type..."

if [ -f /etc/fedora-release ]; then
    log_success "Fedora system detected"
    
    # Configure DNF for faster downloads
    log_info "Configuring DNF for parallel downloads..."
    if ! grep -q '^max_parallel_downloads=' /etc/dnf/dnf.conf; then
        echo 'max_parallel_downloads=20' | sudo tee -a /etc/dnf/dnf.conf >/dev/null
        log_success "Set max_parallel_downloads=20 in DNF config"
    else
        sudo sed -i 's/^max_parallel_downloads=.*/max_parallel_downloads=20/' /etc/dnf/dnf.conf
        log_success "Updated max_parallel_downloads to 20 in DNF config"
    fi

    log_info "Updating package lists..."
    sudo dnf check-update -y
    
    log_info "Upgrading installed packages..."
    sudo dnf upgrade -y
    
    log_info "Cleaning up package cache..."
    sudo dnf clean all
    
    log_info "Removing unused dependencies..."
    sudo dnf autoremove -y

elif [ -f /etc/redhat-release ] && grep -q "CentOS" /etc/redhat-release; then
    log_success "CentOS system detected"
    log_info "Updating package lists..."
    sudo yum check-update -y
    
    log_info "Upgrading installed packages..."
    sudo yum update -y
    
    log_info "Cleaning up package cache..."
    sudo yum clean all
else
    log_error "Could not detect system type. This script supports only Fedora and CentOS!"
    exit 1
fi

log_success "System update complete!"
exit 0