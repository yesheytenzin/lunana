pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../../../common/widgets"
import "../../style"
import "../../components"

Rectangle {
    id: off
    property string text: ""
    anchors.centerIn: parent
    implicitWidth: offRow.implicitWidth + Math.round(28 * AtollStyle.density)
    implicitHeight: Math.round(36 * AtollStyle.density)
    radius: height / 2
    color: AtollStyle.veilHeavy
    border.width: 1
    border.color: AtollStyle.border
    RowLayout {
        id: offRow
        anchors.centerIn: parent
        spacing: Math.round(8 * AtollStyle.density)
        MaterialSymbol { text: "visibility_off"; iconSize: Math.round(16 * AtollStyle.density); color: AtollStyle.subtext }
        AtollText { text: off.text; font.weight: AtollStyle.weight(Font.DemiBold) }
    }
}
