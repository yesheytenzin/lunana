pragma ComponentBehavior: Bound

import QtQuick
import "../../../services"
import "../../common"
import "../style"
import "../components"

// One Character preset as a miniature of what it makes a surface: corners, fill and figure contrast.
MouseArea {
    id: tile
    readonly property real d: AtollStyle.density
    required property string name
    readonly property var values: AtollStyle.presets[tile.name] ?? AtollStyle.presets.atoll
    readonly property bool selected: AtollStyle.presetName === tile.name
    implicitHeight: Math.round(62 * tile.d)
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    Accessible.role: Accessible.RadioButton
    Accessible.name: tile.name
    Accessible.checked: tile.selected
    onClicked: Config.setNestedValue("atoll.appearance.preset", tile.name)
    Rectangle {
        id: miniature
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: Math.round(40 * tile.d)
        radius: Math.round(12 * tile.values.shape * tile.d)
        color: AtollStyle.surfaceOpaque
        border.width: tile.selected ? 2 : 1
        border.color: tile.selected ? AtollStyle.accent : (tile.containsMouse ? AtollStyle.borderStrong : AtollStyle.border)
        Behavior on border.color { ColorAnimation { duration: AtollStyle.duration(110); easing.type: AtollStyle.feedbackEasing } }
        Column {
            anchors.fill: parent
            anchors.margins: Math.round(7 * tile.d)
            spacing: Math.round(4 * tile.d)
            Rectangle {
                width: parent.width
                height: Math.round(13 * tile.d)
                radius: Math.round(6 * tile.values.shape * tile.d)
                color: Qt.alpha(AtollStyle.text, Math.min(0.5, 0.12 * tile.values.fill))
            }
            Row {
                spacing: Math.round(4 * tile.d)
                Rectangle { width: Math.round(16 * tile.d); height: Math.round(8 * tile.d); radius: height / 2; color: AtollStyle.accent }
                Rectangle { width: Math.round(22 * tile.d); height: Math.round(8 * tile.d); radius: height / 2; color: Qt.alpha(AtollStyle.text, tile.values.textTertiary) }
            }
        }
    }
    AtollText {
        anchors.top: miniature.bottom
        anchors.topMargin: Math.round(4 * tile.d)
        anchors.horizontalCenter: parent.horizontalCenter
        text: Translation.tr(tile.name.charAt(0).toUpperCase() + tile.name.slice(1))
        color: tile.selected ? AtollStyle.text : AtollStyle.subtext
        font.pixelSize: AtollStyle.typeFootnote
        font.weight: tile.selected ? Font.DemiBold : Font.Normal
    }
}
