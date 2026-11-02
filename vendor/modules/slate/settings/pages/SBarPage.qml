pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../../../services"
import "../../../common"
import "../../looks"
import ".."

SSettingsPage {
    id: root
    settingsPageIndex: 2
    pageTitle: Translation.tr("Taskbar")
    pageIcon: "desktop"
    pageDescription: Translation.tr("Taskbar appearance and behavior")
    
    property bool isSlateActive: Config.options?.panelFamily === "slate"
    
    SSettingsInfoBar {
        visible: !root.isSlateActive
        severity: SSettingsInfoBar.Severity.Info
        message: Translation.tr("These settings only apply when using the Slate (Slate) panel style. Go to Modules to enable it.")
    }
    
    SSettingsCard {
        visible: root.isSlateActive
        title: Translation.tr("Position & Layout")
        icon: "panel-left-expand"
        
        SSettingsSwitch {
            label: Translation.tr("Bottom position")
            icon: "caret-down"
            description: Translation.tr("Place taskbar at bottom of screen")
            checked: Config.options?.slate?.bar?.bottom ?? true
            onCheckedChanged: Config.setNestedValue("slate.bar.bottom", checked)
        }
        
        SSettingsSwitch {
            label: Translation.tr("Left-align apps")
            icon: "chevron-left"
            description: Translation.tr("Align taskbar apps to the left instead of center")
            checked: Config.options?.slate?.bar?.leftAlignApps ?? false
            onCheckedChanged: Config.setNestedValue("slate.bar.leftAlignApps", checked)
        }
    }
    
    SSettingsCard {
        visible: root.isSlateActive
        title: Translation.tr("Icons")
        icon: "apps"
        
        SSettingsSwitch {
            label: Translation.tr("Tint app icons")
            icon: "dark-theme"
            description: Translation.tr("Apply accent color to taskbar app icons")
            checked: Config.options?.slate?.bar?.monochromeIcons ?? false
            onCheckedChanged: Config.setNestedValue("slate.bar.monochromeIcons", checked)
        }
        
        SSettingsSwitch {
            label: Translation.tr("Tint tray icons")
            icon: "eyedropper"
            description: Translation.tr("Apply accent color to system tray icons")
            checked: Config.options?.slate?.bar?.tintTrayIcons ?? false
            onCheckedChanged: Config.setNestedValue("slate.bar.tintTrayIcons", checked)
        }

        SSettingsSpinBox {
            label: Translation.tr("Taskbar icon size")
            icon: "apps"
            suffix: "px"
            from: 20; to: 40; stepSize: 1
            value: Config.options?.slate?.bar?.iconSize ?? 26
            onValueChanged: Config.setNestedValue("slate.bar.iconSize", value)
        }

        SSettingsSpinBox {
            label: Translation.tr("Search app icon size")
            icon: "search"
            suffix: "px"
            from: 16; to: 40; stepSize: 1
            value: Config.options?.slate?.bar?.searchIconSize ?? 24
            onValueChanged: Config.setNestedValue("slate.bar.searchIconSize", value)
        }
    }
    
    SSettingsCard {
        visible: root.isSlateActive
        title: Translation.tr("Desktop Peek")
        icon: "eye"
        
        SSettingsSwitch {
            label: Translation.tr("Enable hover peek")
            icon: "eye"
            description: Translation.tr("Show desktop when hovering the corner button")
            checked: Config.options?.slate?.bar?.desktopPeek?.hoverPeek ?? false
            onCheckedChanged: Config.setNestedValue("slate.bar.desktopPeek.hoverPeek", checked)
        }
        
        SSettingsSpinBox {
            visible: Config.options?.slate?.bar?.desktopPeek?.hoverPeek ?? false
            label: Translation.tr("Hover delay")
            icon: "timer"
            suffix: "ms"
            from: 100; to: 2000; stepSize: 100
            value: Config.options?.slate?.bar?.desktopPeek?.hoverDelay ?? 500
            onValueChanged: Config.setNestedValue("slate.bar.desktopPeek.hoverDelay", value)
        }
    }
    
    SSettingsCard {
        visible: root.isSlateActive
        title: Translation.tr("Clock & Notifications")
        icon: "arrow-clockwise"
        
        SSettingsSwitch {
            label: Translation.tr("Show seconds")
            icon: "timer"
            description: Translation.tr("Display seconds in taskbar clock")
            checked: Config.options?.time?.secondPrecision ?? false
            onCheckedChanged: Config.setNestedValue("time.secondPrecision", checked)
        }
        
        SSettingsSwitch {
            label: Translation.tr("Show unread count")
            icon: "alert-filled"
            description: Translation.tr("Display notification count badge on clock")
            checked: Config.options?.slate?.bar?.notifications?.showUnreadCount ?? true
            onCheckedChanged: Config.setNestedValue("slate.bar.notifications.showUnreadCount", checked)
        }

        SSettingsSwitch {
            label: Translation.tr("Activation watermark")
            icon: "key"
            description: Translation.tr("Show a fake activation message on the taskbar")
            checked: Config.options?.slate?.bar?.activationWatermark?.enable ?? false
            onCheckedChanged: Config.setNestedValue("slate.bar.activationWatermark.enable", checked)
        }
    }
    
    SSettingsCard {
        visible: root.isSlateActive
        title: Translation.tr("Updates")
        icon: "arrow-sync"
        
        SSettingsSpinBox {
            label: Translation.tr("Check interval")
            icon: "arrow-clockwise"
            suffix: "m"
            from: 15; to: 1440; stepSize: 15
            value: Config.options?.updates?.checkInterval ?? 120
            onValueChanged: Config.setNestedValue("updates.checkInterval", value)
        }
        
        SSettingsSpinBox {
            label: Translation.tr("Show icon threshold")
            icon: "alert"
            description: Translation.tr("Show update icon when packages exceed this")
            from: 1; to: 200; stepSize: 5
            value: Config.options?.updates?.adviseUpdateThreshold ?? 10
            onValueChanged: Config.setNestedValue("updates.adviseUpdateThreshold", value)
        }
        
        SSettingsSpinBox {
            label: Translation.tr("Warning threshold")
            icon: "alert"
            description: Translation.tr("Show warning color when packages exceed this")
            from: 10; to: 500; stepSize: 10
            value: Config.options?.updates?.stronglyAdviseUpdateThreshold ?? 50
            onValueChanged: Config.setNestedValue("updates.stronglyAdviseUpdateThreshold", value)
        }
    }
}
