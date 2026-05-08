#!/bin/bash

WALLPAPER_DIR="$HOME/.config/hypr/wallpapers"

# Wallpapers for DP-3
DP3_WALLPAPERS=(
    "$WALLPAPER_DIR/circles.png"
    "$WALLPAPER_DIR/summer.png"
)

# Wallpapers for HDMI-A-1
HDMI_WALLPAPERS=(
    "$WALLPAPER_DIR/summer2.jpg"
    "$WALLPAPER_DIR/nice_view.png"
)

# Index trackers
DP3_INDEX=0
HDMI_INDEX=0

while true; do
    # Set wallpaper for DP-3
    hyprctl hyprpaper wallpaper "DP-3,${DP3_WALLPAPERS[$DP3_INDEX]}"
    
    # Set wallpaper for HDMI-A-1
    hyprctl hyprpaper wallpaper "HDMI-A-1,${HDMI_WALLPAPERS[$HDMI_INDEX]}"
    
    # Increment indices and wrap around
    DP3_INDEX=$(( (DP3_INDEX + 1) % ${#DP3_WALLPAPERS[@]} ))
    HDMI_INDEX=$(( (HDMI_INDEX + 1) % ${#HDMI_WALLPAPERS[@]} ))
    
    # Wait 10 minutes
    sleep 600
done
