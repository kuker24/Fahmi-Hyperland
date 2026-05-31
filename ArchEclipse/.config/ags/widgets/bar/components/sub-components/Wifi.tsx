import { Gtk } from "ags/gtk4";
import { createPoll } from "ags/time";
import { execAsync } from "ags/process";
import { createState } from "ags";

export default () => {
  const [ssid, setSsid] = createState("Disconnected");
  const [signal, setSignal] = createState(0);
  const [icon, setIcon] = createState("network-wireless-offline-symbolic");
  const [networks, setNetworks] = createState<
    Array<{ ssid: string; signal: string; active: boolean }>
  >([]);
  const [scanning, setScanning] = createState(false);

  // Poll WiFi status every 3 seconds
  const wifiStatus = createPoll("", 3000, () => {
    execAsync(["bash", "-c", "nmcli -t -f active,ssid,signal dev wifi"])
      .then((output) => {
        const lines = output.trim().split("\n");
        for (const line of lines) {
          const [active, name, sig] = line.split(":");
          if (active === "yes" && name) {
            setSsid(name);
            setSignal(parseInt(sig) || 0);
            // Set icon based on signal
            const s = parseInt(sig) || 0;
            if (s > 75) setIcon("network-wireless-signal-excellent-symbolic");
            else if (s > 50)
              setIcon("network-wireless-signal-good-symbolic");
            else if (s > 25)
              setIcon("network-wireless-signal-ok-symbolic");
            else if (s > 0)
              setIcon("network-wireless-signal-weak-symbolic");
            else setIcon("network-wireless-offline-symbolic");
            return;
          }
        }
        setSsid("Disconnected");
        setSignal(0);
        setIcon("network-wireless-offline-symbolic");
      })
      .catch(() => {
        setSsid("Disconnected");
        setSignal(0);
        setIcon("network-wireless-offline-symbolic");
      });
    return "";
  });

  const scanNetworks = () => {
    setScanning(true);
    execAsync(["bash", "-c", "nmcli device wifi rescan 2>/dev/null; sleep 1; nmcli -t -f ssid,signal,active dev wifi"])
      .then((output) => {
        const lines = output.trim().split("\n");
        const nets: Array<{ ssid: string; signal: string; active: boolean }> =
          [];
        const seen = new Set<string>();
        for (const line of lines) {
          const [name, sig, active] = line.split(":");
          if (name && !seen.has(name)) {
            seen.add(name);
            nets.push({
              ssid: name,
              signal: sig || "0",
              active: active === "yes",
            });
          }
        }
        setNetworks(nets);
        setScanning(false);
      })
      .catch(() => setScanning(false));
  };

  const connectWifi = (name: string) => {
    execAsync([
      "bash",
      "-c",
      `nmcli device wifi connect "${name}" 2>&1 || nmcli con up "${name}" 2>&1`,
    ])
      .then((out) => {
        console.log("WiFi connect result:", out);
      })
      .catch((err) => {
        console.error("WiFi connect error:", err);
      });
  };

  const disconnectWifi = () => {
    execAsync(["bash", "-c", "nmcli device disconnect wlan0"])
      .then(() => console.log("WiFi disconnected"))
      .catch((err) => console.error("WiFi disconnect error:", err));
  };

  const restartNetworkManager = () => {
    execAsync(["bash", "-c", "pkexec systemctl restart NetworkManager"])
      .then(() => console.log("NetworkManager restarted"))
      .catch((err) => console.error("Restart error:", err));
  };

  return (
    <menubutton class="wifi-widget">
      <box spacing={4}>
        <image iconName={icon} pixelSize={14} />
        <label label={ssid} maxWidthChars={15} />
      </box>
      <popover
        $={(self) => {
          self.connect("notify::visible", () => {
            if (self.visible) {
              self.add_css_class("popover-open");
              scanNetworks();
            } else {
              self.remove_css_class("popover-open");
            }
          });
        }}
      >
        <box
          orientation={Gtk.Orientation.VERTICAL}
          spacing={8}
          class="wifi-popover"
          widthRequest={280}
        >
          {/* Header */}
          <box spacing={8}>
            <image iconName={icon} pixelSize={16} />
            <label label={ssid} hexpand xalign={0} />
            <label label={`${signal}%`} />
          </box>

          {/* Action buttons */}
          <box spacing={4}>
            <button
              class="wifi-action-btn"
              onClicked={() => scanNetworks()}
              hexpand
            >
              <box spacing={4}>
                <image
                  iconName="view-refresh-symbolic"
                  pixelSize={12}
                />
                <label label="Scan" />
              </box>
            </button>
            <button
              class="wifi-action-btn"
              onClicked={() => disconnectWifi()}
              hexpand
            >
              <box spacing={4}>
                <image
                  iconName="network-offline-symbolic"
                  pixelSize={12}
                />
                <label label="Disconnect" />
              </box>
            </button>
            <button
              class="wifi-action-btn"
              onClicked={() => restartNetworkManager()}
              hexpand
            >
              <box spacing={4}>
                <image
                  iconName="system-reboot-symbolic"
                  pixelSize={12}
                />
                <label label="Restart NM" />
              </box>
            </button>
          </box>

          {/* Separator */}
          <box heightRequest={1} css="background-color: rgba(255,255,255,0.1);" />

          {/* Network list */}
          <scrolledwindow
            heightRequest={200}
            vscrollbarPolicy={Gtk.PolicyType.AUTOMATIC}
          >
            <box orientation={Gtk.Orientation.VERTICAL} spacing={2}>
              {scanning((s) =>
                s ? <label label="Scanning..." /> : <box />,
              )}
              {networks((nets) =>
                nets.map((net) => (
                  <button
                    class={`wifi-network-btn ${net.active ? "active" : ""}`}
                    onClicked={() => {
                      if (!net.active) connectWifi(net.ssid);
                    }}
                  >
                    <box spacing={8}>
                      <image
                        iconName={
                          parseInt(net.signal) > 75
                            ? "network-wireless-signal-excellent-symbolic"
                            : parseInt(net.signal) > 50
                              ? "network-wireless-signal-good-symbolic"
                              : parseInt(net.signal) > 25
                                ? "network-wireless-signal-ok-symbolic"
                                : "network-wireless-signal-weak-symbolic"
                        }
                        pixelSize={14}
                      />
                      <label label={net.ssid} hexpand xalign={0} />
                      <label label={`${net.signal}%`} />
                      {net.active ? (
                        <image
                          iconName="object-select-symbolic"
                          pixelSize={12}
                        />
                      ) : (
                        <box />
                      )}
                    </box>
                  </button>
                )),
              )}
            </box>
          </scrolledwindow>
        </box>
      </popover>
    </menubutton>
  );
};
