pragma ComponentBehavior: Bound

import QtQuick
import "../style"

Item {
    id: root
    property string material: AtollStyle.controlPlate
    property real controlHeight: Math.round(30 * AtollStyle.density)
    readonly property bool framed: ["veil", "glass", "solid"].includes(root.material)
    readonly property real inset: root.framed ? Math.round(4 * AtollStyle.density) : 0
    readonly property real controlRadius: root.framed ? AtollStyle.pieceRadius(root.controlHeight) : Math.round(root.controlHeight / 2)
    default property alias content: holder.data

    implicitWidth: holder.implicitWidth + root.inset * 2
    implicitHeight: holder.implicitHeight + root.inset * 2

    Rectangle {
        id: plate
        anchors.fill: parent
        visible: root.framed
        radius: root.controlRadius + root.inset
        color: AtollStyle.plateFillFor(root.material)
    }
    AtollGlassEdge {
        anchors.fill: parent
        visible: (root.material === "glass" || (root.framed && AtollStyle.edgeLit)) && shown
        radius: plate.radius
    }
    Item {
        id: holder
        x: root.inset
        y: root.inset
        implicitWidth: holder.childrenRect.width
        implicitHeight: holder.childrenRect.height
        width: holder.implicitWidth
        height: holder.implicitHeight
    }
}
