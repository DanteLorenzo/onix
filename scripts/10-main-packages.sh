#!/bin/bash

# Base system configuration and package installation
source "$(dirname "$0")/../utils/logging.sh"

# ========================
# DNF Packages Installation
# ========================
log_info "Installing main packages with dnf..."
sudo dnf install -y \
    tmux \
    ollama \
    flatpak \
    steam \
    discord

if [ $? -eq 0 ]; then
    log_success "Main packages installation complete."
else
    log_error "Main packages installation failed."
    exit 1
fi

# =====================
# Docker Installation
# =====================
log_info "Installing Docker..."
sudo dnf install -y dnf-plugins-core
sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
sudo dnf install -y docker-ce docker-ce-cli containerd.io

if [ $? -eq 0 ]; then
    log_success "Docker installed successfully."
    sudo systemctl enable --now docker
    sudo usermod -aG docker $USER
    sg docker -c "echo 'Group changes applied temporarily'"
    log_info "Docker service enabled and current user added to docker group."
    log_info "You may need to log out and back in for group changes to take effect."
else
    log_error "Docker installation failed."
    exit 1
fi

# =====================
# Go Installation (latest version)
# =====================
log_info "Installing latest Go version..."

# Get the latest stable Go version
LATEST_GO_VERSION=$(curl -s https://go.dev/VERSION?m=text | head -1)
LATEST_GO_URL="https://go.dev/dl/${LATEST_GO_VERSION}.linux-amd64.tar.gz"

log_info "Downloading ${LATEST_GO_VERSION}..."
curl -OL $LATEST_GO_URL || {
    log_error "Failed to download Go"
    exit 1
}

sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf ${LATEST_GO_VERSION}.linux-amd64.tar.gz || {
    log_error "Failed to install Go"
    exit 1
}

rm ${LATEST_GO_VERSION}.linux-amd64.tar.gz

# Add to PATH in multiple places for reliability
GO_PATH_EXPORT='export PATH=$PATH:/usr/local/go/bin'

# For current session
export PATH=$PATH:/usr/local/go/bin

# For future sessions
for rcfile in ~/.bashrc ~/.profile ~/.zshrc; do
    if [ -f "$rcfile" ] && ! grep -q "$GO_PATH_EXPORT" "$rcfile"; then
        echo "$GO_PATH_EXPORT" >> "$rcfile"
    fi
done

if go version; then
    log_success "Go installed successfully: $(go version)"
else
    log_error "Go installation failed"
    exit 1
fi

# =====================
# Rust Installation
# =====================
log_info "Installing Rust..."
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source "$HOME/.cargo/env"

if rustc --version && cargo --version; then
    log_success "Rust installed successfully: $(rustc --version)"
    log_success "Cargo installed successfully: $(cargo --version)"
else
    log_error "Rust installation failed"
    exit 1
fi

# =====================
# Flatpak Configuration
# =====================
log_info "Configuring Flatpak..."
if ! flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo; then
    log_error "Failed to add Flathub repository"
    exit 1
fi

# =====================
# Postman Installation
# =====================
log_info "Installing Postman via Flatpak..."
if flatpak install -y flathub com.getpostman.Postman; then
    log_success "Postman installed successfully"
    echo "Run with: flatpak run com.getpostman.Postman"
else
    log_error "Failed to install Postman"
fi

# ======================
# Insomnia Installation
# ======================
log_info "Installing Insomnia via Flatpak..."
if flatpak install -y flathub rest.insomnia.Insomnia; then
    log_success "Insomnia installed successfully"
    echo "Run with: flatpak run rest.insomnia.Insomnia"
else
    log_error "Failed to install Insomnia"
fi

# =================
# Final Completion
# =================
log_info "System configuration complete!"
echo ""
log_success "Available commands:"
echo "  Postman:  flatpak run com.getpostman.Postman"
echo "  Insomnia: flatpak run rest.insomnia.Insomnia"
echo "  TMUX:     tmux"
echo "  Ollama:   ollama"
echo "  Docker:   $(docker --version 2>/dev/null || echo 'not available')"
echo "  Go:       $(go version 2>/dev/null || echo 'not available')"
echo "  Python:   $(python3 --version 2>/dev/null || echo 'not available')"
echo "  Rust:     $(rustc --version 2>/dev/null || echo 'not available')"
echo ""
log_info "Note: After logout/login you can run docker commands without sudo."
log_info "Note: You may need to start a new shell for PATH changes to take effect."

# ======================
# Favorite Apps Setup
# ======================
log_info "Setting favorite apps..."
FAVORITES="[ "

# Check for Ptyxis
if [ -f "/usr/share/applications/org.gnome.Ptyxis.desktop" ] || 
   [ -f "/usr/local/share/applications/org.gnome.Ptyxis.desktop" ] ||
   [ -f "/var/lib/flatpak/exports/share/applications/org.gnome.Ptyxis.desktop" ]; then
    FAVORITES+="'org.gnome.Ptyxis.desktop'"
    log_info "Added Ptyxis terminal to favorites"
fi

# Check for web browsers
if [ -f "/usr/share/applications/org.mozilla.firefox.desktop" ] || 
   [ -f "/var/lib/flatpak/exports/share/applications/org.mozilla.firefox.desktop" ]; then
    FAVORITES+=", 'org.mozilla.firefox.desktop'"
    log_info "Added Firefox to favorites"
fi

# Check for communication apps
if [ -f "/usr/share/applications/discord.desktop" ] || 
   [ -f "/var/lib/flatpak/exports/share/applications/com.discordapp.Discord.desktop" ]; then
    FAVORITES+=", 'com.discordapp.Discord.desktop'"
    log_info "Added Discord to favorites"
fi

# Check for games
if [ -f "/usr/share/applications/steam.desktop" ] || 
   [ -f "/var/lib/flatpak/exports/share/applications/com.valvesoftware.Steam.desktop" ]; then
    FAVORITES+=", 'com.valvesoftware.Steam.desktop'"
    log_info "Added Steam to favorites"
fi

FAVORITES+="]"

# Set favorite apps in GNOME
gsettings set org.gnome.shell favorite-apps "$FAVORITES"
log_success "Favorite apps configured: $FAVORITES"

exit 0