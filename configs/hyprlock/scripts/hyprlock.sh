#!/bin/bash

# Paths
HYPRPAPER_CONF="$HOME/.config/hyprpaper/tmp.conf"   # Hyprpaper config (source of wallpaper)
HYPRLOCK_CONF="$HOME/.config/hyprlock/hyprlock.conf"    # Hyprlock config (destination to modify)

# Configuration directory
CONFIG_DIR="$HOME/.config/hyprlock"
BLURBOX="$CONFIG_DIR/blurbox.png"

# Extract wallpaper path from hyprpaper.conf
WALLPAPER=$(grep -m1 '^wallpaper' "$HYPRPAPER_CONF" | awk -F',' '{print $NF}' | tr -d ' ')

# Check if wallpaper exists
if [ ! -f "$WALLPAPER" ]; then
  echo "❌ Error: Wallpaper not found: $WALLPAPER"
  exit 1
fi

# Update hyprlock.conf to use the new wallpaper path
sed -i "/background {/,/}/ s|^\([[:space:]]*path[[:space:]]*=[[:space:]]*\).*|\1$WALLPAPER|" "$HYPRLOCK_CONF"

# Generate blurred box
magick convert "$WALLPAPER" \
    -resize 1920x1080^ \
    -gravity center \
    -extent 1920x1080 \
    -crop 900x900+0+0 +repage \
    -blur 0x8 \
    -fill white -colorize 10% \
    "$BLURBOX"



# Launch hyprlock
hyprlock -c "$HYPRLOCK_CONF"