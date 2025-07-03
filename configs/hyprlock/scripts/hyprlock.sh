#!/bin/bash

# Paths
HYPRPAPER_CONF="$HOME/.config/hyprpaper/tmp.conf"
HYPRLOCK_CONF="$HOME/.config/hyprlock/hyprlock.conf"
CONFIG_DIR="$HOME/.config/hyprlock"
BLURBOX="$CONFIG_DIR/blurbox.png"
CACHE_DIR="$HOME/.cache/hyprlock_blur"

# Create cache directory if it doesn't exist
mkdir -p "$CACHE_DIR"

# Extract wallpaper path
WALLPAPER=$(grep -m1 '^wallpaper' "$HYPRPAPER_CONF" | awk -F',' '{print $NF}' | tr -d ' ')

# Check if wallpaper exists
if [ ! -f "$WALLPAPER" ]; then
  echo "❌ Error: Wallpaper not found: $WALLPAPER"
  exit 1
fi

# Get screen resolution (assuming single monitor for simplicity)
SCREEN_RES=$(hyprctl monitors | grep -oP '\d+x\d+' | head -n1)
SCREEN_WIDTH=$(echo $SCREEN_RES | cut -d'x' -f1)
SCREEN_HEIGHT=$(echo $SCREEN_RES | cut -d'x' -f2)

# Calculate center position for 900x900 crop
CROP_X=$(( (SCREEN_WIDTH - 900) / 2 ))
CROP_Y=$(( (SCREEN_HEIGHT - 900) / 2 ))

# Create hash for caching (now includes screen resolution in hash)
WALLPAPER_HASH=$(echo "$(md5sum "$WALLPAPER")_${SCREEN_RES}_900x900" | md5sum | awk '{print $1}')
CACHED_BLUR="$CACHE_DIR/$WALLPAPER_HASH.png"

# Use cached version if available
if [ -f "$CACHED_BLUR" ]; then
    cp "$CACHED_BLUR" "$BLURBOX"
else
    # Generate the exact 900x900 crop from the center, then apply blur
    magick convert "$WALLPAPER" \
        -crop 900x900+${CROP_X}+${CROP_Y} +repage \
        -resize 25% \
        -blur 0x8 \
        -resize 400% \
        -fill white -colorize 10% \
        "$CACHED_BLUR"
    cp "$CACHED_BLUR" "$BLURBOX"
fi

# Update hyprlock config
sed -i "/background {/,/}/ s|^\([[:space:]]*path[[:space:]]*=[[:space:]]*\).*|\1$WALLPAPER|" "$HYPRLOCK_CONF"

# Launch hyprlock
hyprlock -c "$HYPRLOCK_CONF"