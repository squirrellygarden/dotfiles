#!/usr/bin/env bash
# Start swww-daemon and rotate through ~/.config/wallpapers every 30m.
# Picks a random image each cycle; exits quietly if the directory is empty.

set -u

WALLPAPER_DIR="${WALLPAPER_DIR:-$HOME/.config/wallpapers}"
INTERVAL="${WALLPAPER_INTERVAL:-1800}"

if ! command -v swww-daemon >/dev/null 2>&1; then
    exit 0
fi

if ! pgrep -x swww-daemon >/dev/null 2>&1; then
    swww-daemon &
    # Give the daemon a moment to create its socket before the first `swww img`.
    sleep 1
fi

while true; do
    mapfile -d '' -t images < <(find "$WALLPAPER_DIR" -maxdepth 1 -type f \
        \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) -print0 2>/dev/null)

    if [ "${#images[@]}" -eq 0 ]; then
        sleep "$INTERVAL"
        continue
    fi

    pick="${images[RANDOM % ${#images[@]}]}"
    swww img "$pick" --transition-type fade --transition-duration 1 >/dev/null 2>&1 || true
    sleep "$INTERVAL"
done
