pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import "../../style"

Item {
    id: body
    property color light
    property real restWidth: 0
    property real restHeight: 0
    property real progress: 1
    default property alias content: bodyContent.data
    RectangularShadow {
        anchors.fill: bodyPlate
        radius: bodyPlate.radius
        offset.y: 3 * AtollStyle.density
        blur: 16 * AtollStyle.density
        color: AtollStyle.shadow
    }
    LitPlate {
        id: bodyPlate
        anchors.fill: parent
        radius: Math.min(AtollStyle.radiusSheet, height / 2)
        light: body.light
    }
    Item {
        id: bodyContent
        readonly property real pad: AtollStyle.concentricPad(AtollStyle.radiusSheet, 14 * AtollStyle.density)
        x: bodyContent.pad
        y: bodyContent.pad
        width: body.restWidth - 2 * bodyContent.pad
        height: body.restHeight - 2 * bodyContent.pad
        opacity: AtollStyle.ramp(body.progress, 0.55, 0.45)
        visible: opacity > 0
    }
}
