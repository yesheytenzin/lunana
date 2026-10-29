pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Live volume/mic state via wpctl (same pattern as lunana.control-center).
// Empty-safe: missing wpctl or devices keeps defaults, bar renders unmuted.
Singleton {
    id: root

    property var sink: sinkObj
    property bool micMuted: false
    property bool micBeingAccessed: false
    // inir parity: live mic level (poll) + sink-guard signal. The wpctl shim
    // never caps the sink, so sinkProtectionTriggered never fires — but the
    // island's Connections needs the signal, and the slider needs the value.
    property real micVolume: 0
    readonly property real value: audioObj.volume
    signal sinkProtectionTriggered(reason: string)

    QtObject {
        id: sinkObj
        property var audio: audioObj
    }
    QtObject {
        id: audioObj
        property real volume: 0
        property bool muted: false
    }

    function incrementVolume() {
        Quickshell.execDetached(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", "5%+"]);
        sinkPoll.running = true;
    }
    function decrementVolume() {
        Quickshell.execDetached(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", "5%-"]);
        sinkPoll.running = true;
    }
    function toggleMicMute() {
        Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_AUDIO_SOURCE@", "toggle"]);
        micPoll.running = true;
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: {
            if (!sinkPoll.running) sinkPoll.running = true;
            if (!micPoll.running) micPoll.running = true;
        }
    }
    Component.onCompleted: {
        sinkPoll.running = true;
        micPoll.running = true;
    }

    Process {
        id: sinkPoll
        command: ["sh", "-c", "wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                const m = /Volume:\s*([0-9.]+)/.exec(text);
                if (!m) return;
                const v = parseFloat(m[1]);
                if (!isNaN(v)) audioObj.volume = v;
                audioObj.muted = text.indexOf("[MUTED]") >= 0;
            }
        }
    }
    Process {
        id: micPoll
        command: ["sh", "-c", "wpctl get-volume @DEFAULT_AUDIO_SOURCE@ 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                const m = /Volume:\s*([0-9.]+)/.exec(text);
                if (!m) return;
                const v = parseFloat(m[1]);
                if (!isNaN(v)) root.micVolume = v;
                root.micMuted = text.indexOf("[MUTED]") >= 0;
            }
        }
    }
}
