import QtQuick
import Quickshell
import Quickshell.Bluetooth
import "../../../../services"
import "../.."
import "../../functions"
import "../../widgets"

QuickToggleModel {
    name: Translation.tr("Bluetooth")
    statusText: BluetoothStatus.firstActiveDevice?.name ?? Translation.tr("Not connected")
    tooltipText: Translation.tr("%1 | Right-click to configure").arg(
        BluetoothStatus.activeDeviceSummary(true) || Translation.tr("Bluetooth")
    )
    icon: BluetoothStatus.activeIcon

    available: BluetoothStatus.available
    toggled: BluetoothStatus.enabled
    mainAction: () => {
        Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter?.enabled
    }
    hasMenu: true
    altAction: () => {
        AppLauncher.launch("bluetooth")
    }
}
