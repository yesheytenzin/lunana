pragma Singleton
import QtQuick
import Quickshell

// LUNANA SHIM (not vendored from inir) — Wave-A load stub.
// The exact ii bar shows caps/num/layout indicators here; hidden until the
// live-keyboard unit backs this with Hyprland/XKB state.
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
