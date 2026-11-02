import QtQuick
import QtQuick.Layouts
import "../../common/widgets"
import "../style"

StyledText {
    id: root

    enum Role { Body, Meta, Eyebrow, Title, Display, Metric }
    property int role: AtollText.Body

    color: role === AtollText.Meta || role === AtollText.Eyebrow ? AtollStyle.subtext : AtollStyle.text
    defaultFont: (role === AtollText.Title || role === AtollText.Display)
        ? AtollStyle.fontTitle
        : role === AtollText.Metric ? AtollStyle.fontNumbers
        : AtollStyle.fontMain
    font.family: defaultFont
    font.pixelSize: role === AtollText.Meta ? AtollStyle.typeMeta
        : role === AtollText.Eyebrow ? AtollStyle.typeFootnote
        : role === AtollText.Title ? AtollStyle.typeTitle
        : role === AtollText.Display ? AtollStyle.typeDisplay
        : role === AtollText.Metric ? AtollStyle.typeTitleLarge : AtollStyle.typeBody
    font.weight: AtollStyle.weight(role === AtollText.Meta ? Font.Normal
        : role === AtollText.Eyebrow ? Font.DemiBold
        : role === AtollText.Title ? Font.DemiBold
        : role === AtollText.Display || role === AtollText.Metric ? Font.Bold : Font.Medium)
    font.letterSpacing: role === AtollText.Display ? AtollStyle.tracking(AtollStyle.typeDisplay)
        : role === AtollText.Metric ? AtollStyle.tracking(AtollStyle.typeTitleLarge) : 0
    font.variableAxes: ({})
    // Whole-pixel size: a text's fractional natural size puts every neighbour after it off the pixel grid.
    width: Math.ceil(implicitWidth)
    height: root.wrapMode === Text.NoWrap ? Math.ceil(root.implicitHeight) : root.implicitHeight
    Layout.preferredWidth: Math.ceil(implicitWidth)
    Layout.preferredHeight: root.wrapMode === Text.NoWrap ? Math.ceil(root.implicitHeight) : -1
    transform: Translate { x: Math.round(root.x) - root.x; y: Math.round(root.y) - root.y }
}
