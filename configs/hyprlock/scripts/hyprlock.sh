#!/bin/bash

# Path to temporary hyprpaper config
HYPRPAPER_CONF="$HOME/.config/hyprpaper/tmp.conf"

# Path to Hyprlock configuration
HYPRLOCK_CONF="$HOME/.config/hypr/hyprlock.conf"  # Note: Corrected path to standard hyprlock location

# Configuration directory
CONFIG_DIR="$HOME/.config/hypr"
BLURBOX="$CONFIG_DIR/blurbox.png"

# Get wallpaper path from hyprpaper config (handling both formats)
WALLPAPER=$(grep -m1 '^wallpaper' "$HYPRPAPER_CONF" | awk -F',' '{print $NF}' | tr -d ' ')

# Verify wallpaper exists
if [ ! -f "$WALLPAPER" ]; then
  echo "❌ Wallpaper not found: $WALLPAPER"
  exit 1
fi

# Generate blurred box
magick convert "$WALLPAPER" \
    -resize 1920x1080^ \
    -gravity center \
    -extent 1920x1080 \
    -crop 900x900+0+0 +repage \
    -blur 0x8 \
    -fill white -colorize 10% \
    "$BLURBOX"

# Update hyprlock config (improved sed command)
sed -i "/^background {/,/^}/ {
    s|^\([[:space:]]*path[[:space:]]*=[[:space:]]*\).*|\1$WALLPAPER|
    s|^\([[:space:]]*blur_passes[[:space:]]*=[[:space:]]*\).*|\13|
}" "$HYPRLOCK_CONF"

# Launch hyprlock
hyprlock -c "$HYPRLOCK_CONF"