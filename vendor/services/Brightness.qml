pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Live backlight level via brightnessctl (same pattern as lunana.control-center).
// Always returns a working monitor; missing brightnessctl keeps level at 1.0.
Singleton {
    id: root

    property real level: 1.0
    // inir parity: per-monitor changes surface here so the island's
    // onBrightnessChanged attaches to a real notifier.
    signal brightnessChanged()
    onLevelChanged: root.brightnessChanged()

    function setLevel(v) {
        v = Math.max(0.01, Math.min(1, v));
        root.level = v;
        Quickshell.execDetached(["brightnessctl", "-q", "s", Math.max(1, Math.round(v * 100)) + "%"]);
    }

    function getMonitorForScreen(screen) {
        return monitorComp.createObject(root, { svc: root });
    }

    component Monitor: QtObject {
        property var svc: null
        property real brightness: svc ? svc.level : 1.0
        function setBrightness(value) {
            if (svc) svc.setLevel(value);
        }
    }
    Component {
        id: monitorComp
        Monitor {}
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: {
            if (!levelPoll.running) levelPoll.running = true;
        }
    }
    Component.onCompleted: levelPoll.running = true

    Process {
        id: levelPoll
        command: ["sh", "-c", "brightnessctl -m 2>/dev/null | head -n 1 | awk -F, '{print $4}' | tr -d '%'"]
        stdout: StdioCollector {
            onStreamFinished: {
                const v = parseInt(String(text).trim());
                if (!isNaN(v)) root.level = Math.max(1, Math.min(100, v)) / 100;
            }
        }
    }
}
