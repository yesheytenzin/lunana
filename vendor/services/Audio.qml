pragma Singleton
import QtQuick
import Quickshell

// LUNANA SHIM (not vendored from inir) — Wave-A load stub.
// The exact ii bar reads volume state behind `Audio.sink`; null-safe callers
// (`?.`) render mute until the live-audio unit backs this with PipeWire.
Singleton {
    property var sink: null
    property bool micMuted: false
    function incrementVolume() {}
    function decrementVolume() {}
    function toggleMicMute() {}
}
