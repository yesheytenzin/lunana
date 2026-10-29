pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.UPower
import "../modules/common"

// Live charge state via UPower display device. Empty-safe: no battery or no
// daemon falls back to "no battery", hiding the bar indicator.
Singleton {
    id: root

    property bool available: UPower.displayDevice?.isLaptopBattery ?? false
    property var chargeState: UPower.displayDevice?.state ?? 0
    property real energyRate: UPower.displayDevice?.changeRate ?? 0
    property bool isCharging: root.chargeState === UPowerDeviceState.Charging
    property bool isPluggedIn: root.isCharging || root.chargeState === UPowerDeviceState.PendingCharge
    property real percentage: UPower.displayDevice?.percentage ?? 0
    // inir parity (Battery.qml:38,43): low-battery state the island OSD watches.
    readonly property bool isLow: root.available && (root.percentage <= ((Config.options?.battery?.low ?? 20) / 100))
    readonly property bool isLowAndNotCharging: root.isLow && !root.isCharging
    property real timeToEmpty: UPower.displayDevice?.timeToEmpty ?? 0
    property real timeToFull: UPower.displayDevice?.timeToFull ?? 0
}
