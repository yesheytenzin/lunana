pragma Singleton
import QtQuick
import Quickshell

// LUNANA SHIM (not vendored from inir) — Wave-A + Wave-B load stub union.
// The exact ii bar listens for mascot panel-shake (impact signal); the Waffle
// bar shakes on panelShake unless suppressed. Silent/disabled until the mascot
// unit backs this with real chaos state.
Singleton {
    property bool enabled: false
    property bool suppressed: true

    signal impact(string widgetKey, real vx, real vy, string mode)
    signal panelShake(real intensity, string output)
}
