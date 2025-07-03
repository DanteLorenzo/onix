#!/bin/bash

# Paths
HYPRPAPER_CONF="$HOME/.config/hyprpaper/tmp.conf"
HYPRLOCK_CONF="$HOME/.config/hyprlock/hyprlock.conf"
CONFIG_DIR="$HOME/.config/hyprlock"
BLURBOX="$CONFIG_DIR/blurbox.png"
CACHE_DIR="$HOME/.cache/hyprlock_blur"
AVATAR_DIR="$HOME/Pictures/Avatars"

# Create cache directory if it doesn't exist
mkdir -p "$CACHE_DIR"

# Extract wallpaper path
WALLPAPER=$(grep -m1 '^wallpaper' "$HYPRPAPER_CONF" | awk -F',' '{print $NF}' | tr -d ' ')

# Check if wallpaper exists
if [ ! -f "$WALLPAPER" ]; then
  echo "❌ Error: Wallpaper not found: $WALLPAPER"
  exit 1
fi

# Generate blurred wallpaper box
WALLPAPER_HASH=$(md5sum "$WALLPAPER" | awk '{print $1}')
CACHED_BLUR="$CACHE_DIR/${WALLPAPER_HASH}_900x900.png"

if [ -f "$CACHED_BLUR" ]; then
    cp "$CACHED_BLUR" "$BLURBOX"
else
    magick convert "$WALLPAPER" \
        -gravity center \
        -crop 900x900+0+0 +repage \
        -resize 25% \
        -blur 0x9 \
        -resize 400% \
        -fill white -colorize 10% \
        "$CACHED_BLUR"
    cp "$CACHED_BLUR" "$BLURBOX"
fi

# Update wallpaper path in hyprlock config
sed -i "/^background {/,/}/ s|^\([[:space:]]*path[[:space:]]*=[[:space:]]*\).*|\1$WALLPAPER|" "$HYPRLOCK_CONF"

# Update avatar image if directory exists
if [ -d "$AVATAR_DIR" ]; then
    shopt -s nullglob
    AVATAR_FILES=("$AVATAR_DIR"/*.{png,jpg,jpeg,PNG,JPG,JPEG})
    shopt -u nullglob
    
    if [ ${#AVATAR_FILES[@]} -gt 0 ]; then
        RANDOM_AVATAR="${AVATAR_FILES[RANDOM % ${#AVATAR_FILES[@]}]}"
        # More precise matching for avatar section
        sed -i "/^image {/,/}/ {
            /size = 200/ {
                n
                s|^\([[:space:]]*path[[:space:]]*=[[:space:]]*\).*|\1$RANDOM_AVATAR|
            }
        }" "$HYPRLOCK_CONF"
    else
        echo "⚠ Warning: No avatar files found in $AVATAR_DIR"
    fi
else
    echo "⚠ Warning: Avatar directory not found: $AVATAR_DIR"
fi

# Launch hyprlock
hyprlock -c "$HYPRLOCK_CONF"