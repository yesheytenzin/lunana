pragma Singleton
import QtQuick
import Quickshell

<<<<<<< HEAD
// LUNANA STUB (not vendored from inir) — R4 load stub.
// The Waffle bar's system button shows a recording indicator while
// isRecording; screen-recording integration is out of scope, so it stays
// false and the setters/schedule are no-ops.
Singleton {
    property bool isRecording: false
    property int elapsedSeconds: 0
    property string configuredAudioMode: ""
    property string configuredMicrophoneSource: ""
    property string configuredSystemAudioSource: ""

    function scheduleQuickCheck() {}
    function setConfiguredAudioMode(mode) {}
    function setConfiguredMicrophoneSource(source) {}
    function setConfiguredSystemAudioSource(source) {}
=======
// LUNANA SHIM (not vendored from inir) — Wave-C R5 load stub.
// Screen-recording state for the iRiS Island clock/record faces; live
// recording status lands with the recorder unit.
Singleton {
    property bool isRecording: false
    property int elapsedSeconds: 0
>>>>>>> 1c1b743
}
