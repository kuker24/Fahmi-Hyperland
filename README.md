# Fahmi Hyperland

<div align="center">

![Hyprland](https://img.shields.io/badge/Hyprland-v0.55-blue)
![Arch Linux](https://img.shields.io/badge/Arch_Linux-CachyOS-blue)
![AGS](https://img.shields.io/badge/AGS-v3.1-green)
![License](https://img.shields.io/badge/License-MIT-yellow)

A customized [Hyprland](https://hyprland.org/) desktop environment with dynamic wallpapers, AGS widgets, and per-workspace theming.

Based on [ArchEclipse](https://github.com/AymanLyesri/ArchEclipse) rice.

</div>

---

## ✨ Features

- 🎨 **167 Wallpapers** - Curated collection from [Wallpaper Bank](https://github.com/JaKooLit/Wallpaper-Bank)
- 🖥️ **Per-Workspace Wallpapers** - Different wallpaper for each workspace (1-10)
- 🎯 **AGS Bar** - System tray, workspaces, media controls, and widgets
- 🎨 **Dynamic Theme Colors** - Automatic color scheme using [pywal](https://github.com/dylanaraps/pywal)
- 📸 **Screenshot Tool** - Full screen and area selection screenshots
- 🔋 **System Monitoring** - Battery and update notifications
- ⌨️ **Custom Keybinds** - Intuitive keyboard shortcuts

## 📸 Screenshots

> Coming soon...

## 🚀 Quick Start

```bash
# Clone the repository
git clone https://github.com/fahmi12345/Fahmi-Hyperland.git
cd Fahmi-Hyperland

# Run the setup script
chmod +x setup.sh
./setup.sh
```

The script will automatically:
1. Install all dependencies
2. Clone ArchEclipse
3. Copy all configurations
4. Setup wallpapers
5. Compile binaries
6. Apply theme

## 📋 Requirements

- **OS**: Arch Linux or CachyOS
- **Compositor**: Hyprland
- **Shell**: Bash

## ⌨️ Keybinds

| Keybind | Action |
|---------|--------|
| `Super + Return` | Open terminal |
| `Super + W` | Wallpaper switcher |
| `Super + Shift + P` | Screenshot |
| `Super + Ctrl + Shift + P` | Screenshot area |
| `Super + I` | Open browser |
| `Super + Space` | Toggle float |
| `Super + F` | Toggle fullscreen |
| `Super + Q` | Close window |
| `Super + 1-10` | Switch workspace |
| `Super + B` | Refresh bar |
| `Super + Escape` | User panel |

## 🎨 Customization

### Gaps

Edit `~/.config/fahmi/hypr/config/general.lua`:

```lua
gaps_in = 15,   -- Inner gaps between windows
gaps_out = 20,  -- Outer gaps from screen edges
```

### Bar Margin

Edit `~/.config/ags/variables.ts`:

```typescript
export const globalMargin = 15;
```

### Wallpaper Per Workspace

Press `Super + W` to open the wallpaper switcher, then:
1. Select workspace (1-10) at the top
2. Click a wallpaper to apply it

## 📁 Project Structure

```
Fahmi-Hyperland/
├── setup.sh                 # Auto-install script
├── README.md                # This file
├── dependencies.txt         # Package dependencies
├── services.txt             # Systemd services info
├── ArchEclipse/             # Base ArchEclipse configuration
│   └── .config/
│       ├── ags/             # AGS widget configuration
│       └── hypr/            # Hyprland base configuration
└── configs/
    ├── hypr/                # Modified Hyprland configs
    │   ├── config/
    │   │   ├── general.lua  # Gaps, layout settings
    │   │   ├── bind.lua     # Keybindings
    │   │   └── exec.lua     # Startup scripts
    │   ├── scripts/         # Utility scripts
    │   └── wallpaper-daemon/
    │       └── config/
    │           └── eDP-1/
    │               └── defaults.conf  # Per-workspace wallpapers
    ├── ags/                 # AGS configuration
    ├── ags-settings/        # AGS settings cache
    ├── hypridle.conf        # Idle daemon config
    ├── fahmi/               # Start script
    └── wallpapers/          # 167 wallpapers
        └── defaults/
```

## 🔧 Manual Setup

<details>
<summary>Click to expand manual setup instructions</summary>

### 1. Install Dependencies

```bash
yay -S --needed \
    hyprland hyprpaper hypridle hyprlock hyprpicker hyprpolkitagent \
    aylurs-gtk-shell-git \
    kitty fastfetch starship \
    nautilus brave-bin \
    imagemagick ffmpeg grim slurp wl-clipboard \
    brightnessctl wireplumber pipewire pipewire-pulse \
    networkmanager nm-applet blueman blueman-applet \
    phinger-cursors whitesur-gtk-theme whitesur-icon-theme kvantum \
    python-pywal \
    gcc base-devel jq git
```

### 2. Clone ArchEclipse

```bash
git clone https://github.com/AymanLyesri/ArchEclipse.git ~/ArchEclipse
ln -sf ~/ArchEclipse/.config/ags ~/.config/ags
ln -sf ~/ArchEclipse/.config/hypr ~/.config/hypr
```

### 3. Copy Configurations

```bash
# Hyprland configs
rsync -av configs/hypr/ ~/.config/fahmi/hypr/

# AGS configs
rsync -av configs/ags/ ~/ArchEclipse/.config/ags/

# AGS settings
mkdir -p ~/.config/ags/cache/settings
cp configs/ags-settings/settings.json ~/.config/ags/cache/settings/

# Wallpapers
rsync -av configs/wallpapers/ ~/.config/wallpapers/

# Other configs
cp configs/hypridle.conf ~/.config/hypr/
cp configs/fahmi/start-hyprland-fahmi.sh ~/.config/fahmi/
chmod +x ~/.config/fahmi/start-hyprland-fahmi.sh
```

### 4. Enable Services

```bash
systemctl --user enable hyprpaper
systemctl --user enable hypridle
systemctl --user enable hyprpolkitagent
```

### 5. Compile and Start

```bash
# Compile C binaries
gcc ~/.config/fahmi/hypr/scripts-c/battery-check.c -o /tmp/battery-check
gcc ~/.config/fahmi/hypr/scripts-c/updates-check.c -o /tmp/updates-check
gcc ~/.config/fahmi/hypr/scripts-c/wallpaper-loop.c -o /tmp/wallpaper-loop

# Bundle AGS
ags bundle ~/.config/fahmi/ags/app.tsx /tmp/ags-$(whoami)/ags-bin

# Start Hyprland
Hyprland --config ~/.config/fahmi/hypr/hyprland.lua
```

</details>

## 🐛 Troubleshooting

<details>
<summary>AGS not starting</summary>

```bash
# Check for errors
ags run 2>&1

# Restart AGS
killall gjs ags-bin
~/.config/fahmi/hypr/scripts/compile-run-binaries.sh
```

</details>

<details>
<summary>Wallpaper switcher empty</summary>

```bash
# Check config files are synced
cat ~/.config/hypr/wallpaper-daemon/config/eDP-1/defaults.conf
cat ~/.config/fahmi/hypr/wallpaper-daemon/config/eDP-1/defaults.conf

# Both should have the same content
```

</details>

<details>
<summary>Hyprland errors</summary>

```bash
# Check Hyprland logs
journalctl --user -u hyprland -n 50
```

</details>

## 🙏 Credits

- [ArchEclipse](https://github.com/AymanLyesri/ArchEclipse) - Base configuration
- [JaKooLit/Wallpaper-Bank](https://github.com/JaKooLit/Wallpaper-Bank) - Wallpapers
- [Hyprland](https://hyprland.org/) - Compositor
- [AGS](https://aylur.github.io/ags-docs/) - Widget framework

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

<div align="center">

**[⬆ Back to top](#fahmi-hyperland)**

</div>
