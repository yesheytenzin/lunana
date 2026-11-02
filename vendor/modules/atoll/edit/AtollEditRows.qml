pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../.."
import "../../../services"
import "../../common"
import "../style"
import "../components"
import "../settings"

// Option rows, grouped as Settings groups them: a caption over a raised plate of rows.
ColumnLayout {
    id: root

    property var specs: []
    // A group's title wears the colour of the area it belongs to; neutral where there is none.
    property color tint: AtollStyle.label
    readonly property real d: AtollStyle.density
    readonly property var groups: {
        Config.revision
        const out = []
        for (const spec of root.specs) {
            if (!AtollOptions.shown(spec)) continue
            const title = String(spec.group ?? "")
            if (out.length === 0 || out[out.length - 1].title !== title) {
                const occurrence = out.filter(group => group.title === title).length
                out.push({ title: title, modelKey: title + ":" + occurrence, rows: [] })
            }
            out[out.length - 1].rows.push(Object.assign({ modelKey: String(spec.path ?? spec.label) }, spec))
        }
        return out
    }

    spacing: Math.round(12 * root.d)

    Repeater {
        model: ScriptModel { objectProp: "modelKey"; values: root.groups }
        ColumnLayout {
            id: group
            required property var modelData
            Layout.fillWidth: true
            spacing: Math.round(6 * root.d)
            AtollText {
                visible: group.modelData.title.length > 0
                Layout.leftMargin: Math.round(12 * root.d)
                text: Translation.tr(group.modelData.title)
                color: root.tint
                font.family: AtollStyle.fontTitle
                font.pixelSize: AtollStyle.typeMeta
                font.weight: AtollStyle.weight(Font.DemiBold)
            }
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: plate.implicitHeight
                radius: AtollStyle.radiusTile
                color: AtollStyle.surfaceHigh
                ColumnLayout {
                    id: plate
                    anchors.left: parent.left
                    anchors.right: parent.right
                    spacing: 0
                    Repeater {
                        model: ScriptModel { objectProp: "modelKey"; values: group.modelData.rows }
                        AtollSetting {
                            required property var modelData
                            required property int index
                            Layout.fillWidth: true
                            spec: modelData
                            last: index === group.modelData.rows.length - 1
                        }
                    }
                }
            }
        }
    }
}
