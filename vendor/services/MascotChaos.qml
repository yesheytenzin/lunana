pragma Singleton
import QtQuick
import Quickshell

// LUNANA SHIM (not vendored from inir) — Wave-A load stub.
// The exact ii bar listens for mascot panel-shake; silent until the
// mascot unit backs this with the real chaos state.
Singleton {
    property bool enabled: false
    property bool suppressed: true
    signal impact(string widgetKey, real vx, real vy, string mode)
    signal panelShake(real intensity, string output)
    signal tidied()
}
