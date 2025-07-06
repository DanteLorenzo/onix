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
DEFAULT_UUID=$(dconf read /org/gnome/Ptyxis/default-profile-uuid 2>/dev/null | tr -d "'")

if [[ -z "$DEFAULT_UUID" ]]; then
    log_error "Failed to retrieve default profile UUID. Make sure Ptyxis is configured."
    exit 1
fi

log_info "Default Ptyxis profile UUID: $DEFAULT_UUID"

# Set opacity (0.0 = fully transparent, 1.0 = fully opaque)
OPACITY_VALUE=0.85
PROFILE_PATH="/org/gnome/Ptyxis/Profiles/$DEFAULT_UUID"

if dconf write "$PROFILE_PATH/opacity" "$OPACITY_VALUE" 2>/dev/null; then
    log_success "Terminal opacity successfully set to $OPACITY_VALUE"
else
    log_error "Failed to set terminal opacity"
    # Не выходим, так как это не критическая ошибка
fi

# Install zsh if not installed
if ! command -v zsh &>/dev/null; then
    log_info "Installing zsh..."
    if sudo dnf install -y zsh 2>/dev/null; then
        log_success "zsh installed successfully"
    else
        log_error "Failed to install zsh"
        exit 1
    fi
else
    log_info "zsh is already installed"
fi

# Install Oh My Zsh with auto-update disabled
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    log_info "Installing Oh My Zsh..."
    # Отключаем автоматическое обновление при установке
    export DISABLE_AUTO_UPDATE="true"
    if sh -c "$(wget -qO- https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended; then
        log_success "Oh My Zsh installed successfully with auto-update disabled"
    else
        log_error "Failed to install Oh My Zsh"
        exit 1
    fi
else
    log_info "Oh My Zsh is already installed"
    # Добавляем настройку отключения обновлений в существующий конфиг
    if ! grep -q "DISABLE_AUTO_UPDATE" ~/.zshrc; then
        echo -e "\n# Disable Oh My Zsh auto-update\nexport DISABLE_AUTO_UPDATE=\"true\"" >> ~/.zshrc
        log_success "Added DISABLE_AUTO_UPDATE to existing .zshrc"
    fi
fi

# Copy custom .zshrc file
log_info "Copying custom .zshrc file..."
if [[ -f "./configs/zsh/.zshrc" ]]; then
    # Убедимся, что в кастомном .zshrc есть отключение автообновления
    if ! grep -q "DISABLE_AUTO_UPDATE" ./configs/zsh/.zshrc; then
        echo -e "\n# Disable Oh My Zsh auto-update\nexport DISABLE_AUTO_UPDATE=\"true\"" >> ./configs/zsh/.zshrc
    fi
    
    if cp -f ./configs/zsh/.zshrc ~/; then
        log_success "Custom .zshrc copied"
    else
        log_error "Failed to copy .zshrc"
    fi
else
    log_warning "Custom .zshrc not found at ./configs/zsh/.zshrc"
    # Добавим настройку в текущий .zshrc, если кастомный не найден
    if ! grep -q "DISABLE_AUTO_UPDATE" ~/.zshrc; then
        echo -e "\n# Disable Oh My Zsh auto-update\nexport DISABLE_AUTO_UPDATE=\"true\"" >> ~/.zshrc
        log_success "Added DISABLE_AUTO_UPDATE to ~/.zshrc"
    fi
fi

# Install zsh plugins
log_info "Installing zsh plugins..."
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

# Install zsh-autosuggestions
if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]]; then
    if git clone -q https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions" 2>/dev/null; then
        log_success "zsh-autosuggestions installed"
    else
        log_error "Failed to install zsh-autosuggestions"
    fi
else
    log_info "zsh-autosuggestions already installed"
    # Обновляем плагин, если он уже установлен
    cd "$ZSH_CUSTOM/plugins/zsh-autosuggestions" && git pull -q && cd - >/dev/null
fi

# Install zsh-syntax-highlighting
if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]]; then
    if git clone -q https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" 2>/dev/null; then
        log_success "zsh-syntax-highlighting installed"
    else
        log_error "Failed to install zsh-syntax-highlighting"
    fi
else
    log_info "zsh-syntax-highlighting already installed"
    # Обновляем плагин, если он уже установлен
    cd "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" && git pull -q && cd - >/dev/null
fi

# Change default shell to zsh
log_info "Changing default shell to zsh..."
current_shell=$(getent passwd $(whoami) | cut -d: -f7)
if [[ "$current_shell" != "$(which zsh)" ]]; then
    if sudo chsh -s "$(which zsh)" "$(whoami)" 2>/dev/null; then
        log_success "Default shell changed to zsh"
    else
        log_error "Failed to change default shell"
    fi
else
    log_info "Default shell is already zsh"
fi

log_success "Setup completed successfully"
exit 0