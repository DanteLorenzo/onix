#!/bin/bash

# Include logging functions
source "$(dirname "$0")/../utils/logging.sh"

log_info "Configuring GNOME terminal opacity for Ptyxis..."

if [ $? -eq 0 ]; then

  # Copy config folders to ~/.config, overwriting if they exist
  for folder in tmux; do
    src_dir="$(dirname "$0")/../configs/$folder"
    dest_dir="$HOME/.config/$folder"
    rm -rf "$dest_dir"
    cp -r "$src_dir" "$HOME/.config/"
    log_info "Copied $folder config to ~/.config/"
  done

else
  log_error "Configs copy failed."
fi