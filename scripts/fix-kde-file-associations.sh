#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  Fix KDE/Dolphin "Open With" Blank Dialog                    ║
# ║  Root Cause: Missing applications.menu + corrupt sycoca      ║
# ╚══════════════════════════════════════════════════════════════╝

set -e

echo "🔧 Fixing KDE File Associations..."

# Step 1: Create applications.menu symlink if missing
if [ ! -f /etc/xdg/menus/applications.menu ]; then
    echo "⚠️  /etc/xdg/menus/applications.menu not found!"
    echo "   Creating symlink to plasma-applications.menu..."
    sudo ln -sf /etc/xdg/menus/plasma-applications.menu /etc/xdg/menus/applications.menu
    echo "✅ Symlink created"
else
    echo "✅ applications.menu exists"
fi

# Step 2: Clean old state
echo ""
echo "🗑️  Cleaning old state..."
rm -f ~/.local/state/keditfiletypestaterc
rm -f ~/.config/filetypesrc
echo "✅ Old state cleaned"

# Step 3: Create custom desktop files
echo ""
echo "📝 Creating custom desktop files..."
mkdir -p ~/.local/share/applications

# imv
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

# mpv
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

# Firefox PDF
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

# vim
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

echo "✅ Desktop files created"

# Step 4: Rebuild sycoca
echo ""
echo "🔄 Rebuilding sycoca6..."
env XDG_MENU_PREFIX=plasma- kbuildsycoca6 --noincremental
echo "✅ Sycoca rebuilt"

# Step 5: Update databases
echo ""
echo "📊 Updating databases..."
update-desktop-database ~/.local/share/applications
update-mime-database ~/.local/share/mime 2>/dev/null || true
echo "✅ Databases updated"

# Step 6: Set defaults
echo ""
echo "⚙️  Setting default applications..."
xdg-mime default imv-custom.desktop image/png
xdg-mime default imv-custom.desktop image/jpeg
xdg-mime default imv-custom.desktop image/gif
xdg-mime default imv-custom.desktop image/webp
xdg-mime default mpv-custom.desktop video/mp4
xdg-mime default mpv-custom.desktop video/x-matroska
xdg-mime default mpv-custom.desktop video/webm
xdg-mime default mpv-custom.desktop audio/mpeg
xdg-mime default mpv-custom.desktop audio/flac
xdg-mime default mpv-custom.desktop audio/mp3
xdg-mime default firefox-pdf.desktop application/pdf
xdg-mime default vim-editor.desktop text/plain
echo "✅ Defaults set"

# Step 7: Create mimeapps.list
echo ""
echo "📄 Creating mimeapps.list..."
cat > ~/.config/mimeapps.list << 'MIME'
[Default Applications]
image/jpeg=imv-custom.desktop
image/png=imv-custom.desktop
image/gif=imv-custom.desktop
image/webp=imv-custom.desktop
image/bmp=imv-custom.desktop
image/tiff=imv-custom.desktop
image/svg+xml=imv-custom.desktop
image/heif=imv-custom.desktop
image/avif=imv-custom.desktop
video/mp4=mpv-custom.desktop
video/x-matroska=mpv-custom.desktop
video/webm=mpv-custom.desktop
video/avi=mpv-custom.desktop
audio/mpeg=mpv-custom.desktop
audio/flac=mpv-custom.desktop
audio/mp3=mpv-custom.desktop
application/pdf=firefox-pdf.desktop
text/plain=vim-editor.desktop
inode/directory=org.kde.dolphin.desktop
x-scheme-handler/http=brave-browser.desktop
x-scheme-handler/https=brave-browser.desktop
MIME

cp ~/.config/mimeapps.list ~/.config/kde-mimeapps.list
cp ~/.config/mimeapps.list ~/.local/share/applications/mimeapps.list
cp ~/.config/mimeapps.list ~/.local/share/kde-mimeapps.list
echo "✅ mimeapps.list created"

# Step 8: Restart Dolphin
echo ""
echo "🐬 Restarting Dolphin..."
killall dolphin 2>/dev/null || true
systemctl --user restart plasma-kded 2>/dev/null || true

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  ✅ DONE! File associations fixed!                           ║"
echo "╠══════════════════════════════════════════════════════════════╣"
echo "║  📷 Image → imv                                             ║"
echo "║  🎬 Video → mpv                                             ║"
echo "║  🎵 Audio → mpv                                             ║"
echo "║  📄 PDF   → firefox                                         ║"
echo "║  📝 Text  → vim                                             ║"
echo "║  📁 Dir   → dolphin                                         ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "💡 Tip: Centang 'Remember application association' saat pertama kali pilih app!"
