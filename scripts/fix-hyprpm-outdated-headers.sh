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

# hyprpm uses sudo install internally and may recreate state.toml as root:root.
# Make the cache clean again so future updates/reloads can write state without surprises.
if [ -d "$CACHE_DIR" ]; then
  echo "🧹 Final ownership cleanup: $CACHE_DIR"
  sudo chown -R "$USER_NAME:$USER_NAME" "$CACHE_DIR"
  chmod -R u+rwX "$CACHE_DIR"
fi

echo "🔁 Final reload check..."
hyprpm reload
hyprctl reload

echo ""
echo "✅ Done. Verify with:"
echo "  hyprpm list"
echo "  find /var/cache/hyprpm/$USER_NAME -maxdepth 2 -name state.toml -printf '%u:%g %p\\n'"
