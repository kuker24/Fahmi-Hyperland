#!/usr/bin/env bash
# Fix Hyprland hyprpm: "Failed to load plugins: Outdated headers"
# Root cause commonly found on CachyOS/Arch: /var/cache/hyprpm/$USER is root-owned,
# so hyprpm can install headers but cannot write state.toml with the new ABI hash.

set -euo pipefail

USER_NAME="${SUDO_USER:-$USER}"
CACHE_DIR="/var/cache/hyprpm/$USER_NAME"

echo "🔧 Fixing hyprpm outdated headers for user: $USER_NAME"

if ! command -v hyprpm >/dev/null 2>&1; then
  echo "❌ hyprpm not found. Install/update Hyprland first."
  exit 1
fi

if [ -d "$CACHE_DIR" ]; then
  echo "📁 Fixing ownership: $CACHE_DIR"
  sudo chown -R "$USER_NAME:$USER_NAME" "$CACHE_DIR"
  chmod -R u+rwX "$CACHE_DIR"
else
  echo "📁 Cache dir not found yet, hyprpm will create it: $CACHE_DIR"
fi

echo "🔄 Updating hyprpm headers..."
hyprpm update

echo "🔌 Reloading hyprpm plugins..."
hyprpm reload || true

echo ""
echo "✅ Done. Verify with:"
echo "  hyprpm list"
echo "  hyprctl reload"
