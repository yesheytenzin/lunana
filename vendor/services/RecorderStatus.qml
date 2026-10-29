pragma Singleton
import QtQuick
import Quickshell

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
}
