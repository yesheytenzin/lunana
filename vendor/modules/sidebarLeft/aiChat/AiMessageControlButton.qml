import "../../common"
import "../../common/widgets"
import "../../../services"
import QtQuick

GroupButton {
    id: button
    property string buttonIcon
    property bool activated: false
    toggled: activated
    baseWidth: height
    colBackgroundHover: Appearance.angelEverywhere ? Appearance.angel.colGlassCardHover
        : Appearance.lunanaEverywhere ? Appearance.lunana.colLayer2Hover
        : Appearance.auroraEverywhere ? Appearance.aurora.colSubSurfaceHover
        : Appearance.zzzEverywhere ? Appearance.colLayer1Hover : Appearance.colors.colSecondaryContainerHover
    colBackgroundActive: Appearance.angelEverywhere ? Appearance.angel.colGlassCardActive
        : Appearance.lunanaEverywhere ? Appearance.lunana.colLayer2Active
        : Appearance.auroraEverywhere ? Appearance.aurora.colSubSurfaceActive
        : Appearance.zzzEverywhere ? Appearance.colLayer1Active : Appearance.colors.colSecondaryContainerActive

    contentItem: MaterialSymbol {
        horizontalAlignment: Text.AlignHCenter
        iconSize: Appearance.font.pixelSize.larger
        text: buttonIcon
        color: button.activated ? (Appearance.lunanaEverywhere ? Appearance.lunana.colOnPrimary : Appearance.colors.colOnPrimary) :
            button.enabled ? (Appearance.lunanaEverywhere ? Appearance.lunana.colText : Appearance.colors.colOnSurface) :
            (Appearance.lunanaEverywhere ? Appearance.lunana.colTextDisabled : Appearance.colors.colOnLayer1Inactive)

        Behavior on color {
            enabled: Appearance.animationsEnabled
            animation: ColorAnimation { duration: Appearance.animation.elementMoveFast.duration; easing.type: Appearance.animation.elementMoveFast.type; easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve }
        }
    }
}
