#!/bin/bash

# This script is called when the workspace changes
# It applies the wallpaper for the new workspace

monitor="eDP-1"
workspace_id="$1"

if [ -z "$workspace_id" ]; then
    # Get current workspace
    workspace_id=$(hyprctl monitors -j | jq -r '.[0].activeWorkspace.id')
fi

config_file="$HOME/.config/fahmi/hypr/wallpaper-daemon/config/$monitor/defaults.conf"

if [ ! -f "$config_file" ]; then
    echo "Config file not found: $config_file"
    exit 1
fi

wallpaper=$(grep "^w-${workspace_id}=" "$config_file" | cut -d'=' -f2- | head -n 1)

if [ -n "$wallpaper" ] && [ -f "$wallpaper" ]; then
    hyprctl hyprpaper wallpaper "$monitor,$wallpaper"
    echo "Applied wallpaper for workspace $workspace_id: $(basename "$wallpaper")"
else
    echo "No wallpaper found for workspace $workspace_id"
fi
