#!/bin/bash

# Include logging functions
source "$(dirname "$0")/../utils/logging.sh"

# Base packages installation
log_info "Installing main packages with dnf..."

# Install main packages
sudo dnf install -y \
  tmux \



if [ $? -eq 0 ]; then
  log_success "Main packages installation complete."
else
  log_error "Main packages installation failed."
fi
