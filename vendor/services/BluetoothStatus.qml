pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Live adapter state via rfkill + bluetoothctl. Empty-safe: no adapter or
// missing tools keeps available false, hiding the bar indicator.
Singleton {
    id: root

    property string activeIcon: "bluetooth"
    property bool available: false

    property bool _enabled: false
    property bool _connected: false
    property string _deviceName: ""

    function connectionTooltip() {
        if (!root._enabled) return "Bluetooth is disabled";
        if (!root._connected) return "Bluetooth disconnected";
        return root._deviceName.length > 0 ? root._deviceName : "Bluetooth connected";
    }

    function _refresh() {
        if (!btPoll.running) btPoll.running = true;
    }

    Timer {
        interval: 10000
        running: true
        repeat: true
        onTriggered: root._refresh()
    }
    Component.onCompleted: root._refresh()

    Process {
        id: btPoll
        command: ["sh", "-c", "rfkill list bluetooth 2>/dev/null; echo __SEP__; bluetoothctl show 2>/dev/null; echo __SEP__; bluetoothctl devices Connected 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = String(text).split("__SEP__");
                const rfkillOut = (parts[0] ?? "");
                const showOut = (parts[1] ?? "");
                const devicesOut = (parts[2] ?? "").trim();
                const hasAdapter = rfkillOut.indexOf("Bluetooth") >= 0 || showOut.indexOf("Controller") >= 0;
                const softBlocked = rfkillOut.indexOf("Soft blocked: yes") >= 0;
                const powered = showOut.indexOf("Powered: yes") >= 0;
                root.available = hasAdapter;
                root._enabled = hasAdapter && !softBlocked && powered;
                root._connected = root._enabled && devicesOut.length > 0;
                root._deviceName = "";
                if (root._connected) {
                    const line = devicesOut.split("\n")[0];
                    const m = /^Device\s+\S+\s+(.+)$/.exec(line.trim());
                    if (m) root._deviceName = m[1];
                }
                root.activeIcon = !root._enabled ? "bluetooth_disabled" : (root._connected ? "bluetooth_connected" : "bluetooth");
            }
        }
    }
}
