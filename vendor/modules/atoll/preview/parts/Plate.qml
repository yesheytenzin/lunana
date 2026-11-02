pragma ComponentBehavior: Bound

import QtQuick
import "../../style"
import "../../components"

Rectangle {
    id: plate
    property string surface: ""
    property int fallbackRadius: AtollStyle.radiusSheet
    property color own: AtollStyle.accent
    readonly property color light: AtollStyle.surfaceLight(plate.surface, plate.own)
    radius: AtollStyle.surfaceRadius(plate.surface, plate.fallbackRadius)
    color: AtollStyle.bodySurface
    border.width: AtollStyle.rim.a > 0 ? 1 : 0
    border.color: AtollStyle.rim
    AtollGlassEdge { anchors.fill: parent; z: 10; visible: AtollStyle.edgeLit && shown; radius: parent.radius }
    AtollLightWash {
        anchors.fill: parent
        radius: plate.radius
        light: plate.light
    }
}
