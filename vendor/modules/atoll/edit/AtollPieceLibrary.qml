pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../.."
import "../../../services"
import "../../common"
import "../../common/widgets"
import "../style"
import "../components"
import "../pieces"
import "../frame"

// Every piece Atoll can place, one tile each. A tile carries its own state: lit when the piece is on
// screen. Tap to add or take it away; carry it on screen to place it.
ColumnLayout {
    id: root

    readonly property real d: AtollStyle.density
    readonly property var extras: AtollPieces.extras.filter(extra => !AtollFrame.announcements.includes(extra.id))
    readonly property int onCount: {
        Config.revision
        return root.extras.filter(extra => root.isOn(extra.id)).length
    }
    function isOn(id: string): bool {
        return Config.options?.atoll?.bubbles?.extras?.[id]?.enable ?? false
    }
    function toggle(id: string): void {
        Config.setNestedValue("atoll.bubbles.extras." + id + ".enable", !root.isOn(id))
    }
    function glyphOf(kind: string): string {
        const chosen = AtollPieces.chosenGlyph(kind)
        if (chosen.length > 0) return chosen
        return ({ weather: "wb_sunny", notifications: "notifications", controls: "tune", sound: "volume_up", mic: "mic",
            tools: "timer", media: "play_circle", visualizer: "graphic_eq", tray: "widgets", calendar: "calendar_month", clock: "schedule",
            battery: "battery_full", focus: "bedtime", network: "wifi", bluetooth: "bluetooth", vitals: "monitoring",
            workspaces: "grid_view", updates: "deployed_code_update", shellUpdate: "rocket_launch", vpn: "vpn_lock",
            anime: AtollPieces.glyphOf("anime", ""), watching: AtollPieces.glyphOf("watching", "") })[kind] ?? "circle"
    }

    spacing: Math.round(10 * root.d)

    AtollText {
        Layout.fillWidth: true
        text: root.onCount === 1 ? Translation.tr("1 piece on screen. Tap one to add it or take it away; carry it on screen to place it.")
            : Translation.tr("%1 pieces on screen. Tap one to add it or take it away; carry it on screen to place it.").arg(root.onCount)
        color: AtollStyle.textSecondary
        font.pixelSize: AtollStyle.typeMeta
        wrapMode: Text.WordWrap
    }

    GridLayout {
        id: grid
        Layout.fillWidth: true
        readonly property real cell: Math.round(70 * root.d)
        columns: Math.max(4, Math.floor((width + columnSpacing) / (grid.cell + columnSpacing)))
        columnSpacing: Math.round(4 * root.d)
        rowSpacing: Math.round(8 * root.d)

        Repeater {
            model: root.extras
            Item {
                id: tile
                required property var modelData
                readonly property bool on: { Config.revision; return root.isOn(tile.modelData.id) }
                readonly property bool ready: AtollPieces.available(tile.modelData.id)
                Layout.fillWidth: true
                Layout.preferredHeight: face.height + name.implicitHeight + Math.round(6 * root.d)
                opacity: tile.ready ? 1 : 0.45

                Rectangle {
                    id: face
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: Math.round(42 * root.d)
                    height: width
                    radius: AtollStyle.iconRadius(width)
                    color: tile.on ? AtollStyle.tintFill(AtollStyle.accent)
                        : area.containsMouse ? AtollStyle.fillHover : AtollStyle.fillQuiet
                    border.width: tile.on ? 1 : 0
                    border.color: AtollStyle.tintBorder(AtollStyle.accent)
                    scale: area.pressed ? AtollStyle.pressScale(0.9) : area.containsMouse ? 1.04 : 1
                    Behavior on color { ColorAnimation { duration: AtollStyle.feedbackDuration; easing.type: AtollStyle.feedbackEasing } }
                    Behavior on scale { NumberAnimation { duration: AtollStyle.feedbackDuration; easing.type: AtollStyle.feedbackEasing } }
                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: root.glyphOf(tile.modelData.id)
                        fill: tile.on ? 1 : 0
                        iconSize: Math.round(20 * root.d)
                        color: tile.on ? AtollStyle.accent : AtollStyle.text
                    }
                }
                AtollText {
                    id: name
                    anchors.top: face.bottom
                    anchors.topMargin: Math.round(5 * root.d)
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: Translation.tr(tile.modelData.label)
                    color: tile.on ? AtollStyle.text : AtollStyle.muted
                    font.pixelSize: AtollStyle.typeFootnote
                    wrapMode: Text.WordWrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                }
                MouseArea {
                    id: area
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: tile.ready
                    cursorShape: Qt.PointingHandCursor
                    Accessible.role: Accessible.CheckBox
                    Accessible.name: tile.modelData.label
                    Accessible.checked: tile.on
                    onClicked: root.toggle(tile.modelData.id)
                }
            }
        }
    }
}
