pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import "../../common/functions"
import "../style"

// Native borders keep the curve antialiased; the light is faded downward by a smooth vertical mask, never a
// ring mask (that pixelated every corner).
Item {
    id: root
    property real radius: 0
    readonly property real lineWidth: Math.max(1, Math.round(AtollStyle.glassEdgeWidth * AtollStyle.density))
    readonly property bool shown: AtollStyle.glassEdgeLight > 0 || AtollStyle.glassEdgeLine > 0
    visible: root.shown

    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: "transparent"
        antialiasing: true
        border.width: AtollStyle.glassEdgeLine > 0 ? root.lineWidth : 0
        border.color: ColorUtils.applyAlpha(AtollStyle.glassEdgeColour, AtollStyle.glassEdgeLine)
    }

    Rectangle {
        anchors.fill: parent
        visible: AtollStyle.glassEdgeLight > AtollStyle.glassEdgeLine
        radius: root.radius
        color: "transparent"
        antialiasing: true
        border.width: root.lineWidth
        border.color: ColorUtils.applyAlpha(AtollStyle.glassEdgeColour, AtollStyle.glassEdgeLight)
        layer.enabled: true
        layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: litFade
            maskThresholdMin: 0.5
            maskSpreadAtMin: 1
        }
    }
    Rectangle {
        id: litFade
        anchors.fill: parent
        visible: false
        layer.enabled: true
        gradient: Gradient {
            GradientStop { position: 0; color: "white" }
            GradientStop { position: 0.55; color: "transparent" }
        }
    }
}
