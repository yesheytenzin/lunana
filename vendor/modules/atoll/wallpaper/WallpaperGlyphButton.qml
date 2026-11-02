pragma ComponentBehavior: Bound

import QtQuick
import "../../common/widgets"
import "../style"
import "../components"

AtollButton {
    id: root
    property string glyph: ""
    readonly property real d: AtollStyle.density
    quiet: true
    implicitWidth: Math.round(34 * root.d)
    implicitHeight: implicitWidth
    buttonRadius: height / 2
    buttonRadiusPressed: height / 2
    colBackground: AtollStyle.fillQuiet
    colBackgroundHover: AtollStyle.fillHover
    MaterialSymbol {
        anchors.centerIn: parent
        text: root.glyph
        fill: 1
        iconSize: Math.round(17 * root.d)
        color: !root.enabled ? AtollStyle.muted : root.selected ? AtollStyle.accent : AtollStyle.text
    }
}
