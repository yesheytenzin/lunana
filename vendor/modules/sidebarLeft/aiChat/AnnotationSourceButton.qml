import "../../.."
import "../../common"
import "../../common/widgets"
import "../../common/functions"
import "../../../services"
import QtQuick
import QtQuick.Layouts

RippleButton {
    id: root
    property string displayText
    property string url

    property real faviconSize: 20
    implicitHeight: 30
    leftPadding: (implicitHeight - faviconSize) / 2
    rightPadding: 10
    buttonRadius: Appearance.editorialEverywhere ? Appearance.rounding.small : Appearance.angelEverywhere ? Appearance.angel.roundingSmall
        : Appearance.lunanaEverywhere ? Appearance.lunana.roundingSmall : Appearance.rounding.full
    colBackground: Appearance.editorialEverywhere ? Appearance.editorial.tertiaryField : Appearance.angelEverywhere ? Appearance.angel.colGlassCard
        : Appearance.lunanaEverywhere ? Appearance.lunana.colLayer2 
        : Appearance.auroraEverywhere ? "transparent" : Appearance.colors.colSurfaceContainerHighest
    colBackgroundHover: Appearance.angelEverywhere ? Appearance.angel.colGlassCardHover
        : Appearance.lunanaEverywhere ? Appearance.lunana.colLayer2Hover 
        : Appearance.auroraEverywhere ? Appearance.aurora.colSubSurfaceHover : Appearance.colors.colSurfaceContainerHighestHover
    colRipple: Appearance.angelEverywhere ? Appearance.angel.colGlassCardActive
        : Appearance.lunanaEverywhere ? Appearance.lunana.colLayer2Active 
        : Appearance.auroraEverywhere ? Appearance.aurora.colSubSurfaceActive : Appearance.colors.colSurfaceContainerHighestActive

    PointingHandInteraction {}
    onClicked: {
        if (url) {
            Qt.openUrlExternally(url)
            GlobalStates.sidebarLeftOpen = false
        }
    }

    contentItem: Item {
        anchors.centerIn: parent
        implicitWidth: rowLayout.implicitWidth
        implicitHeight: rowLayout.implicitHeight
        RowLayout {
            id: rowLayout
            anchors.fill: parent
            spacing: 5
            Favicon {
                url: root.url
                size: root.faviconSize
                displayText: root.displayText
            }
            StyledText {
                id: text
                horizontalAlignment: Text.AlignHCenter
                text: displayText
                color: Appearance.editorialEverywhere ? Appearance.editorial.tertiaryFieldInk : Appearance.lunanaEverywhere ? Appearance.lunana.colText : Appearance.colors.colOnSurface
            }
        }
    }
}
