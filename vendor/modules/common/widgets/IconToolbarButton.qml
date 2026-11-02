pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import ".."
import "../functions"

ToolbarButton {
    id: iconBtn
    implicitWidth: height
    property int iconRenderType: Text.NativeRendering
    property int iconSize: Appearance.regaliaEverywhere ? 18 : 22

    colBackgroundToggled: Appearance.regaliaEverywhere ? Appearance.regalia.primaryPlate
        : Appearance.zzzEverywhere ? Appearance.zzz.sticker
        : Appearance.angelEverywhere ? Appearance.angel.colGlassCard
        : Appearance.lunanaEverywhere ? Appearance.lunana.colSelection 
        : Appearance.auroraEverywhere ? Appearance.aurora.colElevatedSurface 
        : Appearance.colors.colSecondaryContainer
    colBackgroundToggledHover: Appearance.regaliaEverywhere ? Appearance.regalia.primaryPlateHover
        : Appearance.zzzEverywhere ? Appearance.colors.colPrimaryHover
        : Appearance.angelEverywhere ? Appearance.angel.colGlassCardHover
        : Appearance.lunanaEverywhere ? Appearance.lunana.colSelectionHover 
        : Appearance.auroraEverywhere ? Appearance.aurora.colElevatedSurfaceHover 
        : Appearance.colors.colSecondaryContainerHover
    colRippleToggled: Appearance.zzzEverywhere ? Appearance.colors.colPrimaryActive
        : Appearance.angelEverywhere ? Appearance.angel.colGlassCardActive
        : Appearance.lunanaEverywhere ? Appearance.lunana.colPrimaryActive 
        : Appearance.auroraEverywhere ? Appearance.aurora.colSubSurfaceActive 
        : Appearance.colors.colSecondaryContainerActive
    property color colText: toggled
        ? (Appearance.regaliaEverywhere ? Appearance.regalia.primaryPlateInk
            : Appearance.zzzEverywhere ? Appearance.zzz.onSticker
            : Appearance.lunanaEverywhere ? Appearance.lunana.colOnSelection : Appearance.colors.colOnSecondaryContainer)
        : (Appearance.regaliaEverywhere ? Appearance.regalia.onColor
            : Appearance.zzzEverywhere ? Appearance.zzz.ink
            : Appearance.lunanaEverywhere ? Appearance.lunana.colText : Appearance.colors.colOnSurfaceVariant)

    contentItem: MaterialSymbol {
        anchors.centerIn: parent
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        iconSize: iconBtn.iconSize
        text: iconBtn.text
        textRenderType: iconBtn.iconRenderType
        color: iconBtn.colText
    }
}
