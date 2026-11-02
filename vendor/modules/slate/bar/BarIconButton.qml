import QtQuick
import Quickshell
import "../../.."
import "../../../services"
import "../../common"
import "../looks"
import "."

BarButton {
    id: root

    readonly property var panelScreen: root.QsWindow?.window?.screen ?? null
    property alias iconName: iconContent.icon
    property alias iconSource: iconContent.source
    property alias iconSize: iconContent.implicitSize
    property alias iconRotation: iconContent.rotation
    property alias iconMonochrome: iconContent.monochrome
    property alias iconScale: iconContent.scale
    property alias tooltipText: tooltip.text
    property alias overlayingItems: iconContent.data

    implicitWidth: Looks.scaledBar(32, panelScreen)

    contentItem: Item {
        anchors.centerIn: parent
        implicitWidth: iconContent.implicitWidth
        implicitHeight: iconContent.implicitHeight

        FluentIcon {
            id: iconContent
            anchors.centerIn: parent
            implicitSize: Looks.scaledBar(16, root.panelScreen)
            icon: root.iconName
            monochrome: false
        }
    }

    BarToolTip {
        id: tooltip
        barExtraVisibleCondition: root.shouldShowTooltip && text !== ""
    }
}
