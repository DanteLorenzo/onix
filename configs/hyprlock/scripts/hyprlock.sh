#!/bin/bash

# Get screen dimensions using hyprctl
SCREEN_SIZE=$(hyprctl monitors -j | jq -r '.[0].width,.[0].height')
SCREEN_WIDTH=$(echo "$SCREEN_SIZE" | head -n1)
SCREEN_HEIGHT=$(echo "$SCREEN_SIZE" | tail -n1)

# Calculate blur box size (60% of the smallest dimension)
BLUR_SIZE=$(echo "scale=0; (($SCREEN_WIDTH < $SCREEN_HEIGHT ? $SCREEN_WIDTH : $SCREEN_HEIGHT) * 0.6)/1" | bc)

# Paths
HYPRPAPER_CONF="$HOME/.config/hyprpaper/tmp.conf"
HYPRLOCK_CONF="$HOME/.config/hypr/hyprlock.conf"
CACHE_DIR="$HOME/.cache/hyprlock_blur"
mkdir -p "$CACHE_DIR"

# Extract wallpaper path
WALLPAPER=$(grep -m1 '^wallpaper' "$HYPRPAPER_CONF" | awk -F',' '{print $NF}' | tr -d ' ')

# Generate cached blur path
WALLPAPER_HASH=$(md5sum "$WALLPAPER" | awk '{print $1}')
CACHED_BLUR="$CACHE_DIR/${WALLPAPER_HASH}_${SCREEN_WIDTH}x${SCREEN_HEIGHT}.png"

# Generate new blur if cached doesn't exist
if [ ! -f "$CACHED_BLUR" ]; then
    magick convert "$WALLPAPER" \
        -resize "${SCREEN_WIDTH}x${SCREEN_HEIGHT}^" \
        -gravity center \
        -extent "${SCREEN_WIDTH}x${SCREEN_HEIGHT}" \
        -resize 25% \
        -blur 0x8 \
        -resize 400% \
        -gravity center \
        -crop "${BLUR_SIZE}x${BLUR_SIZE}+0+0" +repage \
        -fill white -colorize 10% \
        "$CACHED_BLUR"
fi

# Update hyprlock config
sed -i "/background {/,/}/ {
    s|^\([[:space:]]*path[[:space:]]*=[[:space:]]*\).*|\1$WALLPAPER|;
    s|^\([[:space:]]*size[[:space:]]*=[[:space:]]*\).*|\1$BLUR_SIZE,$BLUR_SIZE|;
}" "$HYPRLOCK_CONF"

# Launch hyprlock
hyprlock -c "$HYPRLOCK_CONF"