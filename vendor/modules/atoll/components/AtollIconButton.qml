import QtQuick
import "../../common/widgets"
import "../style"
import "."

AtollButton {
    id: root
    property string materialIcon: "circle"
    property int iconSize: Math.round(18 * AtollStyle.density)
    implicitWidth: Math.round(34 * AtollStyle.density)
    implicitHeight: implicitWidth
    quiet: true

    MaterialSymbol {
        anchors.centerIn: parent
        text: root.materialIcon
        iconSize: root.iconSize
        fill: root.selected ? 1 : 0
        animateFill: true
        font.weight: root.selected || root.hovered ? Font.DemiBold : Font.Normal
        color: root.foreground
    }
}
