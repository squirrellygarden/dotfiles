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
git_clone_or_pull() {
    local url="$1"
    local dir="$2"
    if [ -d "$dir/.git" ]; then
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

echo "==> Updating package lists..."
sudo apt update

echo "==> Installing sway, waybar, swayidle, swaylock, and supporting tools..."
sudo apt install -y \
  sway swayidle swaylock swaybg waybar \
  xwayland \
  grim slurp wl-clipboard \
  policykit-1-gnome \
  libnotify-bin \
  autotiling brightnessctl playerctl \
  fontconfig cargo \
  ffmpeg fd-find ripgrep fzf zoxide imagemagick

echo "==> Installing build dependencies (shared + per-project)..."
sudo apt install -y \
  meson ninja-build git \
  \
  `# swaylock-effects` \
  libwayland-dev wayland-protocols \
  libxkbcommon-dev scdoc libcairo2-dev libgdk-pixbuf-2.0-dev \
  \
  `# rofi` \
  libglib2.0-dev libpango1.0-dev \
  libxcb1-dev libxcb-ewmh-dev libxcb-icccm4-dev \
  libxcb-util-dev libxcb-xinerama0-dev libxcb-randr0-dev \
  libxcb-xkb-dev libxkbcommon-x11-dev libstartup-notification0-dev \
  flex bison check \
  \
  `# wpaperd` \
  libwayland-egl1 libegl1-mesa-dev libdav1d-dev

# ─── swaylock-effects ────────────────────────────────────────────────────────

# Check /usr/local/bin specifically — apt installs swaylock to /usr/bin,
# so presence in /usr/local/bin means we built swaylock-effects ourselves
if [ -x /usr/local/bin/swaylock ]; then
    echo "==> swaylock-effects already installed, skipping"
else
    echo "==> Building swaylock-effects..."
    git_clone_or_pull https://github.com/mortie/swaylock-effects.git "$BUILDS_DIR"/swaylock-effects
    cd "$BUILDS_DIR"/swaylock-effects
    rm -rf build
    meson setup build
    ninja -C build
    sudo ninja -C build install
    cd ~

    echo "==> Setting SUID bit on swaylock (required on Ubuntu)..."
    sudo chmod a+s /usr/local/bin/swaylock
fi

# ─── Rofi ────────────────────────────────────────────────────────────────────

# Same logic as swaylock — /usr/local/bin means we built it
if [ -x /usr/local/bin/rofi ]; then
    echo "==> rofi already installed, skipping"
else
    echo "==> Building rofi..."
    git_clone_or_pull https://github.com/davatorium/rofi.git "$BUILDS_DIR"/rofi
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
    echo "==> yazi already installed, skipping"
else
    echo "==> Installing yazi via snap..."
    sudo snap install yazi --classic
fi

# ─── wpaperd ─────────────────────────────────────────────────────────────────

if [ -x "$HOME/.cargo/bin/wpaperd" ]; then
    echo "==> wpaperd already installed, skipping"
else
    echo "==> Installing wpaperd via cargo..."
    cargo install wpaperd
fi

# ─── Kitty ───────────────────────────────────────────────────────────────────

if [ -x "$HOME/.local/kitty.app/bin/kitty" ]; then
    echo "==> kitty already installed, skipping"
else
    echo "==> Installing kitty via official binary installer..."
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

install_nerd_font() {
    local name="$1"
    local font_dir="$HOME/.local/share/fonts/NerdFonts/$name"

    if [ -d "$font_dir" ] && [ -n "$(ls -A "$font_dir" 2>/dev/null)" ]; then
        echo "==> $name Nerd Font already installed, skipping"
        return
    fi

    echo "==> Installing $name Nerd Font..."
    mkdir -p "$font_dir"
    curl -fL "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${name}.tar.xz" \
        | tar -xJ -C "$font_dir"
}

install_nerd_font "Iosevka"
install_nerd_font "IosevkaTerm"
install_nerd_font "MPlus"

echo "==> Rebuilding font cache..."
fc-cache -f ~/.local/share/fonts

# ─── PATH additions ───────────────────────────────────────────────────────────

echo "==> Updating PATH in ~/.profile..."

# ~/.local/bin — kitty, kitten
add_to_profile 'export PATH="$HOME/.local/bin:$PATH"'

# ~/.cargo/bin — wpaperd and any other cargo-installed tools
add_to_profile 'export PATH="$HOME/.cargo/bin:$PATH"'

# /snap/bin — yazi (and any other snap-installed tools)
add_to_profile 'export PATH="/snap/bin:$PATH"'

# /usr/local/bin — swaylock-effects, rofi (meson installs here by default)
# Usually already in PATH on Ubuntu, but ensure it's explicit
add_to_profile 'export PATH="/usr/local/bin:$PATH"'

# ─── Systemd user environment (graphical sessions) ────────────────────────────

# ~/.profile is only sourced by login shells (terminal, SSH).
# GDM starts sway via PAM/systemd and never reads ~/.profile, so none of the
# paths above are available to sway or anything it launches (kitty, swaylock,
# wpaperd...). systemd reads ~/.config/environment.d/ before starting the user
# session, so this is the correct place to set PATH for graphical sessions.

echo "==> Configuring PATH for graphical sessions via ~/.config/environment.d/..."
mkdir -p ~/.config/environment.d
cat > ~/.config/environment.d/10-sway-paths.conf << EOF
PATH=$HOME/.local/bin:$HOME/.cargo/bin:/snap/bin:/usr/local/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games
EOF

# ─── Config directories ───────────────────────────────────────────────────────

echo "==> Creating config directories..."
mkdir -p ~/.config/sway ~/.config/swaylock ~/.config/wpaperd ~/.config/wpaperd/wallpapers

echo ""
echo "✓ Installation complete!"
echo ""
echo "PATH additions have been written to ~/.profile."
echo "Run 'source ~/.profile' to apply them in your current shell,"
echo "or just log out and back in — they'll be picked up automatically."
echo ""
echo "Next steps:"
echo "  1. Run ./restore_configs.sh from this dotfiles repo to install configs"
echo "  2. Log out, select 'Sway' at the login screen, and log back in"
echo ""
echo "##############################################################################"
echo "##                                                                          ##"
echo "##  !!  WALLPAPER FILES ARE NOT IN THIS REPO  !!                            ##"
echo "##                                                                          ##"
echo "##  You MUST drop image files into the following locations or sway will     ##"
echo "##  start with a black screen / no lock background:                         ##"
echo "##                                                                          ##"
echo "##    ~/.config/swaylock/wallpaper.png                                      ##"
echo "##        Single image used as the lock screen background.                  ##"
echo "##        (Path is referenced in swaylock/config — change it there if you   ##"
echo "##        prefer a different filename or extension.)                        ##"
echo "##                                                                          ##"
echo "##    ~/.config/wpaperd/wallpapers/                                         ##"
echo "##        Directory containing one or more images. wpaperd will rotate      ##"
echo "##        through them on a 30m timer (see wpaperd/wallpapers.toml).        ##"
echo "##        wpaperd silently exits if this directory is empty.                ##"
echo "##                                                                          ##"
echo "##############################################################################"
