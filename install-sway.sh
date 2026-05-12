#!/usr/bin/env bash
# install-sway.sh
# Installs sway and related tools on Ubuntu 24.04
# Run as your normal user (sudo will be invoked where needed)
#
# Usage: ./install-sway.sh [builds-dir]
#   builds-dir  Where to clone source repos (default: /tmp/sway-builds)
#   Example: ./install-sway.sh ~/src

set -euo pipefail

BUILDS_DIR="${1:-/tmp/sway-builds}"
echo "==> Using builds directory: $BUILDS_DIR"
mkdir -p "$BUILDS_DIR"

# ─── Helpers ─────────────────────────────────────────────────────────────────

# Clone a repo, or pull latest if the directory already exists
clone_pull() {
    local url="$1"
    local name="$2"
    local dir="$BUILDS_DIR"/"$name"
    if [ -d "/.git" ]; then
        echo "  (directory exists, pulling latest)"
        git -C "$dir" pull
    else
        git clone "$url" "$dir"
    fi
}

# Add a line to ~/.profile if it isn't already there
add_to_profile() {
    local line="$1"
    grep -qxF "$line" ~/.profile 2>/dev/null || echo "$line" >> ~/.profile
}

# Returns 0 if the command exists on PATH, 1 otherwise
is_installed() {
    command -v "$1" &>/dev/null
}

# ─── Package lists ────────────────────────────────────────────────────────────

echo "Updating package lists..."
sudo apt update

echo "Installing from apt repositories..."
echo "[+] Sway ecosystem: sway, swayidle, swaylock, swaybg"
echo "[+] System utils: waybar, grim, slurp, nvim"
echo "[+] Build dependencies: meson, ninja, git, libs, etc."

sudo apt install -y sway swayidle swaylock swaybg xwayland \
  waybar grim slurp

sudo apt install -y --no-install-recommends libwayland-dev \
  playerctl brightnessctl imagemagick libxkbcommon-x11-dev \
  wl-clipboard libxcb-util-dev libxcb-xinerama0-dev neovim \
  meson ninja-build bison wayland-protocols liblz4-dev git \
  libglib2.0-dev libpango1.0-dev libxcb-xkb-dev scdoc flex \
  libxkbcommon-dev libxcb-icccm4-dev libgdk-pixbuf-2.0-dev \
  libcairo2-dev libstartup-notification0-dev python3-i3ipc \
  libxcb-ewmh-dev check libxcb-randr0-dev libegl1-mesa-dev \
  policykit-1-gnome cargo libnotify-bin fontconfig


# ─── swaylock-effects ────────────────────────────────────────────────────────

if [ -x /usr/local/bin/swaylock ]; then
    echo "swaylock-effects already installed, skipping"
else
    echo "Building swaylock-effects..."
    clone_pull https://github.com/mortie/swaylock-effects.git swaylock-effects
    cd "$BUILDS_DIR"/swaylock-effects
    rm -rf build
    meson setup build
    ninja -C build
    sudo ninja -C build install
    cd ~

    echo "[+] Setting SUID bit on swaylock (required on Ubuntu)..."
    sudo chmod a+s /usr/local/bin/swaylock
fi

# ─── Rofi ────────────────────────────────────────────────────────────────────

if [ -x /usr/local/bin/rofi ]; then
    echo "rofi already installed, skipping"
else
    echo "Building rofi..."
    clone_pull https://github.com/davatorium/rofi.git rofi
    cd "$BUILDS_DIR"/rofi
    git submodule update --init
    rm -rf build
    meson setup build
    ninja -C build
    sudo ninja -C build install
    cd ~
fi

# ─── Yazi ────────────────────────────────────────────────────────────────────

if is_installed yazi; then
    echo "yazi already installed, skipping"
else
    echo "Installing yazi via snap..."
    sudo snap install yazi --classic
fi

# ─── swww ────────────────────────────────────────────────────────────────────

if is_installed swww; then
    echo "swww already installed, skipping"
else
    echo "Building swww from source..."
    clone_pull https://github.com/LGFae/swww.git swww
    cd "$BUILDS_DIR"/swww
    cargo build --release
    mkdir -p "$HOME/.local/bin"
    install -m 0755 target/release/swww "$HOME/.local/bin/swww"
    install -m 0755 target/release/swww-daemon "$HOME/.local/bin/swww-daemon"
    cd ~
fi

# ─── autotiling ──────────────────────────────────────────────────────────────

if is_installed autotiling; then
    echo "autotiling already installed, skipping"
else
    echo "Installing autotiling from source..."

    clone_pull https://github.com/nwg-piotr/autotiling.git autotiling
    mkdir -p "$HOME/.local/bin"
    install -m 0755 "$BUILDS_DIR"/autotiling/autotiling/main.py "$HOME/.local/bin/autotiling"
fi

# ─── Kitty ───────────────────────────────────────────────────────────────────

if [ -x "$HOME/.local/kitty.app/bin/kitty" ]; then
    echo "kitty already installed, skipping"
else
    echo "Installing kitty via official binary installer..."
    curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin

    echo "==> Setting up kitty symlinks and desktop entry..."
    mkdir -p ~/.local/bin ~/.local/share/applications
    ln -sf ~/.local/kitty.app/bin/kitty ~/.local/kitty.app/bin/kitten ~/.local/bin/
    cp ~/.local/kitty.app/share/applications/kitty.desktop ~/.local/share/applications/
    cp ~/.local/kitty.app/share/applications/kitty-open.desktop ~/.local/share/applications/ 2>/dev/null || true
    sed -i "s|Icon=kitty|Icon=$(readlink -f ~)/.local/kitty.app/share/icons/hicolor/256x256/apps/kitty.png|g" \
      ~/.local/share/applications/kitty*.desktop
    sed -i "s|Exec=kitty|Exec=$(readlink -f ~)/.local/kitty.app/bin/kitty|g" \
      ~/.local/share/applications/kitty*.desktop
fi


# ─── Nerd Fonts ───────────────────────────────────────────────────────────────

echo "Installing Nerd Fonts..."
install_nerd_font() {
    local name="$1"
    local font_dir="$HOME/.local/share/fonts/NerdFonts/$name"

    if [ -d "$font_dir" ] && [ -n "$(ls -A "$font_dir" 2>/dev/null)" ]; then
        echo "$name Nerd Font already installed, skipping"
        return
    fi

    echo "[+] Installing $name Nerd Font..."
    mkdir -p "$font_dir"
    curl -fL "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${name}.tar.xz" \
        | tar -xJ -C "$font_dir"
}

install_nerd_font "Iosevka"
install_nerd_font "IosevkaTerm"
install_nerd_font "MPlus"

echo "[+] Rebuilding font cache..."
fc-cache -f ~/.local/share/fonts

# ─── PATH additions ───────────────────────────────────────────────────────────

echo "Updating PATH in ~/.profile..."

# ~/.local/bin — kitty
add_to_profile 'export PATH="$HOME/.local/bin:$PATH"'

# ~/.cargo/bin — cargo
add_to_profile 'export PATH="$HOME/.cargo/bin:$PATH"'

# /snap/bin — yazi
add_to_profile 'export PATH="/snap/bin:$PATH"'

# /usr/local/bin — swaylock-effects, rofi
add_to_profile 'export PATH="/usr/local/bin:$PATH"'

# ─── Systemd user environment (graphical sessions) ────────────────────────────

GRAPHICAL_PATH=$HOME/.local/bin:$HOME/.cargo/bin:/snap/bin:/usr/local/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games

echo "[+] Configuring PATH for graphical sessions via ~/.config/environment.d/..."
mkdir -p ~/.config/environment.d

cat > ~/.config/environment.d/10-sway-paths.conf << EOF
PATH=$GRAPHICAL_PATH
EOF

echo "[+] PATH is ""$PATH"
echo "[+] PATH for graphical sessions is ""$GRAPHICAL_PATH"

# ─── Config directories ───────────────────────────────────────────────────────

echo "Creating config directories..."
mkdir -p ~/.config/sway ~/.config/swaylock ~/.config/wallpapers

echo "Installation complete!"
echo "1. Run 'source ~/.profile' to apply changes in current shell,"
echo "2. Run ./restore_configs.sh to install configs"
echo "3. Log out, select 'Sway' at the login screen, and log back in"
echo ""