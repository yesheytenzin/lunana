import "../../common"
import "../../common/widgets"
import QtQuick
import QtQuick.Layouts

GroupButton {
    id: button
    property string buttonIcon: ""
    property string buttonText: ""

    baseHeight: 36
    baseWidth: content.implicitWidth + 46
    clickedWidth: baseWidth + 6

    buttonRadius: Appearance.zzzEverywhere ? Appearance.zzz.controlRadius
        : Appearance.angelEverywhere ? Appearance.angel.roundingSmall
        : Appearance.lunanaEverywhere ? Appearance.lunana.roundingSmall
        : Appearance.editorialEverywhere ? Appearance.rounding.small : baseHeight / 2
    buttonRadiusPressed: Appearance.zzzEverywhere ? Appearance.zzz.cornerRadius
        : Appearance.angelEverywhere ? Appearance.angel.roundingSmall
        : Appearance.lunanaEverywhere ? Appearance.lunana.roundingSmall : Appearance.rounding.small
    colBackground: Appearance.zzzEverywhere ? "transparent"
        : Appearance.angelEverywhere ? Appearance.angel.colGlassCard
        : Appearance.lunanaEverywhere ? Appearance.lunana.colLayer2
        : Appearance.editorialEverywhere ? Appearance.editorial.layer(2)
        : Appearance.auroraEverywhere ? "transparent" : Appearance.colors.colLayer2
    colBackgroundHover: Appearance.zzzEverywhere ? Appearance.zzz.chrome
        : Appearance.angelEverywhere ? Appearance.angel.colGlassCardHover
        : Appearance.lunanaEverywhere ? Appearance.lunana.colLayer2Hover
        : Appearance.editorialEverywhere ? Appearance.editorial.field
        : Appearance.auroraEverywhere ? Appearance.aurora.colSubSurfaceHover : Appearance.colLayer2Hover
    colBackgroundActive: Appearance.zzzEverywhere ? Appearance.zzz.sticker
        : Appearance.angelEverywhere ? Appearance.angel.colGlassCardActive
        : Appearance.lunanaEverywhere ? Appearance.lunana.colLayer2Active
        : Appearance.auroraEverywhere ? Appearance.aurora.colSubSurfaceActive : Appearance.colLayer2Active
    property color colText: Appearance.zzzEverywhere
        ? (toggled ? Appearance.zzz.onSticker : Appearance.zzz.ink)
        : Appearance.lunanaEverywhere
        ? (toggled ? Appearance.lunana.colOnPrimaryContainer : Appearance.lunana.colText)
        : Appearance.editorialEverywhere
        ? (toggled ? Appearance.editorial.fieldInk : Appearance.editorial.ink)
        : (toggled ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer1)

    contentItem: Item {
        id: content
        anchors.fill: parent
        implicitWidth: contentRowLayout.implicitWidth
        implicitHeight: contentRowLayout.implicitHeight
        RowLayout {
            id: contentRowLayout
            anchors.centerIn: parent
            spacing: 5
            MaterialSymbol {
                visible: buttonIcon !== ""
                text: buttonIcon
                iconSize: Appearance.font.pixelSize.huge
                color: button.colText
            }
            StyledText {
                visible: buttonText !== ""
                text: buttonText
                font.pixelSize: Appearance.font.pixelSize.small
                color: button.colText
            }
        }
    }

}
