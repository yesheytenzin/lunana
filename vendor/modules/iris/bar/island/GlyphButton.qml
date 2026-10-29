pragma ComponentBehavior: Bound

import QtQuick
import "../../../../services"
import "../../../common"
import "../../../common/widgets"
import "../../style"
import "../../components"

IrisButton {
    id: glyphButton
    property string glyph: ""
    property real glyphSize: 22 * IrisStyle.density
    property color glyphColor: glyphButton.emphasized && glyphButton.danger ? IrisStyle.inkOnDanger : IrisStyle.text
    quiet: !glyphButton.emphasized
    implicitWidth: Math.round(38 * IrisStyle.density)
    implicitHeight: implicitWidth
    buttonRadius: height / 2
    buttonRadiusPressed: height / 2
    Glyph {
        anchors.centerIn: parent
        text: glyphButton.glyph
        iconSize: glyphButton.glyphSize
        color: glyphButton.enabled ? glyphButton.glyphColor : IrisStyle.muted
    }
}
