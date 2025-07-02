#!/bin/bash

# Directory containing wallpapers
WALLPAPERS_DIR="$HOME/Pictures/Wallpapers"
# Create directory if it doesn't exist
mkdir -p "$WALLPAPERS_DIR"

# Find all image files (jpg/png/jpeg) in the directory
WALLPAPERS=($(find "$WALLPAPERS_DIR" -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.jpeg" \)))

# Exit if no wallpapers are found
if [ ${#WALLPAPERS[@]} -eq 0 ]; then
    echo "❌ Error: No wallpapers found in $WALLPAPERS_DIR"
    exit 1
fi

# Select a random wallpaper (fixed the array indexing syntax)
RANDOM_WALLPAPER="${WALLPAPERS[$RANDOM % ${#WALLPAPERS[@]}]}"

# Generate a temporary hyprpaper config
CONFIG_FILE="$HOME/.config/hyprpaper/hyprpaper_rand.conf"
echo "preload = $RANDOM_WALLPAPER" > "$CONFIG_FILE"
echo "wallpaper = ,$RANDOM_WALLPAPER" >> "$CONFIG_FILE"
echo "ipc = true" >> "$CONFIG_FILE"
echo "splash = true" >> "$CONFIG_FILE"


# Restart hyprpaper to apply changes
pkill hyprpaper
hyprpaper -c "$CONFIG_FILE" &