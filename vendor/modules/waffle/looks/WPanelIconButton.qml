import QtQuick
import Quickshell
import "../../.."
import "../../../services"
import "../../common"
import "."
import "../bar"

WButton {
    id: root

    readonly property var currentScreen: root.QsWindow?.window?.screen ?? null
    property alias iconName: iconContent.icon
    property alias monochrome: iconContent.monochrome
    implicitWidth: Looks.scaled(40, currentScreen)
    implicitHeight: Looks.scaled(40, currentScreen)

    contentItem: FluentIcon {
        id: iconContent
        anchors.centerIn: parent
        implicitSize: Looks.scaled(18, root.currentScreen)
        icon: root.iconName
    }
}
