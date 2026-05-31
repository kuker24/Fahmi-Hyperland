local home = os.getenv("HOME") or ""
local scriptsDir = home .. "/.config/fahmi/hypr/scripts"
local themeScriptsDir = home .. "/.config/fahmi/hypr/theme/scripts"

hl.on("hyprland.start", function()
    hl.exec_cmd("hyprpm reload && hyprctl reload")
    hl.exec_cmd("hyprpaper")
    hl.exec_cmd(scriptsDir .. "/compile-run-binaries.sh")
    hl.exec_cmd("systemctl --user start hyprpolkitagent")
    hl.exec_cmd(themeScriptsDir .. "/system-theme.sh apply")
    -- nm-applet disabled: it was issuing user-requested WiFi disconnects after reconnect.
    -- WiFi is managed by the custom AGS nmcli widget instead.
    hl.exec_cmd("wl-paste --watch bash -c \"" .. home .. "/.config/fahmi/hypr/scripts/clipboard-monitor.sh &\"")
    hl.exec_cmd("blueman-applet")
end)

