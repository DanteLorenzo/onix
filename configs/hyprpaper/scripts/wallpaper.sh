#!/bin/bash
DIR="$HOME/Pictures/Wallpapers"
while true; do
  WALLPAPER=$(find "$DIR" -type f | shuf -n 1)
  hyprctl hyprpaper preload "$WALLPAPER"
  hyprctl hyprpaper wallpaper "DP-1,$WALLPAPER"  # Update for each monitor
  sleep 30  # Change every 5 minutes
done