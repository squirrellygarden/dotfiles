#!/bin/sh

set -e

DOTFILES="$(cd "$(dirname "$0")" && pwd)"

echo "Restoring git files..."
cp "$DOTFILES/git/.gitignore" ~/.gitignore
cp "$DOTFILES/git/.gitconfig" ~/.gitconfig

if command -v hyprland > /dev/null 2>&1; then
    echo "Restoring hypr..."
    mkdir -p ~/.config/hypr
    cp -r "$DOTFILES/hypr/hypr/." ~/.config/hypr/
else
    echo "Hyprland not found, skipping hypr."
fi

echo "Restoring kitty..."
mkdir -p ~/.config/kitty
cp "$DOTFILES/kitty/kitty.conf" ~/.config/kitty/kitty.conf

echo "Restoring nvim..."
mkdir -p ~/.config/nvim
cp -r "$DOTFILES/nvim/." ~/.config/nvim/

echo "Restoring rofi..."
mkdir -p ~/.config/rofi
cp -r "$DOTFILES/rofi/." ~/.config/rofi/

if command -v sway > /dev/null 2>&1; then
    echo "Restoring sway..."
    mkdir -p ~/.config/sway
    cp "$DOTFILES/sway/config" ~/.config/sway/config
    cp -r "$DOTFILES/sway/scripts" ~/.config/sway/
else
    echo "Sway not found, skipping sway."
fi

if command -v swaylock > /dev/null 2>&1; then
    echo "Restoring swaylock..."
    mkdir -p ~/.config/swaylock
    cp "$DOTFILES/swaylock/config" ~/.config/swaylock/config
else
    echo "Swaylock not found, skipping swaylock."
fi

if command -v wpaperd > /dev/null 2>&1 || [ -x "$HOME/.cargo/bin/wpaperd" ]; then
    echo "Restoring wpaperd..."
    mkdir -p ~/.config/wpaperd ~/.config/wpaperd/wallpapers
    cp "$DOTFILES/wpaperd/wallpapers.toml" ~/.config/wpaperd/wallpapers.toml
else
    echo "wpaperd not found, skipping wpaperd."
fi

echo "Restoring waybar..."
mkdir -p ~/.config/waybar
if command -v hyprland > /dev/null 2>&1; then
    echo "  Hyprland detected, using hypr waybar config."
    cp "$DOTFILES/waybar/config.hypr.jsonc" ~/.config/waybar/config.jsonc
elif ls /sys/class/power_supply/BAT* > /dev/null 2>&1; then
    echo "  Battery detected, using laptop waybar config."
    cp "$DOTFILES/waybar/config.laptop.jsonc" ~/.config/waybar/config.jsonc
else
    echo "  Using sway desktop waybar config."
    cp "$DOTFILES/waybar/config.swaydesk.jsonc" ~/.config/waybar/config.jsonc
fi
cp "$DOTFILES/waybar/mocha.css" ~/.config/waybar/mocha.css
cp "$DOTFILES/waybar/style.css" ~/.config/waybar/style.css
cp -r "$DOTFILES/waybar/scripts" ~/.config/waybar/scripts

echo "Restoring yazi..."
mkdir -p ~/.config/yazi
cp -r "$DOTFILES/yazi/." ~/.config/yazi/

echo "Restoring htop..."
mkdir -p ~/.config/htop
cp "$DOTFILES/htop/htoprc" ~/.config/htop/htoprc

echo "Restoring GTK theme..."
mkdir -p ~/.local/share/themes ~/.config/gtk-3.0 ~/.config/gtk-4.0
cp -r "$DOTFILES/gtk/catppuccin-mocha-mauve-standard" ~/.local/share/themes/
cp -r "$DOTFILES/gtk-3.0/." ~/.config/gtk-3.0/
cp -r "$DOTFILES/gtk-4.0/." ~/.config/gtk-4.0/

echo "Restoring krita color schemes..."
mkdir -p ~/.local/share/krita/color-schemes
cp -r "$DOTFILES/krita/color-schemes/." ~/.local/share/krita/color-schemes/

# Reload running services so config changes take effect immediately.
# Each block is a no-op if the service isn't running.
if swaymsg -t get_version > /dev/null 2>&1; then
    echo "Reloading sway..."
    swaymsg reload > /dev/null

    if pgrep -x swayidle > /dev/null 2>&1; then
        echo "Restarting swayidle..."
        pkill -x swayidle || true
        # Brief pause so the old process releases the inhibitor lock before the new one claims it.
        sleep 1
        swaymsg exec ~/.config/sway/scripts/swayidle.sh > /dev/null
    fi

    if pgrep -x waybar > /dev/null 2>&1; then
        echo "Restarting waybar..."
        pkill -x waybar || true
        swaymsg exec waybar > /dev/null
    fi
fi

echo "Done."