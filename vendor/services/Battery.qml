pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.UPower

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
    property real timeToEmpty: UPower.displayDevice?.timeToEmpty ?? 0
    property real timeToFull: UPower.displayDevice?.timeToFull ?? 0
}
