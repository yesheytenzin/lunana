import "../../.."
import "../../../services"
import "../../common"
import "../../common/functions"
import "../../common/widgets"
import QtQuick
import QtQuick.Layouts
import Quickshell

import "classicStyle"

AbstractQuickPanel {
    id: root
    property bool compactMode: false
    property int compactItemSlotWidth: 48
    property int compactSpacing: 8
    
    implicitHeight: grid.implicitHeight
    Layout.fillWidth: true

    Grid {
        id: grid
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        
        // Approximate width of a toggle (40) + spacing
        property int itemSlotWidth: root.compactMode ? root.compactItemSlotWidth : 52
        columns: Math.max(1, Math.floor(root.width / itemSlotWidth))
        
        spacing: root.compactMode ? root.compactSpacing : 12
        
        NetworkToggle {
            altAction: () => root.openWifiDialog()
        }

        HotspotToggle {
            altAction: () => root.openHotspotDialog()
        }

        BluetoothToggle {
            altAction: () => root.openBluetoothDialog()
        }
        
        NightLight {
            altAction: () => root.openNightLightDialog()
        }
        
        EasyEffectsToggle {
            altAction: () => ShellExec.execDetachedArgs(["easyeffects"], "Open EasyEffects")
        }
        
        IdleInhibitor {}
        
        GameMode {}
        
        CloudflareWarp {}
    }
}
