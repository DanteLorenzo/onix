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
    discord \
    wget \
    macchanger \
    desktop-file-utils \
    hashcat \
    htop \
    btop \
    gimp \
    nmap \
    gobuster \
    wireshark \
    podman \
    wireguard-tools \
    dnf-plugins-core \
    telegram \
    yt-dlp \
    fastfetch \
    keepassxc \
    medusa \
    hydra \
    john \
    deluge \
    hping3 \
    hwinfo \
    nload \
    openvpn \
    remmina \
    remmina-plugins-rdp \
    remmina-plugins-vnc \
    remmina-plugins-www \
    remmina-plugins-spice \
    remmina-plugins-secret \
    simplescreenrecorder \
    ansible \
    wine \
    bottles \

# Add VSCodium repository
sudo rpm --import https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/-/raw/master/pub.gpg
printf "[gitlab.com_paulcarroty_vscodium_repo]\nname=download.vscodium.com\nbaseurl=https://download.vscodium.com/rpms/\nenabled=1\ngpgcheck=1\nrepo_gpgcheck=1\ngpgkey=https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/-/raw/master/pub.gpg\nmetadata_expire=1h" | sudo tee -a /etc/yum.repos.d/vscodium.repo

log_info "Installing VSCodium..."
sudo dnf install -y codium

# Adding browser repositories
log_info "Adding browser repositories..."

# Add LibreWolf repository
curl -fsSL https://repo.librewolf.net/librewolf.repo | sudo pkexec tee /etc/yum.repos.d/librewolf.repo

# Add Brave browser repository and import its signing key
sudo dnf config-manager addrepo --overwrite --from-repofile=https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo

# Installing browsers
log_info "Installing browsers..."
sudo dnf install -y \
    librewolf \
    brave-browser

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
log_info "Checking Go installation..."

# Get the latest stable Go version
LATEST_GO_VERSION=$(curl -s https://go.dev/VERSION?m=text | head -1)
CURRENT_GO_VERSION=$(go version 2>/dev/null | awk '{print $3}')

if [ -n "$CURRENT_GO_VERSION" ] && [ "$CURRENT_GO_VERSION" == "$LATEST_GO_VERSION" ]; then
    log_success "Latest Go version already installed: $(go version)"
else
    if [ -n "$CURRENT_GO_VERSION" ]; then
        log_info "Current Go version: $CURRENT_GO_VERSION"
        log_info "Latest available version: $LATEST_GO_VERSION"
        log_info "Updating Go to latest version..."
    else
        log_info "Installing latest Go version..."
    fi

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
# Amberol Installation
# =====================
log_info "Checking Amberol installation..."
if ! flatpak list | grep -q io.bassi.Amberol; then
    log_info "Installing Amberol via Flatpak..."
    if flatpak install -y https://dl.flathub.org/repo/appstream/io.bassi.Amberol.flatpakref; then
        log_success "Amberol installed successfully"
    else
        log_error "Failed to install Amberol"
    fi
else
    log_success "Amberol is already installed"
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

# =====================
# Ton Keeper Installation (RPM)
# =====================
log_info "Installing Ton Keeper..."

TONKEEPER_RPM_URL="https://github.com/tonkeeper/tonkeeper-web/releases/latest/download/Tonkeeper-$(uname -m).rpm"
TONKEEPER_TEMP_RPM="/tmp/tonkeeper-latest.rpm"

# Download latest RPM
log_info "Downloading latest Ton Keeper RPM..."
wget "$TONKEEPER_RPM_URL" -O "$TONKEEPER_TEMP_RPM" || {
    log_error "Failed to download Ton Keeper RPM"
    exit 1
}

# Install the RPM
log_info "Installing Ton Keeper RPM..."
sudo dnf install -y "$TONKEEPER_TEMP_RPM" || {
    log_error "Failed to install Ton Keeper RPM"
    exit 1
}

# Clean up
rm -f "$TONKEEPER_TEMP_RPM"

# Verify installation
if [ -f "/usr/share/applications/tonkeeper.desktop" ]; then
    TONKEEPER_DESKTOP_FILE="/usr/share/applications/tonkeeper.desktop"
    log_success "Ton Keeper installed successfully"
else
    log_error "Ton Keeper installation completed but desktop file not found"
    exit 1
fi

# =====================
# Obsidian Installation (Latest AppImage)
# =====================
log_info "Installing latest Obsidian version..."

# Create directories
APP_DIR="$HOME/Applications"
DESKTOP_DIR="$HOME/.local/share/applications"
ICON_DIR="$HOME/.local/share/icons/hicolor/256x256/apps"
mkdir -p "$APP_DIR" "$DESKTOP_DIR" "$ICON_DIR"

# Get latest Obsidian version from GitHub API
log_info "Checking latest Obsidian version..."
OBSIDIAN_VERSION=$(curl -s https://api.github.com/repos/obsidianmd/obsidian-releases/releases/latest | grep -oP '"tag_name": "\Kv?\d+\.\d+\.\d+')
if [ -z "$OBSIDIAN_VERSION" ]; then
    log_error "Failed to get latest Obsidian version"
    exit 1
fi

# Remove 'v' prefix if present
OBSIDIAN_VERSION=${OBSIDIAN_VERSION#v}
OBSIDIAN_URL="https://github.com/obsidianmd/obsidian-releases/releases/download/v${OBSIDIAN_VERSION}/Obsidian-${OBSIDIAN_VERSION}.AppImage"
OBSIDIAN_FILE="$APP_DIR/Obsidian-${OBSIDIAN_VERSION}.AppImage"

# Download and install
NEED_DOWNLOAD=1
if [ -f "$OBSIDIAN_FILE" ]; then
    log_info "Latest Obsidian version ${OBSIDIAN_VERSION} already installed"
    NEED_DOWNLOAD=0
else
    # Check for older versions
    for old_file in "$APP_DIR"/Obsidian-*.AppImage; do
        if [ -f "$old_file" ] && [ "$old_file" != "$OBSIDIAN_FILE" ]; then
            old_version=$(basename "$old_file" | grep -oP '\d+\.\d+\.\d+')
            log_info "Found older version ${old_version}, will update to ${OBSIDIAN_VERSION}"
            rm "$old_file"
            break
        fi
    done
fi

if [ $NEED_DOWNLOAD -eq 1 ]; then
    log_info "Downloading Obsidian ${OBSIDIAN_VERSION}..."
    wget "$OBSIDIAN_URL" -O "$OBSIDIAN_FILE" || {
        log_error "Failed to download Obsidian"
        exit 1
    }
    chmod +x "$OBSIDIAN_FILE"
    log_success "Obsidian downloaded and made executable"
fi

# Create symlink for easier access
OBSIDIAN_LINK="$APP_DIR/Obsidian.AppImage"
ln -sf "$OBSIDIAN_FILE" "$OBSIDIAN_LINK"

# Create desktop file
OBSIDIAN_DESKTOP_FILE="$DESKTOP_DIR/obsidian.desktop"
cat > "$OBSIDIAN_DESKTOP_FILE" <<EOL
[Desktop Entry]
Version=1.0
Type=Application
Name=Obsidian
Comment=A knowledge base that works on local Markdown files
Exec="$OBSIDIAN_LINK" --no-sandbox
Icon=obsidian
Categories=Office;TextEditor;
Terminal=false
StartupWMClass=obsidian
EOL

# Handle icon installation
OBSIDIAN_ICON_INSTALLED=0
if [ -f "$OBSIDIAN_FILE" ]; then
    "$OBSIDIAN_FILE" --appimage-extract &>/dev/null
    if [ -f squashfs-root/usr/share/icons/hicolor/256x256/apps/obsidian.png ]; then
        cp squashfs-root/usr/share/icons/hicolor/256x256/apps/obsidian.png "$ICON_DIR/obsidian.png" && OBSIDIAN_ICON_INSTALLED=1
        log_info "Obsidian icon extracted from AppImage"
    fi
    rm -rf squashfs-root &>/dev/null
fi

# =====================
# Zen Browser Installation (AppImage)
# =====================
log_info "Installing Zen Browser (AppImage)..."

# Create directories if they don't exist
mkdir -p "$APP_DIR" "$DESKTOP_DIR" "$ICON_DIR"

# Get latest Zen Browser version from GitHub API
log_info "Checking latest Zen Browser version..."
ZEN_VERSION=$(curl -s https://api.github.com/repos/zen-browser/desktop/releases/latest | grep -oP '"tag_name": "\Kv?\d+\.\d+\.\d+\w*')
if [ -z "$ZEN_VERSION" ]; then
    log_error "Failed to get latest Zen Browser version"
    exit 1
fi

# Remove 'v' prefix if present
ZEN_VERSION=${ZEN_VERSION#v}
ZEN_URL="https://github.com/zen-browser/desktop/releases/download/${ZEN_VERSION}/zen-x86_64.AppImage"
ZEN_FILE="$APP_DIR/Zen-${ZEN_VERSION}.AppImage"
ZEN_ICON_PATH="$ICON_DIR/zen-browser.png"

# Download and install
NEED_DOWNLOAD=1
if [ -f "$ZEN_FILE" ]; then
    log_info "Latest Zen Browser version ${ZEN_VERSION} already installed"
    NEED_DOWNLOAD=0
else
    # Remove any old versions
    rm -f "$APP_DIR"/Zen-*.AppImage
    
    log_info "Downloading Zen Browser ${ZEN_VERSION}..."
    wget "$ZEN_URL" -O "$ZEN_FILE" || {
        log_error "Failed to download Zen Browser"
        exit 1
    }
    chmod +x "$ZEN_FILE"
    log_success "Zen Browser downloaded and made executable"
fi

# Create symlink for easier access
ZEN_LINK="$APP_DIR/Zen.AppImage"
ln -sf "$ZEN_FILE" "$ZEN_LINK"

# Create desktop file with absolute path to icon
ZEN_DESKTOP_FILE="$DESKTOP_DIR/zen-browser.desktop"
ZEN_ICON_PATH="$ICON_DIR/zen-browser.png"

# Handle icon installation
ZEN_ICON_INSTALLED=0
if [ -f "$ZEN_FILE" ]; then
    # Extract AppImage to get the icon
    "$ZEN_FILE" --appimage-extract &>/dev/null
    
    # Check multiple possible icon locations
    POSSIBLE_ICON_PATHS=(
        "squashfs-root/zen.png"
        "squashfs-root/.DirIcon"
        "squashfs-root/usr/share/icons/hicolor/256x256/apps/zen.png"
        "squashfs-root/usr/share/pixmaps/zen.png"
    )
    
    for icon_source in "${POSSIBLE_ICON_PATHS[@]}"; do
        if [ -f "$icon_source" ]; then
            cp "$icon_source" "$ZEN_ICON_PATH" && ZEN_ICON_INSTALLED=1
            log_info "Zen Browser icon found at: $icon_source"
            break
        fi
    done
    
    # Clean up extracted files
    rm -rf squashfs-root &>/dev/null
fi

# Create desktop file with NO sandbox flag and absolute paths
cat > "$ZEN_DESKTOP_FILE" <<EOL
[Desktop Entry]
Version=1.0
Type=Application
Name=Zen Browser
GenericName=Web Browser
Comment=A privacy-focused web browser
Exec="$ZEN_LINK" --no-sandbox %U
Icon=$ZEN_ICON_PATH
Categories=Network;WebBrowser;
Terminal=false
StartupWMClass=zen-browser
MimeType=text/html;text/xml;application/xhtml+xml;x-scheme-handler/http;x-scheme-handler/https;
EOL

# Update desktop database
update-desktop-database "$DESKTOP_DIR"
log_success "Zen Browser ${ZEN_VERSION} installed successfully (icon installed: $([ $ZEN_ICON_INSTALLED -eq 1 ] && echo "yes" || echo "no"))"
log_success "Obsidian ${OBSIDIAN_VERSION} installed successfully (icon installed: $([ $OBSIDIAN_ICON_INSTALLED -eq 1 ] && echo "yes" || echo "no"))"

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
echo "  Obsidian: $OBSIDIAN_FILE"
echo "  Zen Browser: $ZEN_FILE"
echo ""
log_info "Note: After logout/login you can run docker commands without sudo."
log_info "Note: You may need to start a new shell for PATH changes to take effect."

# ======================
# Favorite Apps Setup
# ======================
log_info "Setting favorite apps..."
FAVORITES="["

# Always include terminal first
FAVORITES+=" 'org.gnome.Terminal.desktop'"

# Check for Ptyxis
if [ -f "/usr/share/applications/org.gnome.Ptyxis.desktop" ] || 
   [ -f "/usr/local/share/applications/org.gnome.Ptyxis.desktop" ] ||
   [ -f "/var/lib/flatpak/exports/share/applications/org.gnome.Ptyxis.desktop" ]; then
    FAVORITES+=", 'org.gnome.Ptyxis.desktop'"
    log_info "Added Ptyxis terminal to favorites"
fi

# Add Obsidian if installed
if [ -f "$OBSIDIAN_DESKTOP_FILE" ]; then
    FAVORITES+=", 'obsidian.desktop'"
    log_info "Added Obsidian to favorites"
fi

# Add VSCodium
if [ -f "/usr/share/applications/codium.desktop" ]; then
    FAVORITES+=", 'codium.desktop'"
    log_info "Added VSCodium to favorites"
fi

# Add Postman
if [ -f "/var/lib/flatpak/exports/share/applications/com.getpostman.Postman.desktop" ]; then
    FAVORITES+=", 'com.getpostman.Postman.desktop'"
    log_info "Added Postman to favorites"
fi

# Add KeePassXC
if [ -f "/usr/share/applications/org.keepassxc.KeePassXC.desktop" ]; then
    FAVORITES+=", 'org.keepassxc.KeePassXC.desktop'"
    log_info "Added KeePassXC to favorites"
fi

# Add Ton Keeper
if [ -f "/usr/share/applications/tonkeeper.desktop" ]; then
    FAVORITES+=", 'tonkeeper.desktop'"
    log_info "Added Ton Keeper to favorites"
fi

# Add Zen Browser if installed
if [ -f "$ZEN_DESKTOP_FILE" ]; then
    FAVORITES+=", 'zen-browser.desktop'"
    log_info "Added Zen Browser to favorites"
fi

# Check for Brave browser
if [ -f "/usr/share/applications/brave-browser.desktop" ]; then
    FAVORITES+=", 'brave-browser.desktop'"
    log_info "Added Brave browser to favorites"
fi

# Check for LibreWolf browser
if [ -f "/usr/share/applications/librewolf.desktop" ]; then
    FAVORITES+=", 'librewolf.desktop'"
    log_info "Added LibreWolf browser to favorites"
elif [ -f "/var/lib/flatpak/exports/share/applications/io.gitlab.librewolf-community.desktop" ]; then
    FAVORITES+=", 'io.gitlab.librewolf-community.desktop'"
    log_info "Added LibreWolf (Flatpak) to favorites"
fi

# Add Amberol
if [ -f "/var/lib/flatpak/exports/share/applications/io.bassi.Amberol.desktop" ]; then
    FAVORITES+=", 'io.bassi.Amberol.desktop'"
    log_info "Added Amberol to favorites"
fi

# Add Telegram
if [ -f "/usr/share/applications/org.telegram.desktop.desktop" ]; then
    FAVORITES+=", 'org.telegram.desktop.desktop'"
    log_info "Added Telegram to favorites"
elif [ -f "/var/lib/flatpak/exports/share/applications/org.telegram.desktop.desktop" ]; then
    FAVORITES+=", 'org.telegram.desktop.desktop'"
    log_info "Added Telegram (Flatpak) to favorites"
fi

# Check for Discord
if [ -f "/usr/share/applications/discord.desktop" ]; then
    FAVORITES+=", 'discord.desktop'"
    log_info "Added Discord (DNF) to favorites"
elif [ -f "/var/lib/flatpak/exports/share/applications/com.discordapp.Discord.desktop" ]; then
    FAVORITES+=", 'com.discordapp.Discord.desktop'"
    log_info "Added Discord (Flatpak) to favorites"
fi


# Add Deluge
if [ -f "/usr/share/applications/deluge.desktop" ]; then
    FAVORITES+=", 'deluge.desktop'"
    log_info "Added Deluge to favorites"
elif [ -f "/var/lib/flatpak/exports/share/applications/org.deluge_torrent.deluge.desktop" ]; then
    FAVORITES+=", 'org.deluge_torrent.deluge.desktop'"
    log_info "Added Deluge (Flatpak) to favorites"
fi

# Check for Steam
if [ -f "/usr/share/applications/steam.desktop" ]; then
    FAVORITES+=", 'steam.desktop'"
    log_info "Added Steam (DNF) to favorites"
elif [ -f "/var/lib/flatpak/exports/share/applications/com.valvesoftware.Steam.desktop" ]; then
    FAVORITES+=", 'com.valvesoftware.Steam.desktop'"
    log_info "Added Steam (Flatpak) to favorites"
fi

# Add Nautilus
if [ -f "/usr/share/applications/org.gnome.Nautilus.desktop" ]; then
    FAVORITES+=", 'org.gnome.Nautilus.desktop'"
    log_info "Added Nautilus to favorites"
fi

FAVORITES+=" ]"

# Set favorite apps in GNOME
gsettings set org.gnome.shell favorite-apps "$FAVORITES"
log_success "Favorite apps configured: $FAVORITES"

exit 0