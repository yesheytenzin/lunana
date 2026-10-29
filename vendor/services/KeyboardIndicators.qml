pragma Singleton
import QtQuick
import Quickshell

// LUNANA STUB, KEPT (R3 decision) — best-effort, empty-safe.
// No stable local API exists without inir's HyprlandXkb poller
// (hyprctl devices -j), its evdev lock-state daemon, and Config-gated
// panel options — all out of scope (no new vendoring, no Audio-style
// service growth). The exact ii bar only reads the eight members below
// and hides the indicator when hasPanelIndicators is false, so the
// empty stub is the correct backing until a keyboard unit lands.
Singleton {
    property bool capsLockVisible: false
    property string capsMaterialIcon: ""
    property string currentLayoutCodeInline: ""
    property string currentLayoutCodeMultiline: ""
    property bool hasPanelIndicators: false
    property bool layoutVisible: false
    property bool numLockVisible: false
    property string numMaterialIcon: ""
}
