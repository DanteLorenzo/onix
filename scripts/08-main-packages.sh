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
    VirtualBox 


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
# Zen Browser Installation (Flatpak)
# =====================
log_info "Installing Zen Browser via Flatpak..."

if flatpak install -y flathub app.zen_browser.zen; then
    log_success "Zen Browser installed successfully via Flatpak"
    echo "Run with: flatpak run io.github.zen-browser.Zen"
else
    log_error "Failed to install Zen Browser via Flatpak"
fi

# =====================
# Whaler Installation (Flatpak)
# =====================
if flatpak install -y flathub com.github.sdv43.whaler; then
    log_success "Whaler installed successfully"
    echo "Run with: flatpak run com.github.sdv43.whaler"
else
    log_error "Failed to install Whaler"
fi

# =====================
# Pods Installation (Flatpak)
# =====================
if flatpak install -y flathub com.github.marhkb.Pods; then
    log_success "Pods installed successfully"
    echo "Run with: flatpak run com.github.marhkb.Pods"
else
    log_error "Failed to install Pods"
fi

# =====================
# Install Outline Manager
# =====================
if flatpak install -y flathub org.getoutline.OutlineManager; then
    log_success "Outline Manager installed successfully"
    echo "Run with: flatpak run org.getoutline.OutlineManager"
else
    log_error "Failed to install Outline Manager"
fi

# =====================
# Install Outline Client
# =====================
if flatpak install -y flathub org.getoutline.OutlineClient; then
    log_success "Outline Client installed successfully"
    echo "Run with: flatpak run org.getoutline.OutlineClient"
else
    log_error "Failed to install Outline Client"
fi

# =============================
# Ton Keeper Installation (RPM)
# =============================
log_info "Checking Ton Keeper installation..."

# Ensure system architecture is x86_64
if [ "$(uname -m)" != "x86_64" ]; then
    log_error "This script requires x86_64 architecture. Detected: $(uname -m)"
    exit 1
fi

# Get currently installed Ton Keeper version, if any
CURRENT_TONKEEPER_VERSION=$(rpm -q Tonkeeper --queryformat '%{VERSION}' 2>/dev/null)

# Fetch the latest version from GitHub
log_info "Fetching latest release info from GitHub..."
LATEST_TONKEEPER_VERSION=$(curl -s https://api.github.com/repos/tonkeeper/tonkeeper-web/releases/latest | grep -oP '"tag_name": "\Kv?\d+\.\d+\.\d+')
LATEST_TONKEEPER_VERSION=${LATEST_TONKEEPER_VERSION#v}  # remove leading "v" if present

if [ -z "$LATEST_TONKEEPER_VERSION" ]; then
    log_error "Failed to get latest Ton Keeper version"
    exit 1
fi

NEED_TONKEEPER_INSTALL=1

# Compare installed version with latest available
if [ -n "$CURRENT_TONKEEPER_VERSION" ]; then
    log_info "Current Ton Keeper version: $CURRENT_TONKEEPER_VERSION"
    log_info "Latest available version: $LATEST_TONKEEPER_VERSION"

    # Version comparison function
    version_compare() {
        [ "$1" = "$2" ] && return 0
        local IFS=.
        local i ver1=($1) ver2=($2)
        for ((i=${#ver1[@]}; i<${#ver2[@]}; i++)); do ver1[i]=0; done
        for ((i=0; i<${#ver1[@]}; i++)); do
            if [[ -z ${ver2[i]} ]]; then ver2[i]=0; fi
            if ((10#${ver1[i]} > 10#${ver2[i]})); then return 1; fi
            if ((10#${ver1[i]} < 10#${ver2[i]})); then return 2; fi
        done
        return 0
    }

    # Call comparison and check result
    version_compare "$CURRENT_TONKEEPER_VERSION" "$LATEST_TONKEEPER_VERSION"
    cmp_result=$?

    case $cmp_result in
        0)
            log_success "Latest Ton Keeper version already installed"
            NEED_TONKEEPER_INSTALL=0
            ;;
        1)
            log_info "Installed version is newer than latest GitHub release"
            NEED_TONKEEPER_INSTALL=0
            ;;
        2)
            log_info "Newer version available; proceeding with update..."
            ;;
    esac
else
    log_info "Ton Keeper not installed; proceeding with installation..."
fi

# Proceed only if installation or update is required
if [ $NEED_TONKEEPER_INSTALL -eq 1 ]; then
    log_info "Fetching Ton Keeper release assets..."

    ASSETS_JSON=$(curl -s https://api.github.com/repos/tonkeeper/tonkeeper-web/releases/latest | jq -r '.assets[] | {name: .name, url: .browser_download_url}')

    if [ -z "$ASSETS_JSON" ]; then
        log_error "Failed to retrieve release assets"
        exit 1
    fi

    # Extract URL for x86_64 RPM file
    TONKEEPER_RPM_URL=$(echo "$ASSETS_JSON" | jq -r 'select(.name | test("Tonkeeper.*x86_64\\.rpm"; "i")) | .url')
    if [ -z "$TONKEEPER_RPM_URL" ]; then
        log_error "Could not find x86_64 RPM package in release assets"
        exit 1
    fi

    log_info "Download URL for x86_64 RPM: $TONKEEPER_RPM_URL"

    TONKEEPER_TEMP_RPM="/tmp/tonkeeper-${LATEST_TONKEEPER_VERSION}.x86_64.rpm"

    # Download the RPM package
    log_info "Downloading Ton Keeper ${LATEST_TONKEEPER_VERSION}..."
    wget --show-progress -q "$TONKEEPER_RPM_URL" -O "$TONKEEPER_TEMP_RPM" || {
        log_error "Failed to download Ton Keeper RPM"
        exit 1
    }

    # Install the RPM package
    log_info "Installing Ton Keeper..."
    sudo dnf install -y "$TONKEEPER_TEMP_RPM" || {
        log_error "Failed to install Ton Keeper"
        rm -f "$TONKEEPER_TEMP_RPM"
        exit 1
    }

    # Clean up
    rm -f "$TONKEEPER_TEMP_RPM"

    # Check for .desktop file
    if [ -f "/usr/share/applications/Tonkeeper.desktop" ]; then
        log_success "Ton Keeper ${LATEST_TONKEEPER_VERSION} installed successfully"
    else
        log_warning "Ton Keeper installed, but .desktop file not found in expected location"
    fi
else
    log_info "Skipping Ton Keeper installation as no update is needed"
fi


# =====================
# Obsidian Installation (Latest AppImage)
# =====================
log_info "Installing latest Obsidian version..."

# Create directories
APP_DIR="$HOME/Applications"
DESKTOP_DIR="/usr/share/applications"
ICON_DIR="/usr/share/icons/hicolor/256x256/apps"
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
OBSIDIAN_FILE="$APP_DIR/Obsidian-${OBSIDIAN_VERSION}.AppImage"  # Сохраняем с версией в имени файла

# Download and install
NEED_DOWNLOAD=1
if [ -f "$OBSIDIAN_FILE" ]; then
    # Версия уже содержится в имени файла
    log_info "Latest Obsidian version ${OBSIDIAN_VERSION} already installed"
    NEED_DOWNLOAD=0
else
    # Проверим, есть ли другие версии Obsidian
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

# Создаем симлинк без версии для удобства
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
ICON_INSTALLED=0
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Method 1: Extract icon from AppImage
if [ -f "$OBSIDIAN_FILE" ]; then
    "$OBSIDIAN_FILE" --appimage-extract &>/dev/null
    if [ -f squashfs-root/usr/share/icons/hicolor/256x256/apps/obsidian.png ]; then
        cp squashfs-root/usr/share/icons/hicolor/256x256/apps/obsidian.png "$ICON_DIR/obsidian.png" && ICON_INSTALLED=1
        log_info "Obsidian icon extracted from AppImage"
    fi
    rm -rf squashfs-root &>/dev/null
fi


# Update desktop database
update-desktop-database "$DESKTOP_DIR"
log_success "Obsidian ${OBSIDIAN_VERSION} installed successfully (icon installed: $([ $OBSIDIAN_ICON_INSTALLED -eq 1 ] && echo "yes" || echo "no"))"


# =============================
# DBeaver Installation (RPM)
# =============================
# DBeaver is already installed in the main DNF section
log_info "Checking DBeaver installation..."
if dbeaver-ce --version &>/dev/null; then
    log_success "DBeaver is already installed: $(dbeaver-ce --version 2>/dev/null | head -n1)"
else
    log_info "Installing DBeaver..."
    sudo dnf install -y dbeaver-ce
    if [ $? -eq 0 ]; then
        log_success "DBeaver installed successfully"
    else
        log_error "Failed to install DBeaver"
    fi
fi

# =============================
# Cursor Installation (RPM)
# =============================
log_info "Installing Cursor..."
sudo rpm --import https://download.cursor.sh/linux/signing-key.public
sudo sh -c 'echo -e "[cursor]\nname=Cursor\nbaseurl=https://download.cursor.sh/linux/rpm\nenabled=1\ngpgcheck=1\ngpgkey=https://download.cursor.sh/linux/signing-key.public" > /etc/yum.repos.d/cursor.repo'
sudo dnf install -y cursor

if [ $? -eq 0 ]; then
    log_success "Cursor installed successfully"
else
    log_error "Failed to install Cursor"
fi

# =============================
# Dolphin Anty Installation (RPM)
# =============================
log_info "Installing Dolphin Anty..."
DOLPHIN_ANTY_URL="https://dolphin-anty.com/download.php?get-linux=true"
DOLPHIN_ANTY_TEMP="/tmp/dolphin-anty.rpm"

wget -O "$DOLPHIN_ANTY_TEMP" "$DOLPHIN_ANTY_URL"
if [ $? -eq 0 ]; then
    sudo dnf install -y "$DOLPHIN_ANTY_TEMP"
    if [ $? -eq 0 ]; then
        log_success "Dolphin Anty installed successfully"
    else
        log_error "Failed to install Dolphin Anty RPM"
    fi
    rm -f "$DOLPHIN_ANTY_TEMP"
else
    log_error "Failed to download Dolphin Anty"
fi

# =================
# Final Completion
# =================
log_info "System configuration complete!"
echo ""
log_success "Installed versions:"
echo "  Docker:   $(docker --version 2>/dev/null || echo 'not available')"
echo "  Go:       $(go version 2>/dev/null || echo 'not available')"
echo "  Python:   $(python3 --version 2>/dev/null || echo 'not available')"
echo "  Rust:     $(rustc --version 2>/dev/null || echo 'not available')"
echo "  Obsidian: $OBSIDIAN_FILE"
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

# Add Boxes
if [ -f "/usr/share/applications/org.gnome.Boxes.desktop" ]; then
    FAVORITES+=", 'org.gnome.Boxes.desktop'"
    log_info "Added Boxes to favorites"
fi

# Add Virtualbox
if [ -f "/usr/share/applications/virtualbox.desktop" ]; then
    FAVORITES+=", 'virtualbox.desktop'"
    log_info "Added Virtualbox to favorites"
fi

# Add KeePassXC
if [ -f "/usr/share/applications/org.keepassxc.KeePassXC.desktop" ]; then
    FAVORITES+=", 'org.keepassxc.KeePassXC.desktop'"
    log_info "Added KeePassXC to favorites"
fi

# Add Ton Keeper
if [ -f "/usr/share/applications/Tonkeeper.desktop" ]; then
    FAVORITES+=", 'Tonkeeper.desktop'"
    log_info "Added Ton Keeper to favorites"
fi

# Add Zen Browser (Flatpak)
if [ -f "/var/lib/flatpak/exports/share/applications/app.zen_browser.zen.desktop" ]; then
    FAVORITES+=", 'app.zen_browser.zen.desktop'"
    log_info "Added Zen Browser (Flatpak) to favorites"
fi

# Check for LibreWolf browser
if [ -f "/usr/share/applications/librewolf.desktop" ]; then
    FAVORITES+=", 'librewolf.desktop'"
    log_info "Added LibreWolf browser to favorites"
elif [ -f "/var/lib/flatpak/exports/share/applications/io.gitlab.librewolf-community.desktop" ]; then
    FAVORITES+=", 'io.gitlab.librewolf-community.desktop'"
    log_info "Added LibreWolf (Flatpak) to favorites"
fi

# Check for Brave browser
if [ -f "/usr/share/applications/brave-browser.desktop" ]; then
    FAVORITES+=", 'brave-browser.desktop'"
    log_info "Added Brave browser to favorites"
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