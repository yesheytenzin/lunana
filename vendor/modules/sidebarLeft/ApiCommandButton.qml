import "../common"
import "../common/widgets"
import QtQuick

GroupButton {
    id: button
    property string buttonText

    horizontalPadding: 8
    verticalPadding: 6

    baseWidth: contentItem.implicitWidth + horizontalPadding * 2
    clickedWidth: baseWidth + 14
    baseHeight: contentItem.implicitHeight + verticalPadding * 2
    buttonRadius: down ? (Appearance.lunanaEverywhere ? Appearance.lunana.roundingSmall : Appearance.rounding.verysmall) : (Appearance.lunanaEverywhere ? Appearance.lunana.roundingNormal : Appearance.rounding.small)

    colBackground: Appearance.angelEverywhere ? Appearance.angel.colGlassCard
        : Appearance.lunanaEverywhere ? Appearance.lunana.colLayer2 
        : Appearance.auroraEverywhere ? "transparent" : Appearance.colors.colLayer2
    colBackgroundHover: Appearance.angelEverywhere ? Appearance.angel.colGlassCardHover
        : Appearance.lunanaEverywhere ? Appearance.lunana.colLayer2Hover 
        : Appearance.auroraEverywhere ? Appearance.aurora.colSubSurfaceHover : Appearance.colLayer2Hover
    colBackgroundActive: Appearance.angelEverywhere ? Appearance.angel.colGlassCardActive
        : Appearance.lunanaEverywhere ? Appearance.lunana.colLayer2Active 
        : Appearance.auroraEverywhere ? Appearance.aurora.colSubSurfaceActive : Appearance.colLayer2Active

    contentItem: StyledText {
        horizontalAlignment: Text.AlignHCenter
        text: buttonText
        color: Appearance.lunanaEverywhere ? Appearance.lunana.colText : Appearance.colors.colOnSurface
    }
}