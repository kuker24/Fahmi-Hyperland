import { createPoll } from "ags/time";
import { execAsync } from "ags/process";

const networkIcon = (state: string) => {
  if (state.startsWith("connected:")) return "󰤨";
  if (state === "connecting") return "󰤫";
  return "󰤮";
};

const networkLabel = (state: string) => {
  if (state.startsWith("connected:")) {
    const ssid = state.replace("connected:", "").trim();
    return ssid.length > 14 ? `${ssid.slice(0, 13)}…` : ssid;
  }
  if (state === "connecting") return "Connecting";
  return "WiFi";
};

export default () => {
  const state = createPoll("WiFi", 2500, [
    "bash",
    "-lc",
    `
      nm_state=$(nmcli -t -f DEVICE,TYPE,STATE dev status | awk -F: '$1=="wlan0" {print $3}')
      ssid=$(nmcli -t -f active,ssid dev wifi | awk -F: '$1=="yes" {print $2; exit}')
      if [ -n "$ssid" ]; then
        printf 'connected:%s' "$ssid"
      elif [ "$nm_state" = "connecting" ]; then
        printf 'connecting'
      else
        printf 'disconnected'
      fi
    `,
  ]);

  const openNetworkMenu = () => {
    execAsync([
      "bash",
      "-lc",
      `
        nmcli radio wifi on >/dev/null 2>&1 || true
        nmcli dev wifi rescan >/dev/null 2>&1 || true
        networkmanager_dmenu >/tmp/networkmanager-dmenu.log 2>&1 &
      `,
    ]).catch((err) => console.error("networkmanager_dmenu failed", err));
  };

  return (
    <button
      class="wifi-chip"
      tooltipText="Open WiFi manager"
      onClicked={openNetworkMenu}
    >
      <box spacing={6}>
        <label class="wifi-chip-icon" label={state((s) => networkIcon(s))} />
        <label class="wifi-chip-label" label={state((s) => networkLabel(s))} />
      </box>
    </button>
  );
};
