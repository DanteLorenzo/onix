#!/bin/bash

# Include logging functions
source "$(dirname "$0")/../utils/logging.sh"

log_info "Detecting system type..."

if [ -f /etc/fedora-release ]; then
    log_success "Fedora system detected"
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