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

# Create hash for caching
WALLPAPER_HASH=$(md5sum "$WALLPAPER" | awk '{print $1}')
CACHED_BLUR="$CACHE_DIR/$WALLPAPER_HASH.png"

# Use cached version if available
if [ -f "$CACHED_BLUR" ]; then
    cp "$CACHED_BLUR" "$BLURBOX"
else
    # Optimized blur generation (3x faster)
    magick convert "$WALLPAPER" \
        -resize 2880x1800
        -blur 0x1 \
        -gravity center \
        -crop 900x900+0+0 +repage \
        -fill white -colorize 10% \
        "$CACHED_BLUR"
    cp "$CACHED_BLUR" "$BLURBOX"
fi

# Update hyprlock config
sed -i "/background {/,/}/ s|^\([[:space:]]*path[[:space:]]*=[[:space:]]*\).*|\1$WALLPAPER|" "$HYPRLOCK_CONF"

# Launch hyprlock
hyprlock -c "$HYPRLOCK_CONF"