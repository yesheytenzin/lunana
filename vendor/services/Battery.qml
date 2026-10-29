pragma Singleton
import QtQuick
import Quickshell

// LUNANA SHIM (not vendored from inir) — Wave-A load stub.
// The exact ii bar reads charge state here; defaults render
// "no battery" until the live-power unit backs this with UPower.
Singleton {
    property bool available: false
    property string chargeState: ""
    property real energyRate: 0
    property bool isCharging: false
    property bool isPluggedIn: false
    property real percentage: 0
    property real timeToEmpty: 0
    property real timeToFull: 0
}
