#!/usr/bin/env bash
# Stabilize sudo auth on Arch/CachyOS.
# Fixes common "correct password but sudo rejects" causes:
# - stale pam_faillock lockouts
# - too aggressive faillock timing
# - dangerous numpad remaps that change password digits

set -euo pipefail

TARGET_USER="${SUDO_USER:-$USER}"
HOME_DIR="$(getent passwd "$TARGET_USER" | cut -d: -f6)"

if [ "$(id -u)" -ne 0 ]; then
  echo "🔐 Need root. Run: sudo $0"
  exit 1
fi

echo "🔧 Stabilizing sudo auth for: $TARGET_USER"

# 1) Reset faillock counters for the user.
if command -v faillock >/dev/null 2>&1; then
  echo "🧹 Resetting faillock for $TARGET_USER"
  faillock --user "$TARGET_USER" --reset || true
fi

# 2) Make faillock less annoying but still secure.
# Arch defaults are deny=3, fail_interval=900, unlock_time=600.
# This keeps protection but prevents long false lockouts.
CONF="/etc/security/faillock.conf"
if [ -f "$CONF" ]; then
  BACKUP="$CONF.bak.$(date +%Y%m%d-%H%M%S)"
  cp -a "$CONF" "$BACKUP"
  echo "💾 Backup: $BACKUP"

  set_key() {
    local key="$1" value="$2"
    if grep -Eq "^[#[:space:]]*$key[[:space:]]*=" "$CONF"; then
      sed -i -E "s|^[#[:space:]]*$key[[:space:]]*=.*|$key = $value|" "$CONF"
    else
      printf '\n%s = %s\n' "$key" "$value" >> "$CONF"
    fi
  }

  set_flag() {
    local key="$1"
    if grep -Eq "^[#[:space:]]*$key([[:space:]]*)$" "$CONF"; then
      sed -i -E "s|^[#[:space:]]*$key([[:space:]]*)$|$key|" "$CONF"
    elif ! grep -Eq "^[[:space:]]*$key([[:space:]]*)$" "$CONF"; then
      printf '\n%s\n' "$key" >> "$CONF"
    fi
  }

  set_key deny 5
  set_key fail_interval 300
  set_key unlock_time 60
  set_flag local_users_only
fi

# 3) Remove dangerous numpad remaps from ArchEclipse/Fahmi configs.
for f in \
  "$HOME_DIR/.config/fahmi/hypr/evremap/remap.toml" \
  "$HOME_DIR/.config/hypr/evremap/remap.toml"; do
  if [ -f "$f" ]; then
    echo "⌨️  Writing safe evremap config: $f"
    cat > "$f" <<'EOF'
device_name = "AT Translated Set 2 keyboard"

# Keep only safe non-password-affecting remap.
# Removed numpad remaps because they can make sudo/login passwords appear "wrong"
# when typing digits from the numpad.
[[remap]]
input = ["KEY_RIGHTALT"]
output = ["KEY_F11"]
EOF
    chown "$TARGET_USER:$TARGET_USER" "$f"
  fi
done

echo ""
echo "✅ sudo auth stability fix complete."
echo "Verify: faillock --user $TARGET_USER"
