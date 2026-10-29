pragma Singleton
import QtQuick
import Quickshell

// LUNANA SHIM (not vendored from inir) — Wave-C R5 load stub.
// Screen-recording state for the iRiS Island clock/record faces; live
// recording status lands with the recorder unit.
Singleton {
    property bool isRecording: false
    property int elapsedSeconds: 0
}
