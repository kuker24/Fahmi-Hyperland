#!/bin/bash
# ============================================
# Fahmi Hyperland - Auto Setup Script
# Run this on a fresh Arch/CachyOS system
# ============================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$SCRIPT_DIR/configs"
ARCH_ECLIPSE_DIR="$SCRIPT_DIR/ArchEclipse"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

# ============================================
# STEP 1: Install Dependencies
# ============================================
install_dependencies() {
    print_status "Installing dependencies..."
    
    # Check if yay is installed
    if ! command -v yay &> /dev/null; then
        print_warning "yay not found. Installing..."
        sudo pacman -S --needed git base-devel
        git clone https://aur.archlinux.org/yay.git /tmp/yay
        cd /tmp/yay && makepkg -si --noconfirm
        cd "$SCRIPT_DIR"
    fi
    
    # Install packages
    print_status "Installing packages with yay..."
    yay -S --needed --noconfirm \
        hyprland hyprpaper hypridle hyprlock hyprpicker hyprpolkitagent \
        aylurs-gtk-shell-git \
        kitty fastfetch starship \
        nautilus \
        brave-bin \
        imagemagick ffmpeg grim slurp wl-clipboard \
        brightnessctl wireplumber pipewire pipewire-pulse \
        networkmanager nm-applet blueman blueman-applet \
        phinger-cursors whitesur-gtk-theme whitesur-icon-theme kvantum \
        python-pywal \
        gcc base-devel jq git
    
    print_status "Dependencies installed!"
}

# ============================================
# STEP 2: Setup ArchEclipse
# ============================================
setup_archeclipse() {
    print_status "Setting up ArchEclipse..."
    
    # Clone ArchEclipse to home directory
    if [ ! -d "$HOME/ArchEclipse" ]; then
        print_status "Cloning ArchEclipse..."
        git clone https://github.com/AymanLyesri/ArchEclipse.git "$HOME/ArchEclipse"
    else
        print_warning "ArchEclipse already exists, skipping clone..."
    fi
    
    # Create symlinks
    print_status "Creating symlinks..."
    ln -sf "$HOME/ArchEclipse/.config/ags" "$HOME/.config/ags"
    ln -sf "$HOME/ArchEclipse/.config/hypr" "$HOME/.config/hypr"
    
    print_status "ArchEclipse setup complete!"
}

# ============================================
# STEP 3: Copy Modified Configs
# ============================================
copy_configs() {
    print_status "Copying modified configs..."
    
    # Create fahmi config directory
    mkdir -p "$HOME/.config/fahmi"
    
    # Copy Hyprland configs
    print_status "Copying Hyprland configs..."
    rsync -av "$CONFIG_DIR/hypr/" "$HOME/.config/fahmi/hypr/"
    
    # Copy AGS configs (our modifications)
    print_status "Copying AGS configs..."
    rsync -av "$CONFIG_DIR/ags/" "$HOME/ArchEclipse/.config/ags/"
    
    # Copy AGS settings
    print_status "Copying AGS settings..."
    mkdir -p "$HOME/.config/ags/cache/settings"
    cp "$CONFIG_DIR/ags-settings/settings.json" "$HOME/.config/ags/cache/settings/"
    
    # Copy hypridle.conf
    print_status "Copying hypridle.conf..."
    cp "$CONFIG_DIR/hypridle.conf" "$HOME/.config/hypr/"
    
    # Copy start script
    print_status "Copying start script..."
    mkdir -p "$HOME/.config/fahmi"
    cp "$CONFIG_DIR/fahmi/start-hyprland-fahmi.sh" "$HOME/.config/fahmi/"
    chmod +x "$HOME/.config/fahmi/start-hyprland-fahmi.sh"
    
    print_status "Configs copied!"
}

# ============================================
# STEP 4: Setup Wallpapers
# ============================================
setup_wallpapers() {
    print_status "Setting up wallpapers..."
    
    # Create wallpapers directory
    mkdir -p "$HOME/.config/wallpapers"
    
    # Copy wallpapers
    rsync -av "$CONFIG_DIR/wallpapers/" "$HOME/.config/wallpapers/"
    
    # Copy wallpaper daemon config
    mkdir -p "$HOME/.config/fahmi/hypr/wallpaper-daemon/config/eDP-1"
    cp "$CONFIG_DIR/hypr/wallpaper-daemon/config/eDP-1/defaults.conf" \
       "$HOME/.config/fahmi/hypr/wallpaper-daemon/config/eDP-1/"
    cp "$CONFIG_DIR/hypr/wallpaper-daemon/config/eDP-1/defaults.conf" \
       "$HOME/.config/hypr/wallpaper-daemon/config/eDP-1/"
    
    print_status "Wallpapers setup complete!"
}

# ============================================
# STEP 5: Compile and Setup Services
# ============================================
setup_services() {
    print_status "Setting up services..."
    
    # Enable systemd services
    systemctl --user enable hyprpaper
    systemctl --user enable hypridle
    systemctl --user enable hyprpolkitagent
    
    # Compile C binaries
    print_status "Compiling C binaries..."
    SRC="$HOME/.config/fahmi/hypr/scripts-c"
    TMP="/tmp"
    
    gcc "$SRC/battery-check.c" -o "$TMP/battery-check"
    gcc "$SRC/updates-check.c" -o "$TMP/updates-check"
    gcc "$SRC/wallpaper-loop.c" -o "$TMP/wallpaper-loop"
    
    # Bundle AGS
    print_status "Bundling AGS..."
    AGS_TMP="$TMP/ags-$(whoami)"
    mkdir -p "$AGS_TMP"
    ags bundle "$HOME/.config/fahmi/ags/app.tsx" "$AGS_TMP/ags-bin"
    
    print_status "Services setup complete!"
}

# ============================================
# STEP 6: Setup Theme
# ============================================
setup_theme() {
    print_status "Setting up theme..."
    
    # Apply theme
    bash "$HOME/.config/fahmi/hypr/theme/scripts/system-theme.sh" apply
    
    print_status "Theme applied!"
}

# ============================================
# MAIN
# ============================================
main() {
    echo "============================================"
    echo "  Fahmi Hyperland - Auto Setup"
    echo "============================================"
    echo ""
    
    # Check if running as root
    if [ "$EUID" -eq 0 ]; then
        print_error "Don't run this script as root!"
        exit 1
    fi
    
    # Ask for confirmation
    read -p "This will install and configure Fahmi Hyperland. Continue? (y/N): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_warning "Setup cancelled."
        exit 0
    fi
    
    # Run setup steps
    install_dependencies
    setup_archeclipse
    copy_configs
    setup_wallpapers
    setup_services
    setup_theme
    
    echo ""
    echo "============================================"
    print_status "Setup complete!"
    echo "============================================"
    echo ""
    echo "Next steps:"
    echo "1. Log out and log back in"
    echo "2. Select 'Hyprland' as your session"
    echo "3. Enjoy your new desktop!"
    echo ""
    echo "Keybinds:"
    echo "  Super + W        - Wallpaper switcher"
    echo "  Super + Shift + P - Screenshot"
    echo "  Super + Return   - Terminal"
    echo "  Super + I        - Browser"
    echo "  Super + Space    - Float toggle"
    echo ""
}

main "$@"

# ╔══════════════════════════════════════════════════════════════╗
# ║  FIX: KDE/Dolphin File Associations (CachyOS specific)       ║
# ╚══════════════════════════════════════════════════════════════╝
echo ""
echo "🔧 Fixing KDE file associations..."

# Fix missing applications.menu symlink
if [ ! -f /etc/xdg/menus/applications.menu ]; then
    echo "⚠️  Creating applications.menu symlink..."
    sudo ln -sf /etc/xdg/menus/plasma-applications.menu /etc/xdg/menus/applications.menu
fi

# Clean old state
rm -f ~/.local/state/keditfiletypestaterc
rm -f ~/.config/filetypesrc

# Create custom desktop files
mkdir -p ~/.local/share/applications

cat > ~/.local/share/applications/imv-custom.desktop << 'DESKTOP'
[Desktop Entry]
Type=Application
Name=imv Image Viewer
GenericName=Image Viewer
Comment=View images
Exec=imv %F
Icon=image-viewer
Terminal=false
Categories=Graphics;Viewer;
MimeType=image/jpeg;image/png;image/gif;image/webp;image/bmp;image/tiff;image/svg+xml;image/heif;image/avif;image/jxl;
DESKTOP

cat > ~/.local/share/applications/mpv-custom.desktop << 'DESKTOP'
[Desktop Entry]
Type=Application
Name=mpv Media Player
GenericName=Media Player
Comment=Play videos and audio
Exec=mpv %F
Icon=mpv
Terminal=false
Categories=AudioVideo;Player;Video;Audio;
MimeType=video/mp4;video/x-matroska;video/webm;video/avi;video/x-msvideo;video/quicktime;video/x-flv;video/mpeg;video/ogg;video/3gpp;audio/mpeg;audio/mp3;audio/ogg;audio/wav;audio/flac;audio/aac;
DESKTOP

cat > ~/.local/share/applications/firefox-pdf.desktop << 'DESKTOP'
[Desktop Entry]
Type=Application
Name=Firefox PDF Viewer
GenericName=PDF Viewer
Comment=View PDF files with Firefox
Exec=firefox %F
Icon=firefox
Terminal=false
Categories=Office;Viewer;
MimeType=application/pdf;
DESKTOP

cat > ~/.local/share/applications/vim-editor.desktop << 'DESKTOP'
[Desktop Entry]
Type=Application
Name=Vim Text Editor
GenericName=Text Editor
Comment=Edit text files with vim
Exec=kitty vim %F
Icon=gvim
Terminal=false
Categories=Development;TextEditor;
MimeType=text/plain;text/x-python;text/x-csrc;text/x-c++src;text/xml;text/css;text/javascript;application/json;application/xml;application/x-shellscript;application/x-lua;
DESKTOP

# Rebuild sycoca with XDG_MENU_PREFIX
env XDG_MENU_PREFIX=plasma- kbuildsycoca6 --noincremental

# Update databases
update-desktop-database ~/.local/share/applications

# Set defaults
xdg-mime default imv-custom.desktop image/png
xdg-mime default imv-custom.desktop image/jpeg
xdg-mime default mpv-custom.desktop video/mp4
xdg-mime default mpv-custom.desktop audio/mpeg
xdg-mime default firefox-pdf.desktop application/pdf
xdg-mime default vim-editor.desktop text/plain

echo "✅ KDE file associations fixed!"
