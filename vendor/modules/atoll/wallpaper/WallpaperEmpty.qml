pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../../common/widgets"
import "../style"
import "../components"

ColumnLayout {
    id: root

    required property var picker
    readonly property bool shrug: root.picker.online && !root.picker.searching

    spacing: Math.round(6 * AtollStyle.density)

    MaterialSymbol {
        Layout.alignment: Qt.AlignHCenter
        visible: !root.shrug
        text: root.picker.emptyGlyph
        fill: 1
        iconSize: Math.round(30 * AtollStyle.density)
        color: AtollStyle.muted
    }
    AtollText {
        Layout.alignment: Qt.AlignHCenter
        visible: root.shrug
        text: "(´・ω・`)"
        color: AtollStyle.subtext
        font.pixelSize: 22 * AtollStyle.typeScale
    }
    AtollText {
        Layout.fillWidth: true
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        text: root.picker.emptyText
        color: AtollStyle.muted
    }
}
