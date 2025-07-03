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

# Get wallpaper dimensions
WALLPAPER_DIM=$(magick identify -format "%wx%h" "$WALLPAPER")
WALLPAPER_WIDTH=${WALLPAPER_DIM%x*}
WALLPAPER_HEIGHT=${WALLPAPER_DIM#*x}

# Calculate center position for 900x900 crop
CROP_X=$(( (WALLPAPER_WIDTH - 900) / 2 ))
CROP_Y=$(( (WALLPAPER_HEIGHT - 900) / 2 ))

# Ensure crop coordinates are not negative
CROP_X=$(( CROP_X > 0 ? CROP_X : 0 ))
CROP_Y=$(( CROP_Y > 0 ? CROP_Y : 0 ))

# Create hash for caching
WALLPAPER_HASH=$(md5sum "$WALLPAPER" | awk '{print $1}')
CACHED_BLUR="$CACHE_DIR/${WALLPAPER_HASH}_900x900.png"

# Use cached version if available
if [ -f "$CACHED_BLUR" ]; then
    cp "$CACHED_BLUR" "$BLURBOX"
else
    # Generate the exact 900x900 crop from the center, then apply blur
    magick convert "$WALLPAPER" \
        -gravity center \
        -crop 900x900+0+0 +repage \
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