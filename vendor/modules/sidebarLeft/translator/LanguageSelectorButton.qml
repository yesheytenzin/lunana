import "../../.."
import "../../../services"
import "../../common"
import "../../common/widgets"
import "../../common/functions"
import QtQuick
import QtQuick.Layouts

RippleButton {
    id: root
    property string displayText: ""
    colBackground: Appearance.angelEverywhere ? Appearance.angel.colGlassCard
        : Appearance.lunanaEverywhere ? Appearance.lunana.colLayer2 
        : Appearance.auroraEverywhere ? "transparent" : Appearance.colors.colLayer2
    colBackgroundHover: Appearance.angelEverywhere ? Appearance.angel.colGlassCardHover
        : Appearance.lunanaEverywhere ? Appearance.lunana.colLayer2Hover 
        : Appearance.auroraEverywhere ? Appearance.aurora.colSubSurfaceHover : Appearance.colLayer2Hover
    colRipple: Appearance.angelEverywhere ? Appearance.angel.colGlassCardActive
        : Appearance.lunanaEverywhere ? Appearance.lunana.colLayer2Active 
        : Appearance.auroraEverywhere ? Appearance.aurora.colSubSurfaceActive : Appearance.colLayer2Active
    buttonRadius: Appearance.angelEverywhere ? Appearance.angel.roundingSmall
        : Appearance.lunanaEverywhere ? Appearance.lunana.roundingSmall : Appearance.rounding.small

    implicitWidth: contentItem.implicitWidth + horizontalPadding * 2
    implicitHeight: contentItem.implicitHeight + verticalPadding * 2

    contentItem: Item {
        anchors.centerIn: parent
        implicitWidth: languageRow.implicitWidth
        implicitHeight: languageText.implicitHeight
        RowLayout {
            id: languageRow
            anchors.centerIn: parent
            spacing: 0
            StyledText {
                id: languageText
                Layout.alignment: Qt.AlignVCenter
                Layout.leftMargin: 5
                text: root.displayText
                color: Appearance.lunanaEverywhere ? Appearance.lunana.colText : Appearance.colors.colOnLayer2
                font.pixelSize: Appearance.font.pixelSize.small
            }
            MaterialSymbol {
                Layout.alignment: Qt.AlignVCenter
                iconSize: Appearance.font.pixelSize.hugeass
                text: "arrow_drop_down"
                color: Appearance.lunanaEverywhere ? Appearance.lunana.colText : Appearance.colors.colOnLayer2
            }
        }
    }
}
