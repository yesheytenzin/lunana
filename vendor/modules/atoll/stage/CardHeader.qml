pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../../common/widgets"
import "../style"
import "../components"

RowLayout {
    id: header
    property string glyph: ""
    property string title: ""
    property string detail: ""
    property color tint: AtollStyle.accent
    default property alias actions: actionRow.data
    Layout.fillWidth: true
    spacing: 8 * AtollStyle.density
    Rectangle {
        implicitWidth: Math.round(24 * AtollStyle.density)
        implicitHeight: implicitWidth
        radius: AtollStyle.iconRadius(width)
        gradient: Gradient {
            GradientStop { position: 0; color: AtollStyle.tileTop(header.tint) }
            GradientStop { position: 1; color: header.tint }
        }
        MaterialSymbol { anchors.centerIn: parent; text: header.glyph; fill: 1; iconSize: Math.round(15 * AtollStyle.density); color: AtollStyle.onTint }
    }
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 0
        AtollText {
            Layout.fillWidth: true
            text: header.title
            font.weight: AtollStyle.weight(Font.DemiBold)
            font.pixelSize: AtollStyle.typeBody
            elide: Text.ElideRight
        }
        AtollText {
            Layout.fillWidth: true
            visible: text.length > 0
            text: header.detail
            role: AtollText.Meta
            elide: Text.ElideRight
        }
    }
    RowLayout { id: actionRow; spacing: 0 }
}
