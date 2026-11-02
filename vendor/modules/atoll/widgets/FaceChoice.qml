pragma ComponentBehavior: Bound

import QtQuick
import "../../common/widgets"
import "../style"

Rectangle {
    id: root

    property string icon: ""
    property string label: ""
    property bool selected: false
    signal clicked()

    implicitWidth: row.implicitWidth + Math.round(20 * AtollStyle.density)
    implicitHeight: Math.round(34 * AtollStyle.density)
    radius: height / 2
    color: root.selected ? AtollStyle.tintFill(AtollStyle.accent)
        : hover.hovered ? AtollStyle.fillHover : AtollStyle.fillQuiet
    border.width: root.selected ? 1 : 0
    border.color: AtollStyle.tintBorder(AtollStyle.accent)
    scale: tap.pressed ? AtollStyle.pressScale(0.97) : 1
    Behavior on color { ColorAnimation { duration: AtollStyle.feedbackDuration; easing.type: AtollStyle.feedbackEasing } }
    Behavior on scale { NumberAnimation { duration: AtollStyle.feedbackDuration; easing.type: AtollStyle.feedbackEasing } }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: Math.round(6 * AtollStyle.density)
        MaterialSymbol {
            visible: root.icon.length > 0
            anchors.verticalCenter: parent.verticalCenter
            text: root.icon
            fill: root.selected ? 1 : 0
            iconSize: 16 * AtollStyle.typeScale
            color: root.selected ? AtollStyle.accent : AtollStyle.textSecondary
        }
        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            text: root.label
            color: root.selected ? AtollStyle.text : AtollStyle.textSecondary
            font.family: AtollStyle.fontMain
            font.pixelSize: AtollStyle.typeLabel
            font.weight: root.selected ? Font.DemiBold : Font.Medium
        }
    }

    HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
    TapHandler { id: tap; onTapped: root.clicked() }
    Accessible.role: Accessible.Button
    Accessible.name: root.label
    Accessible.checked: root.selected
}
