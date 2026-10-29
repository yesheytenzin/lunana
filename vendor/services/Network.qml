pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Live wifi/ethernet state via nmcli. Empty-safe: missing nmcli or radio off
// keeps offline defaults, bar renders "Wi-Fi is disabled"/"Not connected".
Singleton {
    id: root

    property var active: null
    property bool ethernet: false
    property string materialSymbol: "signal_wifi_off"
    property string networkName: ""
    property bool online: false
    property bool wifiEnabled: false

    property var _link: ({ strength: 0, wifiStatus: "disconnected" })

    function accessPointDetails(ap, full) {
        if (!ap) return "";
        const details = [];
        if ((ap.strength ?? -1) >= 0) details.push(ap.strength + "%");
        if (full && (ap.bssid ?? "").length > 0) details.push(ap.bssid);
        return details.join(" | ");
    }
    function refreshActiveNetworkDetails() {
        if (!linkPoll.running) linkPoll.running = true;
        if (!statusPoll.running) statusPoll.running = true;
    }

    function _updateSymbol() {
        if (root.ethernet) {
            root.materialSymbol = "lan";
        } else if (!root.wifiEnabled) {
            root.materialSymbol = "signal_wifi_off";
        } else if (root._link.wifiStatus === "connected") {
            const s = root._link.strength;
            root.materialSymbol = s > 83 ? "signal_wifi_4_bar" : s > 67 ? "network_wifi" : s > 50 ? "network_wifi_3_bar" : s > 33 ? "network_wifi_2_bar" : s > 17 ? "signal_wifi_1_bar" : "signal_wifi_0_bar";
        } else if (root._link.wifiStatus === "connecting") {
            root.materialSymbol = "signal_wifi_statusbar_not_connected";
        } else if (root._link.wifiStatus === "disconnected") {
            root.materialSymbol = "wifi_find";
        } else {
            root.materialSymbol = "signal_wifi_bad";
        }
    }

    Timer {
        interval: 8000
        running: true
        repeat: true
        onTriggered: root.refreshActiveNetworkDetails()
    }
    Component.onCompleted: root.refreshActiveNetworkDetails()

    Process {
        id: statusPoll
        command: ["sh", "-c", "nmcli radio wifi 2>/dev/null; echo __SEP__; nmcli networking connectivity 2>/dev/null; echo __SEP__; nmcli -t -f TYPE,STATE d status 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = String(text).split("__SEP__");
                root.wifiEnabled = (parts[0] ?? "").trim() === "enabled";
                const connectivity = (parts[1] ?? "").trim().toLowerCase();
                root.online = connectivity === "full" || connectivity === "unknown" || connectivity.length === 0;
                let eth = false;
                let wifiStatus = root.wifiEnabled ? "disconnected" : "disabled";
                for (const line of String(parts[2] ?? "").split("\n")) {
                    if (line.indexOf("ethernet:connected") === 0) eth = true;
                    else if (line.indexOf("wifi:") === 0) {
                        if (line.indexOf("connected") > 0) wifiStatus = "connected";
                        else if (line.indexOf("connecting") > 0) wifiStatus = "connecting";
                    }
                }
                root.ethernet = eth;
                root._link = ({ strength: root._link.strength, wifiStatus: wifiStatus });
                root._updateSymbol();
            }
        }
    }
    Process {
        id: linkPoll
        command: ["sh", "-c", "nmcli -t -f ACTIVE,SSID,SIGNAL dev wifi list --rescan no 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                let found = null;
                for (const raw of String(text).split("\n")) {
                    const line = raw.trim();
                    if (!line) continue;
                    const cols = line.replace(/\\:/g, "").split(":");
                    if (cols.length < 3) continue;
                    const strength = parseInt(cols[cols.length - 1]);
                    const ssid = cols.slice(1, -1).join(":");
                    if (!ssid) continue;
                    if (cols[0] === "yes") {
                        found = ({ ssid: ssid, strength: isNaN(strength) ? 0 : strength, bssid: "", active: true });
                        break;
                    }
                }
                root.active = found;
                root.networkName = found ? found.ssid : "";
                root._link = ({ strength: found ? found.strength : 0, wifiStatus: root._link.wifiStatus });
                if (root._link.wifiStatus === "connected" && !found) root._link.wifiStatus = "disconnected";
                root._updateSymbol();
            }
        }
    }
}
