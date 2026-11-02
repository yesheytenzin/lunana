pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../../../common/widgets"
import "../../style"
import "../../components"

RowLayout {
    id: blockRow
    property string glyph: "circle"
    property string title: ""
    property string detail: ""
    Layout.fillWidth: true
    spacing: Math.round(12 * AtollStyle.density)
    Item {
        implicitWidth: Math.round(40 * AtollStyle.density)
        implicitHeight: implicitWidth
        Rectangle { anchors.fill: parent; radius: width / 2; color: AtollStyle.fill }
        MaterialSymbol { anchors.centerIn: parent; text: blockRow.glyph; fill: 1; iconSize: Math.round(20 * AtollStyle.density); color: AtollStyle.text }
    }
    ColumnLayout {
        Layout.fillWidth: true
        spacing: Math.round(1 * AtollStyle.density)
        AtollText { Layout.fillWidth: true; text: blockRow.title; font.weight: AtollStyle.weight(Font.DemiBold); elide: Text.ElideRight }
        AtollText { Layout.fillWidth: true; text: blockRow.detail; color: AtollStyle.muted; font.pixelSize: AtollStyle.typeMeta; elide: Text.ElideRight }
    }
}
