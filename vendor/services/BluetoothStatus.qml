pragma Singleton
import QtQuick
import Quickshell

// LUNANA SHIM (not vendored from inir) — Wave-A load stub.
// The exact ii bar reads the tray bluetooth icon/tooltip here; hidden until
// the live-bluetooth unit backs this with BlueZ.
Singleton {
    property string activeIcon: ""
    property bool available: false
    property string connectionTooltip: ""
    // Wave-C R5: iRiS bubble face reads these; live BlueZ lands later.
    property bool enabled: false
    property int activeDeviceCount: 0
}
