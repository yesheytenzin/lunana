import QtQuick
import Quickshell
import ".."
import "../functions"
import "."

StyledText {
    text: "Dialog Title"
    color: Appearance.colors.colOnSurface
    wrapMode: Text.Wrap
    font {
        family: Appearance.font.family.title
        pixelSize: Appearance.font.pixelSize.title
        variableAxes: Appearance.editorialEverywhere ? ({}) : Appearance.font.variableAxes.title
        weight: Appearance.editorialEverywhere ? Appearance.editorial.titleWeight : Font.Normal
        letterSpacing: Appearance.editorialEverywhere ? Appearance.editorial.titleTracking : 0
    }
}
