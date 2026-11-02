pragma ComponentBehavior: Bound

import QtQuick
import "../../common/widgets"
import "../style"

Rectangle {
    id: root

    required property var face
    property string glyph: ""
    property string name: ""
    property color tint: root.face.ink
    property bool danger: false
    signal activated()

    implicitWidth: root.face.dp(32)
    implicitHeight: implicitWidth
    radius: height / 2
    color: hover.hovered ? (root.danger ? AtollStyle.tintFill(root.face.danger) : root.face.fillHover) : root.face.fill
    scale: tap.pressed ? AtollStyle.pressScale(0.94) : 1
    Behavior on color { ColorAnimation { duration: AtollStyle.feedbackDuration; easing.type: AtollStyle.feedbackEasing } }
    Behavior on scale { NumberAnimation { duration: AtollStyle.feedbackDuration; easing.type: AtollStyle.feedbackEasing } }

    MaterialSymbol {
        anchors.centerIn: parent
        text: root.glyph
        fill: 1
        iconSize: root.face.px(17)
        color: hover.hovered && root.danger ? root.face.danger : root.tint
    }
    HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
    TapHandler { id: tap; gesturePolicy: TapHandler.WithinBounds; onTapped: root.activated() }
    Accessible.role: Accessible.Button
    Accessible.name: root.name
}
