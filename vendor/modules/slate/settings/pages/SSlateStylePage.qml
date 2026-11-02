pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import "../../../../services"
import "../../../../services/deferred"
import "../../../common"
import "../../looks"
import ".."

SSettingsPage {
    id: root
    settingsPageIndex: 8
    pageTitle: Translation.tr("Slate Style")
    pageIcon: "desktop"
    pageDescription: Translation.tr("Slate style customization")
    
    property bool isSlateActive: Config.options?.panelFamily === "slate"
    // Helper to check if a module is enabled
    function isPanelEnabled(panelId: string): bool {
        return (Config.options?.enabledPanels ?? []).includes(panelId)
    }

    function disabledModuleDescription(moduleName: string): string {
        return moduleName + " " + Translation.tr("is currently disabled in Modules. These settings will apply when you enable it.")
    }
    
    SSettingsInfoBar {
        visible: !root.isSlateActive
        severity: SSettingsInfoBar.Severity.Info
        message: Translation.tr("These settings only apply when using the Slate (Slate) panel style. Go to Modules to enable it.")
    }

    SSettingsSection {
        visible: root.isSlateActive
        title: Translation.tr("Window Management")
        icon: "apps"
    }

    SSettingsCard {
        visible: root.isSlateActive
        title: Translation.tr("Alt+Tab Switcher")
        icon: "apps"

        SSettingsDropdown {
            label: Translation.tr("Alt+Tab opens")
            icon: "keyboard"
            description: NiriKeybinds.altTabSource === "custom"
                ? Translation.tr("Alt+Tab is bound in your own Niri binds. Choosing here takes it over; your line stays as it is.")
                : Translation.tr("Niri's Recent Windows, or this switcher with the style below")
            currentValue: NiriKeybinds.altTabSource
            options: [
                { value: "niri", displayName: Translation.tr("Niri's Recent Windows") },
                { value: "lunana", displayName: Translation.tr("Lunana switcher") }
            ]
            onSelected: newValue => NiriKeybinds.setAltTabSource(newValue)
        }

        SSettingsDropdown {
            label: Translation.tr("Style")
            icon: "image"
            description: Translation.tr("Visual layout of the window switcher")
            currentValue: Config.options?.slate?.altSwitcher?.preset ?? "thumbnails"
            options: [
                { value: "thumbnails", displayName: Translation.tr("Thumbnails") },
                { value: "cards", displayName: Translation.tr("Cards") },
                { value: "compact", displayName: Translation.tr("Compact") },
                { value: "list", displayName: Translation.tr("List") },
                { value: "skew", displayName: Translation.tr("Skew previews") },
                { value: "none", displayName: Translation.tr("Disabled") }
            ]
            onSelected: newValue => {
                Config.setNestedValue("slate.altSwitcher.preset", newValue)
                Config.setNestedValue("slate.altSwitcher.noVisualUi", newValue === "none")
            }
        }
        
        SSettingsSwitch {
            label: Translation.tr("Quick switch")
            icon: "flash-on"
            description: Translation.tr("Single Alt+Tab switches instantly without UI")
            checked: Config.options?.slate?.altSwitcher?.quickSwitch ?? false
            onCheckedChanged: Config.setNestedValue("slate.altSwitcher.quickSwitch", checked)
        }

        SSettingsSwitch {
            label: Translation.tr("No visual UI")
            icon: "eye-off"
            description: Translation.tr("Switch windows without showing overlay")
            enabled: {
                const preset = Config.options?.slate?.altSwitcher?.preset ?? "thumbnails"
                return preset !== "skew" && preset !== "none"
            }
            checked: {
                const preset = Config.options?.slate?.altSwitcher?.preset ?? "thumbnails"
                if (preset === "none")
                    return true
                if (preset === "skew")
                    return false
                return Config.options?.slate?.altSwitcher?.noVisualUi ?? false
            }
            onCheckedChanged: Config.setNestedValue("slate.altSwitcher.noVisualUi", checked)
        }
        
        SSettingsSwitch {
            label: Translation.tr("Most recent first")
            icon: "arrow-counterclockwise"
            description: Translation.tr("Order windows by most recently used")
            checked: Config.options?.slate?.altSwitcher?.useMostRecentFirst ?? true
            onCheckedChanged: Config.setNestedValue("slate.altSwitcher.useMostRecentFirst", checked)
        }
        
        SSettingsSwitch {
            label: Translation.tr("Auto-hide")
            icon: "arrow-clockwise"
            description: Translation.tr("Hide after releasing Alt key")
            checked: Config.options?.slate?.altSwitcher?.autoHide ?? true
            onCheckedChanged: Config.setNestedValue("slate.altSwitcher.autoHide", checked)
        }
        
        SSettingsSpinBox {
            visible: Config.options?.slate?.altSwitcher?.autoHide ?? true
            label: Translation.tr("Auto-hide delay")
            icon: "arrow-clockwise"
            suffix: "ms"
            from: 100; to: 2000; stepSize: 100
            value: Config.options?.slate?.altSwitcher?.autoHideDelayMs ?? 500
            onValueChanged: Config.setNestedValue("slate.altSwitcher.autoHideDelayMs", value)
        }

        SSettingsSwitch {
            label: Translation.tr("Close on window focus")
            icon: "dismiss"
            checked: Config.options?.slate?.altSwitcher?.closeOnFocus ?? true
            onCheckedChanged: Config.setNestedValue("slate.altSwitcher.closeOnFocus", checked)
        }

        SSettingsSpinBox {
            visible: (Config.options?.slate?.altSwitcher?.preset ?? "thumbnails") === "thumbnails"
            label: Translation.tr("Thumbnail width")
            icon: "image-copy"
            suffix: "px"
            from: 150; to: 500; stepSize: 20
            value: Config.options?.slate?.altSwitcher?.thumbnailWidth ?? 280
            onValueChanged: Config.setNestedValue("slate.altSwitcher.thumbnailWidth", value)
        }

        SSettingsSpinBox {
            visible: (Config.options?.slate?.altSwitcher?.preset ?? "thumbnails") === "thumbnails"
            label: Translation.tr("Thumbnail height")
            icon: "image-copy"
            suffix: "px"
            from: 100; to: 400; stepSize: 20
            value: Config.options?.slate?.altSwitcher?.thumbnailHeight ?? 180
            onValueChanged: Config.setNestedValue("slate.altSwitcher.thumbnailHeight", value)
        }

        SSettingsSpinBox {
            label: Translation.tr("Background dim")
            icon: "dark-theme"
            description: Translation.tr("Scrim opacity behind the switcher")
            suffix: "%"
            from: 0; to: 100; stepSize: 5
            value: Math.round((Config.options?.slate?.altSwitcher?.scrimOpacity ?? 0.4) * 100)
            onValueChanged: Config.setNestedValue("slate.altSwitcher.scrimOpacity", value / 100.0)
        }

        SSettingsSwitch {
            label: Translation.tr("Show Niri overview while switching")
            icon: "open"
            description: Translation.tr("Open compositor overview alongside the switcher")
            checked: Config.options?.slate?.altSwitcher?.showOverviewWhileSwitching ?? false
            onCheckedChanged: Config.setNestedValue("slate.altSwitcher.showOverviewWhileSwitching", checked)
        }
    }
    
    SSettingsCard {
        visible: root.isSlateActive
        title: Translation.tr("Task View")
        icon: "task-view-dark"

        SSettingsRow {
            visible: !root.isPanelEnabled("slateTaskView")
            label: Translation.tr("Module currently disabled")
            icon: "info"
            description: root.disabledModuleDescription(Translation.tr("Task View"))
        }
        
        SSettingsDropdown {
            label: Translation.tr("View mode")
            icon: "task-view-dark"
            description: Translation.tr("Carousel shows desktops equally. Centered highlights the active one.")
            currentValue: Config.options?.slate?.taskView?.mode ?? "centered"
            options: [
                { value: "carousel", displayName: Translation.tr("Carousel") },
                { value: "centered", displayName: Translation.tr("Centered focus") }
            ]
            onSelected: newValue => Config.setNestedValue("slate.taskView.mode", newValue)
        }
        
        SSettingsSwitch {
            label: Translation.tr("Close on window select")
            icon: "dismiss"
            description: Translation.tr("Exit Task View when clicking a window")
            checked: Config.options?.slate?.taskView?.closeOnSelect ?? false
            onCheckedChanged: Config.setNestedValue("slate.taskView.closeOnSelect", checked)
        }
    }

    SSettingsSection {
        visible: root.isSlateActive
        title: Translation.tr("Behavior")
        icon: "settings"
    }

    SSettingsCard {
        visible: root.isSlateActive
        title: Translation.tr("Behavior")
        icon: "settings"
        
        SSettingsSwitch {
            label: Translation.tr("Allow multiple panels open")
            icon: "panel-left-expand"
            description: Translation.tr("Keep start menu open when opening action center")
            checked: Config.options?.slate?.behavior?.allowMultiplePanels ?? false
            onCheckedChanged: Config.setNestedValue("slate.behavior.allowMultiplePanels", checked)
        }
        
        SSettingsSwitch {
            label: Translation.tr("Smoother menu animations")
            icon: "wand"
            description: Translation.tr("Use smoother closing animations for popups")
            checked: Config.options?.slate?.tweaks?.smootherMenuAnimations ?? true
            onCheckedChanged: Config.setNestedValue("slate.tweaks.smootherMenuAnimations", checked)
        }

        SSettingsSwitch {
            label: Translation.tr("Switch handle position fix")
            icon: "settings"
            description: Translation.tr("Fix toggle switch handle alignment")
            checked: Config.options?.slate?.tweaks?.switchHandlePositionFix ?? true
            onCheckedChanged: Config.setNestedValue("slate.tweaks.switchHandlePositionFix", checked)
        }
    }

    SSettingsSection {
        visible: root.isSlateActive
        title: Translation.tr("Panels")
        icon: "panel-left-expand"
    }

    SSettingsCard {
        visible: root.isSlateActive
        title: Translation.tr("Start Menu")
        icon: "start-here"

        SSettingsRow {
            visible: !root.isPanelEnabled("slateStartMenu")
            label: Translation.tr("Module currently disabled")
            icon: "info"
            description: root.disabledModuleDescription(Translation.tr("Start Menu"))
        }

        SSettingsDropdown {
            label: Translation.tr("Size preset")
            icon: "options"
            description: Translation.tr("Choose the start menu size")
            currentValue: Config.options?.slate?.startMenu?.sizePreset ?? "normal"
            options: [
                { value: "mini", displayName: Translation.tr("Mini") },
                { value: "compact", displayName: Translation.tr("Compact") },
                { value: "normal", displayName: Translation.tr("Normal") },
                { value: "large", displayName: Translation.tr("Large") },
                { value: "wide", displayName: Translation.tr("Wide") }
            ]
            onSelected: newValue => Config.setNestedValue("slate.startMenu.sizePreset", newValue)
        }

        SSettingsSpinBox {
            label: Translation.tr("Text scale")
            icon: "auto"
            description: Translation.tr("Scale text in the start menu")
            suffix: "%"
            from: 80; to: 150; stepSize: 5
            value: Math.round((Config.options?.slate?.startMenu?.scale ?? 1.0) * 100)
            onValueChanged: Config.setNestedValue("slate.startMenu.scale", value / 100.0)
        }
    }

    SSettingsCard {
        title: Translation.tr("Family Transition")
        icon: "arrow-sync"

        SSettingsSwitch {
            label: Translation.tr("Animated transition")
            icon: "wand"
            description: Translation.tr("Smooth animated overlay when switching between panel families")
            checked: Config.options?.familyTransitionAnimation ?? true
            onCheckedChanged: Config.setNestedValue("familyTransitionAnimation", checked)
        }
    }
    
    SSettingsCard {
        visible: root.isSlateActive
        title: Translation.tr("Widgets Panel")
        icon: "apps"

        SSettingsRow {
            visible: !root.isPanelEnabled("slateWidgets")
            label: Translation.tr("Module currently disabled")
            icon: "info"
            description: root.disabledModuleDescription(Translation.tr("Widgets Panel"))
        }
        
        SSettingsSwitch {
            label: Translation.tr("Show date & time")
            icon: "schedule"
            description: Translation.tr("Display date and time widget")
            checked: Config.options?.slate?.widgetsPanel?.showDateTime ?? true
            onCheckedChanged: Config.setNestedValue("slate.widgetsPanel.showDateTime", checked)
        }
        
        SSettingsSwitch {
            label: Translation.tr("Show weather")
            icon: "weather-sunny"
            description: Translation.tr("Display weather conditions widget")
            checked: Config.options?.slate?.widgetsPanel?.showWeather ?? true
            onCheckedChanged: Config.setNestedValue("slate.widgetsPanel.showWeather", checked)
        }

        SSettingsSwitch {
            label: Translation.tr("Hide weather location")
            icon: "eye-off"
            description: Translation.tr("Hide the city/location name in the weather widget and taskbar button")
            checked: Config.options?.slate?.widgetsPanel?.weatherHideLocation ?? false
            onCheckedChanged: Config.setNestedValue("slate.widgetsPanel.weatherHideLocation", checked)
        }
        
        SSettingsSwitch {
            label: Translation.tr("Show system info")
            icon: "pulse"
            description: Translation.tr("Display CPU, RAM, and disk usage")
            checked: Config.options?.slate?.widgetsPanel?.showSystem ?? true
            onCheckedChanged: Config.setNestedValue("slate.widgetsPanel.showSystem", checked)
        }
        
        SSettingsSwitch {
            label: Translation.tr("Show media controls")
            icon: "music-note-2"
            description: Translation.tr("Display now playing and media controls")
            checked: Config.options?.slate?.widgetsPanel?.showMedia ?? true
            onCheckedChanged: Config.setNestedValue("slate.widgetsPanel.showMedia", checked)
        }
        
        SSettingsSwitch {
            label: Translation.tr("Show quick actions")
            icon: "flash-on"
            description: Translation.tr("Display quick action buttons")
            checked: Config.options?.slate?.widgetsPanel?.showQuickActions ?? true
            onCheckedChanged: Config.setNestedValue("slate.widgetsPanel.showQuickActions", checked)
        }

        SSettingsSwitch {
            visible: Config.options?.slate?.widgetsPanel?.showQuickActions ?? true
            label: Translation.tr("Files shortcut")
            icon: "folder"
            checked: Config.options?.slate?.widgetsPanel?.showFiles ?? true
            onCheckedChanged: Config.setNestedValue("slate.widgetsPanel.showFiles", checked)
        }

        SSettingsSwitch {
            visible: Config.options?.slate?.widgetsPanel?.showQuickActions ?? true
            label: Translation.tr("Terminal shortcut")
            icon: "terminal"
            checked: Config.options?.slate?.widgetsPanel?.showTerminal ?? true
            onCheckedChanged: Config.setNestedValue("slate.widgetsPanel.showTerminal", checked)
        }

        SSettingsSwitch {
            visible: Config.options?.slate?.widgetsPanel?.showQuickActions ?? true
            label: Translation.tr("Settings shortcut")
            icon: "settings"
            checked: Config.options?.slate?.widgetsPanel?.showSettings ?? true
            onCheckedChanged: Config.setNestedValue("slate.widgetsPanel.showSettings", checked)
        }

        SSettingsSwitch {
            visible: Config.options?.slate?.widgetsPanel?.showQuickActions ?? true
            label: Translation.tr("Wallpaper shortcut")
            icon: "image"
            checked: Config.options?.slate?.widgetsPanel?.showWallpaper ?? true
            onCheckedChanged: Config.setNestedValue("slate.widgetsPanel.showWallpaper", checked)
        }

        SSettingsSwitch {
            visible: Config.options?.slate?.widgetsPanel?.showQuickActions ?? true
            label: Translation.tr("Screenshot shortcut")
            icon: "screenshot"
            checked: Config.options?.slate?.widgetsPanel?.showScreenshot ?? true
            onCheckedChanged: Config.setNestedValue("slate.widgetsPanel.showScreenshot", checked)
        }

        SSettingsSwitch {
            visible: Config.options?.slate?.widgetsPanel?.showQuickActions ?? true
            label: Translation.tr("Screen Record shortcut")
            icon: "record"
            checked: Config.options?.slate?.widgetsPanel?.showScreenRecord ?? true
            onCheckedChanged: Config.setNestedValue("slate.widgetsPanel.showScreenRecord", checked)
        }

        SSettingsSwitch {
            visible: Config.options?.slate?.widgetsPanel?.showQuickActions ?? true
            label: Translation.tr("Session shortcut")
            icon: "power"
            checked: Config.options?.slate?.widgetsPanel?.showSession ?? true
            onCheckedChanged: Config.setNestedValue("slate.widgetsPanel.showSession", checked)
        }

        SSettingsSwitch {
            label: Translation.tr("Color Scheme selector")
            icon: "color"
            checked: Config.options?.slate?.widgetsPanel?.showColorScheme ?? true
            onCheckedChanged: Config.setNestedValue("slate.widgetsPanel.showColorScheme", checked)
        }
    }

    SSettingsSection {
        title: Translation.tr("Weather")
        icon: "weather-sunny"
    }
    
    // Weather configuration - shared with drift family
    SSettingsCard {
        title: Translation.tr("Weather")
        icon: "weather-sunny"
        
        SSettingsTextField {
            label: Translation.tr("City")
            icon: "globe-search"
            description: Translation.tr("Leave empty to auto-detect from IP")
            placeholderText: Translation.tr("e.g. Buenos Aires, London, Tokyo")
            text: Config.options?.bar?.weather?.city ?? ""
            onTextEdited: newText => Config.setNestedValue("bar.weather.city", newText)
        }
        
        SSettingsTextField {
            label: Translation.tr("Latitude")
            icon: "globe-search"
            description: Translation.tr("Manual latitude (overrides city). e.g. -34.6037")
            placeholderText: Translation.tr("e.g. -34.6037")
            text: {
                const v = Config.options?.bar?.weather?.manualLat ?? 0;
                return v !== 0 ? String(v) : "";
            }
            onTextEdited: newText => {
                const num = parseFloat(newText);
                Config.setNestedValue("bar.weather.manualLat", isNaN(num) ? 0 : num);
            }
        }
        
        SSettingsTextField {
            label: Translation.tr("Longitude")
            icon: "globe-search"
            description: Translation.tr("Manual longitude (overrides city). e.g. -58.3816")
            placeholderText: Translation.tr("e.g. -58.3816")
            text: {
                const v = Config.options?.bar?.weather?.manualLon ?? 0;
                return v !== 0 ? String(v) : "";
            }
            onTextEdited: newText => {
                const num = parseFloat(newText);
                Config.setNestedValue("bar.weather.manualLon", isNaN(num) ? 0 : num);
            }
        }
        
        SSettingsSwitch {
            label: Translation.tr("Use GPS location")
            icon: "globe-search"
            description: Translation.tr("Uses GPS when no manual location is set (requires geoclue)")
            checked: Config.options?.bar?.weather?.enableGPS ?? false
            onCheckedChanged: Config.setNestedValue("bar.weather.enableGPS", checked)
        }
        
        // Current detected location
        SSettingsRow {
            visible: Weather.location.valid
            label: Translation.tr("Detected location")
            icon: "globe-search"
            description: Weather.location.name || (Weather.location.lat + ", " + Weather.location.lon)
        }
        
        SSettingsSwitch {
            label: Translation.tr("Use Fahrenheit")
            icon: "weather-sunny"
            description: Translation.tr("Display temperature in °F instead of °C")
            checked: Config.options?.bar?.weather?.useUSCS ?? false
            onCheckedChanged: Config.setNestedValue("bar.weather.useUSCS", checked)
        }
        
        SSettingsSpinBox {
            label: Translation.tr("Update interval")
            icon: "arrow-sync"
            description: Translation.tr("How often to refresh weather data")
            suffix: " min"
            from: 5; to: 60; stepSize: 5
            value: Config.options?.bar?.weather?.fetchInterval ?? 10
            onValueChanged: Config.setNestedValue("bar.weather.fetchInterval", value)
        }
    }
    
    SSettingsCard {
        visible: root.isSlateActive
        title: Translation.tr("Calendar")
        icon: "news"

        SSettingsRow {
            visible: !root.isPanelEnabled("slateNotificationCenter")
            label: Translation.tr("Module currently disabled")
            icon: "info"
            description: root.disabledModuleDescription(Translation.tr("Calendar / Notification Center"))
        }
        
        SSettingsSwitch {
            label: Translation.tr("Force 2-char day names")
            icon: "news"
            description: Translation.tr("Use Mo, Tu, We instead of Mon, Tue, Wed")
            checked: Config.options?.slate?.calendar?.force2CharDayOfWeek ?? true
            onCheckedChanged: Config.setNestedValue("slate.calendar.force2CharDayOfWeek", checked)
        }
    }
}
