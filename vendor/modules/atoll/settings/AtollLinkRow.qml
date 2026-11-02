pragma ComponentBehavior: Bound

import QtQuick
import "../../common/widgets"
import "../components"
import "../style"

MouseArea {
    id: root

    property var entry: ({})
    property bool tinted: true
    property bool last: true

    width: parent ? parent.width : 0
    height: Math.round(46 * AtollStyle.density)
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    Accessible.role: Accessible.Button
    Accessible.name: root.entry.label ?? ""
    onClicked: root.entry.action()

    Rectangle {
        anchors.fill: parent
        anchors.margins: 3 * AtollStyle.density
        radius: AtollStyle.radiusRow
        color: root.containsMouse ? AtollStyle.fillQuiet : "transparent"
        Behavior on color {
            enabled: AtollStyle.motionEnabled
            ColorAnimation { duration: AtollStyle.duration(110) }
        }
    }
    AtollSquircle {
        id: mark
        visible: root.tinted
        anchors.left: parent.left
        anchors.leftMargin: 14 * AtollStyle.density
        anchors.verticalCenter: parent.verticalCenter
        width: Math.round(26 * AtollStyle.density)
        height: width
        tint: root.entry.tint ?? AtollStyle.identity.gray
        glyph: root.entry.icon ?? "chevron_right"
    }
    MaterialSymbol {
        id: glyph
        visible: !root.tinted
        anchors.left: parent.left
        anchors.leftMargin: 18 * AtollStyle.density
        anchors.verticalCenter: parent.verticalCenter
        text: root.entry.icon ?? "chevron_right"
        iconSize: Math.round(18 * AtollStyle.density)
        color: AtollStyle.subtext
    }
    AtollText {
        id: label
        anchors.left: mark.visible ? mark.right : glyph.right
        anchors.leftMargin: 12 * AtollStyle.density
        anchors.right: value.visible ? value.left : chevron.left
        anchors.rightMargin: value.visible ? 8 * AtollStyle.density : 0
        anchors.verticalCenter: parent.verticalCenter
        text: root.entry.label ?? ""
        font.pixelSize: AtollStyle.typeLabel
        elide: Text.ElideRight
    }
    AtollText {
        id: value
        visible: (root.entry.value ?? "").length > 0
        anchors.right: chevron.left
        anchors.rightMargin: 8 * AtollStyle.density
        anchors.verticalCenter: parent.verticalCenter
        horizontalAlignment: Text.AlignRight
        text: root.entry.value ?? ""
        color: AtollStyle.muted
        font.pixelSize: AtollStyle.typeLabel
        elide: Text.ElideRight
    }
    MaterialSymbol {
        id: chevron
        anchors.right: parent.right
        anchors.rightMargin: 12 * AtollStyle.density
        anchors.verticalCenter: parent.verticalCenter
        text: "chevron_right"
        iconSize: Math.round(18 * AtollStyle.density)
        color: AtollStyle.textTertiary
    }
    Rectangle {
        anchors.left: label.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 1
        visible: !root.last
        color: AtollStyle.hairline
    }
}
