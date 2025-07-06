#!/bin/bash

# Include logging functions
source "$(dirname "$0")/../utils/logging.sh"

log_info "Configuring GNOME terminal opacity for Ptyxis..."

# Check if dconf is available
if ! command -v dconf &>/dev/null; then
    log_error "dconf not found. This script requires GNOME with dconf."
    exit 1
fi

# Try to get the default UUID for Ptyxis profile
DEFAULT_UUID=$(dconf read /org/gnome/Ptyxis/default-profile-uuid | tr -d "'")

if [[ -z "$DEFAULT_UUID" ]]; then
    log_error "Failed to retrieve default profile UUID. Make sure Ptyxis is configured."
    exit 1
fi

log_info "Default Ptyxis profile UUID: $DEFAULT_UUID"

# Set opacity (0.0 = fully transparent, 1.0 = fully opaque)
OPACITY_VALUE=0.85
PROFILE_PATH="/org/gnome/Ptyxis/Profiles/$DEFAULT_UUID"

dconf write "$PROFILE_PATH/opacity" "$OPACITY_VALUE"

if [[ $? -eq 0 ]]; then
    log_success "Terminal opacity successfully set to $OPACITY_VALUE"
else
    log_error "Failed to set terminal opacity"
fi

# Install zsh if not installed
if ! command -v zsh &>/dev/null; then
    log_info "Installing zsh..."
    sudo dnf install -y zsh
    if [ $? -ne 0 ]; then
        log_error "Failed to install zsh"
        exit 1
    fi
    log_success "zsh installed successfully"
else
    log_info "zsh is already installed"
fi

# Install Oh My Zsh
log_info "Installing Oh My Zsh..."
sh -c "$(wget -qO- https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# Check if installation was successful
if [ $? -eq 0 ]; then
  log_success "Oh My Zsh installed successfully."

  # Copy custom .zshrc file
  log_info "Copying custom .zshrc file..."
  if [[ -f "./configs/zsh/.zshrc" ]]; then
    cp ./configs/zsh/.zshrc ~/
    log_success "Custom .zshrc copied"
  else
    log_warning "Custom .zshrc not found at ./configs/zsh/.zshrc"
  fi

  # Install zsh plugins
  log_info "Installing zsh plugins..."
  ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
  
  # Install zsh-autosuggestions
  if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
    git clone -q https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions" && \
      log_success "zsh-autosuggestions installed" || \
      log_error "Failed to install zsh-autosuggestions"
  else
    log_info "zsh-autosuggestions already installed"
  fi
  
  # Install zsh-syntax-highlighting
  if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
    git clone -q https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" && \
      log_success "zsh-syntax-highlighting installed" || \
      log_error "Failed to install zsh-syntax-highlighting"
  else
    log_info "zsh-syntax-highlighting already installed"
  fi

  # Change default shell to zsh
  log_info "Changing default shell to zsh..."
  sudo chsh -s $(which zsh) $(whoami) && \
    log_success "Default shell changed to zsh" || \
    log_error "Failed to change default shell"

  log_success "Setup completed successfully."
else
  log_error "Failed to install Oh My Zsh. Check for errors above."
  exit 1
fi