#!/bin/bash

TMP=/tmp
AGS_TMP="$TMP/ags-${USER}"
SRC=$HOME/.config/fahmi/hypr/scripts-c
CONFIG_DIR=$HOME/.config
USER=$(whoami)

mkdir -p "$TMP"
mkdir -p "$AGS_TMP"

gcc "$SRC/battery-check.c"   -o "$TMP/battery-check"
gcc "$SRC/updates-check.c"   -o "$TMP/updates-check"
gcc "$SRC/wallpaper-loop.c"  -o "$TMP/wallpaper-loop"

ags bundle "$HOME/.config/fahmi/ags/app.tsx" "$AGS_TMP/ags-bin"

# Run in background after kill any existing loop
pkill -f "wallpaper-loop" 2>/dev/null

"$TMP/wallpaper-loop" &
"$AGS_TMP/ags-bin" &

# Run immediately once
/tmp/battery-check &
/tmp/updates-check &

# Schedule checks with systemd user timers instead of cron/cronie.
# This avoids the recurring "Cron jobs will not execute" warning and does not need sudo.
SYSTEMD_USER_DIR="$HOME/.config/systemd/user"
mkdir -p "$SYSTEMD_USER_DIR"

cat > "$SYSTEMD_USER_DIR/fahmi-battery-check.service" <<SERVICE
[Unit]
Description=Fahmi battery notification check

[Service]
Type=oneshot
Environment=XDG_RUNTIME_DIR=/run/user/$(id -u)
ExecStart=$TMP/battery-check
SERVICE

cat > "$SYSTEMD_USER_DIR/fahmi-battery-check.timer" <<TIMER
[Unit]
Description=Run Fahmi battery check every 5 minutes

[Timer]
OnBootSec=2min
OnUnitActiveSec=5min
Unit=fahmi-battery-check.service

[Install]
WantedBy=timers.target
TIMER

cat > "$SYSTEMD_USER_DIR/fahmi-updates-check.service" <<SERVICE
[Unit]
Description=Fahmi updates notification check

[Service]
Type=oneshot
Environment=XDG_RUNTIME_DIR=/run/user/$(id -u)
ExecStart=$TMP/updates-check
SERVICE

cat > "$SYSTEMD_USER_DIR/fahmi-updates-check.timer" <<TIMER
[Unit]
Description=Run Fahmi updates check every 6 hours

[Timer]
OnBootSec=10min
OnUnitActiveSec=6h
Unit=fahmi-updates-check.service

[Install]
WantedBy=timers.target
TIMER

systemctl --user daemon-reload
systemctl --user enable --now fahmi-battery-check.timer fahmi-updates-check.timer >/dev/null 2>&1 || \
    notify-send "Error" "Failed to enable Fahmi systemd user timers"

