#!/bin/bash

# Include logging functions
source "$(dirname "$0")/../utils/logging.sh"

# Base packages installation
log_info "Installing base packages with dnf..."

# Install main packages
sudo dnf install -y \
  gcc \
  cmake \
  git \
  mesa-libGL \
  mesa-dri-drivers \
  nano \
  vim \
  vulkan \
  vulkan-tools \
  jq \
  curl


if [ $? -eq 0 ]; then
  log_success "Base packages installation complete."
else
  log_error "Base packages installation failed."
fi
