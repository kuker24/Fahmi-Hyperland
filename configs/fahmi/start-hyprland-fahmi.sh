#!/bin/bash
# Launcher for Fahmi (ArchEclipse) Hyprland profile
# Uses a separate config directory from the main Hyprland setup.

# Use start-hyprland wrapper with custom config path
# Arguments after -- are passed to Hyprland
exec start-hyprland -- --config "$HOME/.config/fahmi/hypr/hyprland.lua"
