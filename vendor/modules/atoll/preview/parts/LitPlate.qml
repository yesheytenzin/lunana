pragma ComponentBehavior: Bound

import QtQuick
import "../../style"
import "../../components"

Rectangle {
    id: lit
    property color light: AtollStyle.wallpaperLight
    color: AtollStyle.bodySurface
    border.width: AtollStyle.rim.a > 0 ? 1 : 0
    border.color: AtollStyle.rim
    AtollGlassEdge { anchors.fill: parent; z: 10; visible: AtollStyle.edgeLit && shown; radius: parent.radius }
    AtollLightWash {
        anchors.fill: parent
        radius: lit.radius
        light: lit.light
    }
}
