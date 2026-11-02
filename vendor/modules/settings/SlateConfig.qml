import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../services"
import "../../services/deferred"
import "../common"
import "../common/widgets"
import "../common/functions"

ContentPage {
    id: root
    settingsPageIndex: 11
    settingsPageName: Translation.tr("Slate Style")

    property bool isSlateActive: Config.options?.panelFamily === "slate"

    // Helper to check if a module is enabled
    function isPanelEnabled(panelId: string): bool {
        return Config.options?.enabledPanels?.includes(panelId) ?? false
    }

    SettingsCardSection {
        visible: !root.isSlateActive
        expanded: true
        icon: "info"
        title: Translation.tr("Not Active")

        SettingsGroup {
            StyledText {
                Layout.fillWidth: true
                text: Translation.tr("These settings only apply when using the Slate (Slate) panel style. Go to Modules → Panel Style to enable it.")
                color: Appearance.colors.colSubtext
                font.pixelSize: Appearance.font.pixelSize.small
                wrapMode: Text.WordWrap
            }
        }
    }

    // Wallpaper section
    // Wallpaper section
    property string activeSection: "wallpaper"

    SettingsTaskNavigator {
        icon: "window"
        title: Translation.tr("Slate Style")
        description: Translation.tr("Tune the Slate style surfaces in focused views: wallpaper, taskbar, theming and family switching.")
        summary: Translation.tr("Wallpaper \u00b7 Taskbar \u00b7 Style \u00b7 Transition")
        currentValue: root.activeSection
        onSelected: value => root.activeSection = value
        options: [
            { displayName: Translation.tr("Wallpaper"), icon: "wallpaper_slideshow", value: "wallpaper" },
            { displayName: Translation.tr("Taskbar"), icon: "toolbar", value: "taskbar" },
            { displayName: Translation.tr("Style"), icon: "palette", value: "style" },
            { displayName: Translation.tr("Transition"), icon: "swap_horiz", value: "transition" }
        ]
    }

    SettingsTaskLoader {
        requested: root.isSlateActive && root.isPanelEnabled("slateBackground") && root.activeSection === "wallpaper"
        sourceComponent: Component {
    SettingsCardSection {
        settingsTaskSection: "wallpaper"
        expanded: true
        title: Translation.tr("Wallpaper")

        SettingsGroup {
            SettingsSwitch {
                buttonIcon: "link"
                text: Translation.tr("Use main wallpaper")
                checked: Config.options?.slate?.background?.useMainWallpaper ?? true
                onCheckedChanged: {
                    Config.setNestedValue("slate.background.useMainWallpaper", checked);
                    if (checked) Config.setNestedValue("slate.background.wallpaperPath", "");
                }
                StyledToolTip { text: Translation.tr("Share wallpaper with Material drift style") }
            }

            RippleButtonWithIcon {
                visible: Config.options?.slate?.background?.useMainWallpaper ?? true
                Layout.fillWidth: true
                buttonRadius: Appearance.rounding.small
                materialIcon: "wallpaper"
                mainText: Translation.tr("Pick main wallpaper")
                onClicked: {
                    Config.setNestedValue("wallpaperSelector.selectionTarget", "main")
                    Quickshell.execDetached([((Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")) + "/omarchy/lunana-vendor/" + ("scripts/lunana")), "wallpaperSelector", "toggle"]);
                }
            }

            RippleButtonWithIcon {
                visible: !(Config.options?.slate?.background?.useMainWallpaper ?? true)
                Layout.fillWidth: true
                buttonRadius: Appearance.rounding.small
                materialIcon: "wallpaper"
                mainText: Translation.tr("Pick Slate wallpaper")
                onClicked: {
                    Config.setNestedValue("wallpaperSelector.selectionTarget", "slate")
                    Quickshell.execDetached([((Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")) + "/omarchy/lunana-vendor/" + ("scripts/lunana")), "wallpaperSelector", "toggle"]);
                }
            }

            SettingsSwitch {
                buttonIcon: "fullscreen_exit"
                text: Translation.tr("Hide main wallpaper in fullscreen")
                checked: Config.options?.slate?.background?.hideWhenFullscreen ?? true
                onCheckedChanged: Config.setNestedValue("slate.background.hideWhenFullscreen", checked)
                StyledToolTip {
                    text: Translation.tr("Hide the Slate main wallpaper during fullscreen. The Task View backdrop remains available.")
                }
            }
            
            SettingsSwitch {
                buttonIcon: "play_circle"
                text: Translation.tr("Enable animated wallpapers (videos/GIFs)")
                checked: Config.options?.slate?.background?.enableAnimation ?? true
                onCheckedChanged: {
                    Config.setNestedValue("slate.background.enableAnimation", checked);
                }
                StyledToolTip {
                    text: Translation.tr("Play videos and GIFs as wallpaper. When disabled, shows thumbnail instead (better performance)")
                }
            }
        }
    }
        }
    }

    SettingsTaskLoader {
        requested: root.isSlateActive && root.isPanelEnabled("slateBackground") && root.activeSection === "wallpaper"
        sourceComponent: Component {
    SettingsCardSection {
        settingsTaskSection: "wallpaper"
        expanded: true
        title: Translation.tr("Wallpaper Effects")

        SettingsGroup {
            SettingsSwitch {
                buttonIcon: "blur_on"
                text: Translation.tr("Enable blur")
                checked: Config.options?.slate?.background?.effects?.enableBlur ?? false
                onCheckedChanged: Config.setNestedValue("slate.background.effects.enableBlur", checked)
            }

            ConfigSpinBox {
                visible: Config.options?.slate?.background?.effects?.enableBlur ?? false
                icon: "blur_medium"
                text: Translation.tr("Blur radius")
                from: 0; to: 64; stepSize: 2
                value: Config.options?.slate?.background?.effects?.blurRadius ?? 32
                onValueChanged: Config.setNestedValue("slate.background.effects.blurRadius", value)
            }

            ConfigSpinBox {
                icon: "brightness_5"
                text: Translation.tr("Dim (%)")
                from: 0; to: 100; stepSize: 5
                value: Config.options?.slate?.background?.effects?.dim ?? 0
                onValueChanged: Config.setNestedValue("slate.background.effects.dim", value)
            }

            ConfigSpinBox {
                icon: "brightness_auto"
                text: Translation.tr("Dynamic dim (%)")
                from: 0; to: 100; stepSize: 5
                value: Config.options?.slate?.background?.effects?.dynamicDim ?? 0
                onValueChanged: Config.setNestedValue("slate.background.effects.dynamicDim", value)
                StyledToolTip { text: Translation.tr("Extra dim when windows are present on current workspace") }
            }
        }
    }
        }
    }

    SettingsTaskLoader {
        requested: root.isSlateActive && root.activeSection === "wallpaper"
        sourceComponent: Component {
    SettingsCardSection {
        settingsTaskSection: "wallpaper"
        expanded: true
        title: Translation.tr("Backdrop (Niri Overview)")

        SettingsGroup {
            StyledText {
                Layout.fillWidth: true
                text: Translation.tr("Backdrop is the wallpaper shown during Niri's native overview (Mod+Tab). It's always rendered in the background layer.")
                color: Appearance.colors.colSubtext
                font.pixelSize: Appearance.font.pixelSize.small
                wrapMode: Text.WordWrap
            }

            SettingsSwitch {
                buttonIcon: "texture"
                text: Translation.tr("Enable backdrop layer for overview")
                checked: Config.options?.slate?.background?.backdrop?.enable ?? true
                onCheckedChanged: {
                    Config.setNestedValue("slate.background.backdrop.enable", checked)
                }
            }

            SettingsSwitch {
                visible: Config.options?.slate?.background?.backdrop?.enable ?? true
                buttonIcon: "play_circle"
                text: Translation.tr("Enable animated wallpapers (videos/GIFs)")
                checked: Config.options?.slate?.background?.backdrop?.enableAnimation ?? false
                onCheckedChanged: {
                    Config.setNestedValue("slate.background.backdrop.enableAnimation", checked);
                }
                StyledToolTip {
                    text: Translation.tr("Play videos and GIFs in backdrop (may impact performance)")
                }
            }

            SettingsSwitch {
                visible: Config.options?.slate?.background?.backdrop?.enable ?? true
                buttonIcon: "visibility_off"
                text: Translation.tr("Hide main wallpaper (show only backdrop)")
                checked: Config.options?.slate?.background?.backdrop?.hideWallpaper ?? false
                onCheckedChanged: {
                    Config.setNestedValue("slate.background.backdrop.hideWallpaper", checked);
                }
                StyledToolTip { text: Translation.tr("Hides the desktop wallpaper, showing only the backdrop during Niri's overview") }
            }

            SettingsSwitch {
                visible: Config.options?.slate?.background?.backdrop?.enable ?? true
                buttonIcon: "link"
                text: Translation.tr("Use main wallpaper")
                checked: Config.options?.slate?.background?.backdrop?.useMainWallpaper ?? true
                onCheckedChanged: {
                    Config.setNestedValue("slate.background.backdrop.useMainWallpaper", checked)
                    if (checked) Config.setNestedValue("slate.background.backdrop.wallpaperPath", "")
                }
            }

            RippleButtonWithIcon {
                visible: (Config.options?.slate?.background?.backdrop?.enable ?? true) && !(Config.options?.slate?.background?.backdrop?.useMainWallpaper ?? true)
                Layout.fillWidth: true
                buttonRadius: Appearance.rounding.small
                materialIcon: "wallpaper"
                mainText: Translation.tr("Pick backdrop wallpaper")
                onClicked: {
                    Config.setNestedValue("wallpaperSelector.selectionTarget", "slate-backdrop")
                    Quickshell.execDetached([((Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")) + "/omarchy/lunana-vendor/" + ("scripts/lunana")), "wallpaperSelector", "toggle"]);
                }
            }

            ConfigSpinBox {
                visible: Config.options?.slate?.background?.backdrop?.enable ?? true
                icon: "blur_on"
                text: Translation.tr("Blur radius")
                from: 0; to: 100; stepSize: 5
                value: Config.options?.slate?.background?.backdrop?.blurRadius ?? 32
                onValueChanged: Config.setNestedValue("slate.background.backdrop.blurRadius", value)
            }

            ConfigSpinBox {
                visible: Config.options?.slate?.background?.backdrop?.enable ?? true
                icon: "brightness_5"
                text: Translation.tr("Dim (%)")
                from: 0; to: 100; stepSize: 5
                value: Config.options?.slate?.background?.backdrop?.dim ?? 35
                onValueChanged: Config.setNestedValue("slate.background.backdrop.dim", value)
            }

            ConfigSpinBox {
                visible: Config.options?.slate?.background?.backdrop?.enable ?? true
                icon: "contrast"
                text: Translation.tr("Saturation")
                from: 0; to: 200; stepSize: 10
                value: Math.round((Config.options?.slate?.background?.backdrop?.saturation ?? 1.0) * 100)
                onValueChanged: Config.setNestedValue("slate.background.backdrop.saturation", value / 100.0)
            }

            ConfigSpinBox {
                visible: Config.options?.slate?.background?.backdrop?.enable ?? true
                icon: "exposure"
                text: Translation.tr("Contrast")
                from: 0; to: 200; stepSize: 10
                value: Math.round((Config.options?.slate?.background?.backdrop?.contrast ?? 1.0) * 100)
                onValueChanged: Config.setNestedValue("slate.background.backdrop.contrast", value / 100.0)
            }

            SettingsSwitch {
                visible: Config.options?.slate?.background?.backdrop?.enable ?? true
                buttonIcon: "vignette"
                text: Translation.tr("Vignette")
                checked: Config.options?.slate?.background?.backdrop?.vignetteEnabled ?? false
                onCheckedChanged: Config.setNestedValue("slate.background.backdrop.vignetteEnabled", checked)
            }

            ConfigSpinBox {
                visible: (Config.options?.slate?.background?.backdrop?.enable ?? true) && (Config.options?.slate?.background?.backdrop?.vignetteEnabled ?? false)
                icon: "opacity"
                text: Translation.tr("Vignette intensity")
                from: 0; to: 100; stepSize: 5
                value: Math.round((Config.options?.slate?.background?.backdrop?.vignetteIntensity ?? 0.5) * 100)
                onValueChanged: Config.setNestedValue("slate.background.backdrop.vignetteIntensity", value / 100.0)
            }
        }
    }
        }
    }

    SettingsTaskLoader {
        requested: root.isSlateActive && root.isPanelEnabled("slateBar") && root.activeSection === "taskbar"
        sourceComponent: Component {
    SettingsCardSection {
        settingsTaskSection: "taskbar"
        expanded: true
        title: Translation.tr("Taskbar")

        SettingsGroup {
            SettingsSwitch {
                buttonIcon: "vertical_align_bottom"
                text: Translation.tr("Bottom position")
                checked: Config.options?.slate?.bar?.bottom ?? true
                onCheckedChanged: Config.setNestedValue("slate.bar.bottom", checked)
            }

            SettingsSwitch {
                buttonIcon: "format_align_left"
                text: Translation.tr("Left-align apps")
                checked: Config.options?.slate?.bar?.leftAlignApps ?? false
                onCheckedChanged: Config.setNestedValue("slate.bar.leftAlignApps", checked)
            }

            SettingsSwitch {
                buttonIcon: "palette"
                text: Translation.tr("Tint app icons")
                checked: Config.options?.slate?.bar?.monochromeIcons ?? false
                onCheckedChanged: Config.setNestedValue("slate.bar.monochromeIcons", checked)
            }

            SettingsSwitch {
                buttonIcon: "palette"
                text: Translation.tr("Tint tray icons")
                checked: Config.options?.slate?.bar?.tintTrayIcons ?? false
                onCheckedChanged: Config.setNestedValue("slate.bar.tintTrayIcons", checked)
            }
        }
    }
        }
    }

    SettingsTaskLoader {
        requested: root.isSlateActive && root.activeSection === "style"
        sourceComponent: Component {
    SettingsCardSection {
        id: themingSection
        settingsTaskSection: "style"
        expanded: true
        title: Translation.tr("Theming")

        property string currentFontFamily: Config.options?.slate?.theming?.font?.family ?? "Noto Sans"
        property string defaultFont: "Noto Sans"

        SettingsGroup {
            SettingsSwitch {
                buttonIcon: "format_color_fill"
                text: Translation.tr("Use Material colors")
                enabled: !Appearance.editorialEverywhere
                checked: Appearance.editorialEverywhere || (Config.options?.slate?.theming?.useMaterialColors ?? false)
                onCheckedChanged: {
                    if (!Appearance.editorialEverywhere) Config.setNestedValue("slate.theming.useMaterialColors", checked)
                }
                StyledToolTip { text: Translation.tr("Apply the Material drift color scheme instead of Slate grey") }
            }

            ConfigSelectionArray {
                options: [
                    { displayName: "Segoe UI", icon: "window", value: "Segoe UI Variable" },
                    { displayName: "Inter", icon: "text_fields", value: "Inter" },
                    { displayName: "Roboto", icon: "android", value: "Roboto" },
                    { displayName: "Noto Sans", icon: "translate", value: "Noto Sans" },
                    { displayName: "Ubuntu", icon: "terminal", value: "Ubuntu" }
                ]
                currentValue: themingSection.currentFontFamily
                onSelected: newValue => Config.setNestedValue("slate.theming.font.family", newValue)
            }

            FontSelector {
                label: Translation.tr("Custom font")
                icon: "font_download"
                selectedFont: themingSection.currentFontFamily
                onSelectedFontChanged: Config.setNestedValue("slate.theming.font.family", selectedFont)
            }

            ConfigSpinBox {
                icon: "format_size"
                text: Translation.tr("Font scale (%)")
                from: 80; to: 150; stepSize: 5
                value: Math.round((Config.options?.slate?.theming?.font?.scale ?? 1.0) * 100)
                onValueChanged: Config.setNestedValue("slate.theming.font.scale", value / 100.0)
                StyledToolTip { text: Translation.tr("Scale all Slate UI text (80% - 150%)") }
            }

            RippleButton {
                visible: themingSection.currentFontFamily !== themingSection.defaultFont || (Config.options?.slate?.theming?.font?.scale ?? 1.0) !== 1.0
                Layout.fillWidth: true
                implicitHeight: 36
                
                colBackground: Appearance.colors.colLayer1
                colBackgroundHover: Appearance.colors.colLayer1Hover
                colRipple: Appearance.colors.colLayer1Active

                contentItem: RowLayout {
                    anchors.centerIn: parent
                    spacing: 8

                    MaterialSymbol {
                        text: "restart_alt"
                        iconSize: Appearance.font.pixelSize.normal
                        color: Appearance.colors.colOnSurface
                    }
                    StyledText {
                        text: Translation.tr("Reset to defaults")
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colOnSurface
                    }
                }

                onClicked: {
                    Config.setNestedValue("slate.theming.font.family", themingSection.defaultFont);
                    Config.setNestedValue("slate.theming.font.scale", 1.0);
                }
            }
        }
    }
        }
    }

    SettingsTaskLoader {
        requested: root.isSlateActive && root.activeSection === "style"
        sourceComponent: Component {
    SettingsCardSection {
        settingsTaskSection: "style"
        expanded: true
        title: Translation.tr("Behavior")

        SettingsGroup {
            SettingsSwitch {
                buttonIcon: "stacks"
                text: Translation.tr("Allow multiple panels open")
                checked: Config.options?.slate?.behavior?.allowMultiplePanels ?? false
                onCheckedChanged: Config.setNestedValue("slate.behavior.allowMultiplePanels", checked)
            }
        }
    }
        }
    }

    SettingsTaskLoader {
        requested: root.activeSection === "transition"
        sourceComponent: Component {
    SettingsCardSection {
        settingsTaskSection: "transition"
        expanded: true
        title: Translation.tr("Family Transition")

        SettingsGroup {
            StyledText {
                Layout.fillWidth: true
                text: Translation.tr("Settings for switching between Material drift, Slate, and Atoll panel families.")
                color: Appearance.colors.colSubtext
                font.pixelSize: Appearance.font.pixelSize.small
                wrapMode: Text.WordWrap
            }

            SettingsSwitch {
                buttonIcon: "animation"
                text: Translation.tr("Animated transition")
                checked: Config.options?.familyTransitionAnimation ?? true
                onCheckedChanged: Config.setNestedValue("familyTransitionAnimation", checked)
                StyledToolTip { text: Translation.tr("Show a smooth animated overlay when switching between panel families") }
            }
        }
    }
        }
    }

    SettingsCardSection {
        visible: root.isSlateActive && root.isPanelEnabled("slateStartMenu")
        expanded: false
        icon: "grid_view"
        title: Translation.tr("Start Menu")

        SettingsGroup {
            ConfigSelectionArray {
                options: [
                    { displayName: Translation.tr("Mini"), icon: "crop_square", value: "mini" },
                    { displayName: Translation.tr("Compact"), icon: "view_compact", value: "compact" },
                    { displayName: Translation.tr("Normal"), icon: "grid_view", value: "normal" },
                    { displayName: Translation.tr("Large"), icon: "grid_on", value: "large" },
                    { displayName: Translation.tr("Wide"), icon: "view_week", value: "wide" }
                ]
                currentValue: Config.options?.slate?.startMenu?.sizePreset ?? "normal"
                onSelected: (newValue) => Config.setNestedValue("slate.startMenu.sizePreset", newValue)
            }

            ConfigSpinBox {
                icon: "format_size"
                text: Translation.tr("Text scale (%)")
                from: 80; to: 150; stepSize: 5
                value: Math.round((Config.options?.slate?.startMenu?.scale ?? 1.0) * 100)
                onValueChanged: Config.setNestedValue("slate.startMenu.scale", value / 100.0)
                StyledToolTip { text: Translation.tr("Scale text in the start menu (80% - 150%)") }
            }
        }
    }

    SettingsCardSection {
        visible: root.isSlateActive
        expanded: false
        icon: "tune"
        title: Translation.tr("Tweaks")

        SettingsGroup {
            SettingsSwitch {
                buttonIcon: "animation"
                text: Translation.tr("Smoother menu animations")
                checked: Config.options?.slate?.tweaks?.smootherMenuAnimations ?? true
                onCheckedChanged: Config.setNestedValue("slate.tweaks.smootherMenuAnimations", checked)
            }

            SettingsSwitch {
                buttonIcon: "toggle_on"
                text: Translation.tr("Switch handle position fix")
                checked: Config.options?.slate?.tweaks?.switchHandlePositionFix ?? true
                onCheckedChanged: Config.setNestedValue("slate.tweaks.switchHandlePositionFix", checked)
            }
        }
    }

    SettingsCardSection {
        visible: root.isSlateActive && root.isPanelEnabled("slateNotificationCenter")
        expanded: false
        icon: "calendar_month"
        title: Translation.tr("Calendar")

        SettingsGroup {
            SettingsSwitch {
                buttonIcon: "calendar_today"
                text: Translation.tr("Force 2-character day of week")
                checked: Config.options?.slate?.calendar?.force2CharDayOfWeek ?? true
                onCheckedChanged: Config.setNestedValue("slate.calendar.force2CharDayOfWeek", checked)
            }
        }
    }

    SettingsCardSection {
        visible: root.isSlateActive
        expanded: false
        icon: "swap_horiz"
        title: Translation.tr("Alt+Tab Switcher")

        SettingsGroup {
            ConfigSelectionArray {
                options: [
                    { displayName: Translation.tr("Niri's Recent Windows"), icon: "view_carousel", value: "niri" },
                    { displayName: Translation.tr("Lunana switcher"), icon: "keyboard_tab", value: "lunana" }
                ]
                currentValue: NiriKeybinds.altTabSource
                onSelected: newValue => NiriKeybinds.setAltTabSource(newValue)
            }
            SettingsSwitch {
                enabled: {
                    const preset = Config.options?.slate?.altSwitcher?.preset ?? "thumbnails"
                    return preset !== "skew" && preset !== "none"
                }
                buttonIcon: "visibility_off"
                text: Translation.tr("No visual UI (cycle windows only)")
                checked: {
                    const preset = Config.options?.slate?.altSwitcher?.preset ?? "thumbnails"
                    if (preset === "none")
                        return true
                    if (preset === "skew")
                        return false
                    return Config.options?.slate?.altSwitcher?.noVisualUi ?? false
                }
                onCheckedChanged: Config.setNestedValue("slate.altSwitcher.noVisualUi", checked)
                StyledToolTip { text: Translation.tr("Use Alt+Tab to switch windows without showing the switcher overlay") }
            }

            ConfigSelectionArray {
                options: [
                    { displayName: Translation.tr("Thumbnails"), icon: "grid_view", value: "thumbnails" },
                    { displayName: Translation.tr("Cards"), icon: "view_carousel", value: "cards" },
                    { displayName: Translation.tr("Compact"), icon: "view_module", value: "compact" },
                    { displayName: Translation.tr("List"), icon: "view_list", value: "list" },
                    { displayName: Translation.tr("Skew previews"), icon: "view_in_ar", value: "skew" },
                    { displayName: Translation.tr("None (no UI)"), icon: "visibility_off", value: "none" }
                ]
                currentValue: Config.options?.slate?.altSwitcher?.preset ?? "thumbnails"
                onSelected: (newValue) => {
                    Config.setNestedValue("slate.altSwitcher.preset", newValue)
                    Config.setNestedValue("slate.altSwitcher.noVisualUi", newValue === "none")
                }
            }

            SettingsSwitch {
                buttonIcon: "bolt"
                text: Translation.tr("Quick switch (Alt+Tab once to switch)")
                checked: Config.options?.slate?.altSwitcher?.quickSwitch ?? true
                onCheckedChanged: Config.setNestedValue("slate.altSwitcher.quickSwitch", checked)
                StyledToolTip { text: Translation.tr("Single Alt+Tab switches to previous window without showing the switcher") }
            }

            SettingsSwitch {
                buttonIcon: "timer"
                text: Translation.tr("Auto-hide after delay")
                checked: Config.options?.slate?.altSwitcher?.autoHide ?? true
                onCheckedChanged: Config.setNestedValue("slate.altSwitcher.autoHide", checked)
            }

            ConfigSpinBox {
                visible: Config.options?.slate?.altSwitcher?.autoHide ?? true
                icon: "hourglass_empty"
                text: Translation.tr("Auto-hide delay (ms)")
                from: 100; to: 5000; stepSize: 100
                value: Config.options?.slate?.altSwitcher?.autoHideDelayMs ?? 500
                onValueChanged: Config.setNestedValue("slate.altSwitcher.autoHideDelayMs", value)
            }

            SettingsSwitch {
                buttonIcon: "close"
                text: Translation.tr("Close on window focus")
                checked: Config.options?.slate?.altSwitcher?.closeOnFocus ?? true
                onCheckedChanged: Config.setNestedValue("slate.altSwitcher.closeOnFocus", checked)
            }

            SettingsSwitch {
                buttonIcon: "history"
                text: Translation.tr("Most recent first")
                checked: Config.options?.slate?.altSwitcher?.useMostRecentFirst ?? true
                onCheckedChanged: Config.setNestedValue("slate.altSwitcher.useMostRecentFirst", checked)
            }

            ConfigSpinBox {
                visible: (Config.options?.slate?.altSwitcher?.preset ?? "thumbnails") === "thumbnails"
                icon: "width"
                text: Translation.tr("Thumbnail width")
                from: 150; to: 500; stepSize: 20
                value: Config.options?.slate?.altSwitcher?.thumbnailWidth ?? 280
                onValueChanged: Config.setNestedValue("slate.altSwitcher.thumbnailWidth", value)
            }

            ConfigSpinBox {
                visible: (Config.options?.slate?.altSwitcher?.preset ?? "thumbnails") === "thumbnails"
                icon: "height"
                text: Translation.tr("Thumbnail height")
                from: 100; to: 400; stepSize: 20
                value: Config.options?.slate?.altSwitcher?.thumbnailHeight ?? 180
                onValueChanged: Config.setNestedValue("slate.altSwitcher.thumbnailHeight", value)
            }

            // List width option disabled - SPane doesn't support dynamic width properly
            // ConfigSpinBox {
            //     visible: (Config.options?.slate?.altSwitcher?.preset ?? "thumbnails") === "list"
            //     icon: "width"
            //     text: Translation.tr("List width")
            //     from: 350; to: 800; stepSize: 25
            //     value: Config.options?.slate?.altSwitcher?.listWidth ?? 500
            //     onValueChanged: Config.options.slate.altSwitcher.listWidth = value
            // }

            ConfigSpinBox {
                icon: "opacity"
                text: Translation.tr("Scrim opacity")
                from: 0; to: 100; stepSize: 5
                value: Math.round((Config.options?.slate?.altSwitcher?.scrimOpacity ?? 0.4) * 100)
                onValueChanged: Config.setNestedValue("slate.altSwitcher.scrimOpacity", value / 100.0)
            }

            SettingsSwitch {
                buttonIcon: "grid_view"
                text: Translation.tr("Show Niri overview while switching")
                checked: Config.options?.slate?.altSwitcher?.showOverviewWhileSwitching ?? false
                onCheckedChanged: Config.setNestedValue("slate.altSwitcher.showOverviewWhileSwitching", checked)
                StyledToolTip { text: Translation.tr("Opens Niri's native overview alongside the switcher for window previews") }
            }
        }
    }

    SettingsCardSection {
        visible: root.isSlateActive && root.isPanelEnabled("slateWidgets")
        expanded: false
        icon: "widgets"
        title: Translation.tr("Widgets Panel")

        SettingsGroup {
            SettingsSwitch {
                buttonIcon: "schedule"
                text: Translation.tr("Date & Time")
                checked: Config.options?.slate?.widgetsPanel?.showDateTime ?? true
                onCheckedChanged: Config.setNestedValue("slate.widgetsPanel.showDateTime", checked)
            }

            SettingsSwitch {
                buttonIcon: "cloud"
                text: Translation.tr("Weather")
                checked: Config.options?.slate?.widgetsPanel?.showWeather ?? true
                onCheckedChanged: Config.setNestedValue("slate.widgetsPanel.showWeather", checked)
            }

            SettingsSwitch {
                buttonIcon: "memory"
                text: Translation.tr("System Resources")
                checked: Config.options?.slate?.widgetsPanel?.showSystem ?? true
                onCheckedChanged: Config.setNestedValue("slate.widgetsPanel.showSystem", checked)
            }

            SettingsSwitch {
                buttonIcon: "music_note"
                text: Translation.tr("Media Player")
                checked: Config.options?.slate?.widgetsPanel?.showMedia ?? true
                onCheckedChanged: Config.setNestedValue("slate.widgetsPanel.showMedia", checked)
            }

            SettingsSwitch {
                buttonIcon: "bolt"
                text: Translation.tr("Quick Actions")
                checked: Config.options?.slate?.widgetsPanel?.showQuickActions ?? true
                onCheckedChanged: Config.setNestedValue("slate.widgetsPanel.showQuickActions", checked)
            }
        }
    }
}
