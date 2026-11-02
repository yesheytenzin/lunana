import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../services"
import "../common"
import "../common/widgets"

ContentPage {
    id: modulesPage
    settingsPageIndex: 10
    settingsPageName: Translation.tr("Modules")

    readonly property string activeFamily: Config.options?.panelFamily ?? "drift"
    readonly property bool isIi: modulesPage.activeFamily === "drift"
    readonly property bool isSlate: modulesPage.activeFamily === "slate"
    readonly property bool isAtoll: modulesPage.activeFamily === "atoll"

    readonly property var defaultPanels: ({
        "drift": [
            "driftBar", "driftBackground", "driftBackdrop", "driftCheatsheet", "driftControlPanel", "driftDock", "driftLock", 
            "driftMediaControls", "driftNotificationPopup", "driftOnScreenDisplay", "driftOnScreenKeyboard", 
            "driftOverlay", "driftOverview", "driftPolkit", "driftRegionSelector", "driftScreenCorners", 
            "driftSessionScreen", "driftSidebarLeft", "driftSidebarRight", "driftTilingOverlay", "driftVerticalBar", 
            "driftWallpaperSelector", "driftWallpaperLauncher", "driftCoverflowSelector", "driftClipboard", "driftShellUpdate"
        ],
        "slate": [
            "slateBar", "slateBackground", "slateBackdrop", "slateStartMenu", "slateActionCenter", "slateNotificationCenter", "slateNotificationPopup", "slateOnScreenDisplay", "slateWidgets", "slateTaskView", "slateLock", "slatePolkit", "slateSessionScreen",
            "driftCheatsheet", "driftOnScreenKeyboard", "driftOverlay", "driftOverview",
            "driftRegionSelector", "driftScreenCorners", "driftWallpaperSelector", "driftWallpaperLauncher", "driftCoverflowSelector", "driftClipboard"
        ],
        "atoll": [
            "atollBar", "atollBackground", "atollPalette", "atollControlCenter",
            "atollNotificationPopup", "atollOnScreenDisplay", "atollSessionScreen",
            "atollLock", "atollPolkit"
        ]
    })

    function isPanelEnabled(panelId: string): bool {
        return (Config.options?.enabledPanels ?? []).includes(panelId)
    }

    function setPanelEnabled(panelId: string, enabled: bool) {
        let panels = [...(Config.options?.enabledPanels ?? [])]
        const idx = panels.indexOf(panelId)
        
        if (enabled && idx === -1) {
            panels.push(panelId)
        } else if (!enabled && idx !== -1) {
            panels.splice(idx, 1)
        }
        
        Config.setNestedValue("enabledPanels", panels)
    }

    function isDriftBarEnabled(): bool {
        const panels = Config.options?.enabledPanels ?? []
        return panels.includes("driftBar") || panels.includes("driftVerticalBar")
    }

    function setDriftBarEnabled(enabled: bool) {
        let panels = [...(Config.options?.enabledPanels ?? [])]

        const hasBar = panels.includes("driftBar")
        const hasVerticalBar = panels.includes("driftVerticalBar")

        if (enabled) {
            if (!hasBar) panels.push("driftBar")
            if (!hasVerticalBar) panels.push("driftVerticalBar")
        } else {
            panels = panels.filter(panel => panel !== "driftBar" && panel !== "driftVerticalBar")
        }

        Config.setNestedValue("enabledPanels", panels)
    }

    function resetToDefaults() {
        const family = Config.options?.panelFamily ?? "drift"
        Config.setNestedValue("enabledPanels", [...(defaultPanels[family] ?? [])])
    }

    property string activeSection: "panels"

    function activateSettingsSearchSection(section: string): bool {
        const label = String(section || "").toLowerCase().trim()
        const sections = {
            "shell modules": "panels",
            "panel style": "panels",
            "default terminal": "terminal",
            "modules": "modules",
            "core": "modules",
            "feedback": "modules",
            "utilities": "modules",
            "optional": "modules",
            "slate core": "modules",
            "shared modules": "modules",
            "display scaling": "interface",
            "wallpaper selector": "interface",
            "settings ui": "interface"
        }
        const target = sections[label] ?? ""
        if (!target)
            return false
        modulesPage.activeSection = target
        return true
    }

    SettingsTaskNavigator {
        icon: "extension"
        title: Translation.tr("Modules")
        description: Translation.tr("Choose which shell modules run, pick your default terminal and tune interface behavior in focused views.")
        summary: Translation.tr("Panels \u00b7 Terminal \u00b7 Modules \u00b7 Interface")
        currentValue: modulesPage.activeSection
        onSelected: value => modulesPage.activeSection = value
        options: [
            { displayName: Translation.tr("Panels"), icon: "extension", value: "panels" },
            { displayName: Translation.tr("Terminal"), icon: "terminal", value: "terminal" },
            { displayName: Translation.tr("Modules"), icon: "dashboard", value: "modules" },
            { displayName: Translation.tr("Interface"), icon: "tune", value: "interface" }
        ]
    }

    SettingsTaskLoader {
        requested: modulesPage.activeSection === "panels"
        sourceComponent: Component {
    SettingsCardSection {
        settingsTaskSection: "panels"
        expanded: true
        icon: "extension"
        title: Translation.tr("Shell Modules")

        SettingsGroup {
            StyledText {
                Layout.fillWidth: true
                text: Translation.tr("Enable or disable shell modules. Changes apply live.")
                color: Appearance.colors.colSubtext
                font.pixelSize: Appearance.font.pixelSize.smaller
                wrapMode: Text.WordWrap
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                RippleButton {
                    Layout.fillWidth: true
                    implicitHeight: 36
                    buttonRadius: Appearance.zzzEverywhere ? Appearance.zzz.controlRadius : Appearance.rounding.small
                    colBackground: Appearance.colors.colLayer1
                    colBackgroundHover: Appearance.colors.colLayer1Hover
                    colRipple: Appearance.colors.colLayer1Active

                    RowLayout {
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
                        }
                    }

                    onClicked: modulesPage.resetToDefaults()
                }
            }
        }
    }
        }
    }

    SettingsTaskLoader {
        requested: modulesPage.activeSection === "panels"
        sourceComponent: Component {
    SettingsCardSection {
        settingsTaskSection: "panels"
        expanded: false
        icon: "style"
        title: Translation.tr("Panel Style")

        SettingsGroup {
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                RippleButton {
                    Layout.fillWidth: true
                    implicitHeight: 64
                    buttonRadius: Appearance.zzzEverywhere ? Appearance.zzz.controlRadius : Appearance.rounding.small
                    colBackground: modulesPage.isIi
                        ? (Appearance.zzzEverywhere ? Appearance.zzz.sticker : Appearance.colors.colPrimaryContainer)
                        : Appearance.colors.colLayer1
                    colBackgroundHover: modulesPage.isIi
                        ? (Appearance.zzzEverywhere ? Appearance.colors.colPrimaryHover : Appearance.colors.colPrimaryContainerHover)
                        : Appearance.colors.colLayer1Hover
                    colRipple: modulesPage.isIi
                        ? (Appearance.zzzEverywhere ? Appearance.colors.colPrimaryActive : Appearance.colors.colPrimaryContainerActive)
                        : Appearance.colors.colLayer1Active

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 4
                        MaterialSymbol {
                            Layout.alignment: Qt.AlignHCenter
                            text: "dashboard"
                            iconSize: Appearance.font.pixelSize.larger
                            color: modulesPage.isIi
                                ? (Appearance.zzzEverywhere ? Appearance.zzz.onSticker : Appearance.colors.colOnPrimaryContainer)
                                : Appearance.colors.colOnSurface
                        }
                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            text: "Material (drift)"
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: modulesPage.isIi
                                ? (Appearance.zzzEverywhere ? Appearance.zzz.onSticker : Appearance.colors.colOnPrimaryContainer)
                                : Appearance.colors.colOnSurface
                        }
                    }

                    onClicked: Quickshell.execDetached(["omarchy-shell", "lunana.family", "set", "drift"])
                }

                RippleButton {
                    Layout.fillWidth: true
                    implicitHeight: 64
                    buttonRadius: Appearance.zzzEverywhere ? Appearance.zzz.controlRadius : Appearance.rounding.small
                    colBackground: modulesPage.isSlate ? Appearance.colors.colPrimaryContainer : Appearance.colors.colLayer1
                    colBackgroundHover: modulesPage.isSlate ? Appearance.colors.colPrimaryContainerHover : Appearance.colors.colLayer1Hover
                    colRipple: modulesPage.isSlate ? Appearance.colors.colPrimaryContainerActive : Appearance.colors.colLayer1Active

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 4
                        MaterialSymbol {
                            Layout.alignment: Qt.AlignHCenter
                            text: "window"
                            iconSize: Appearance.font.pixelSize.larger
                            color: modulesPage.isSlate ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colOnSurface
                        }
                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            text: "Slate (Slate)"
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: modulesPage.isSlate ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colOnSurface
                        }
                    }

                    onClicked: Quickshell.execDetached(["omarchy-shell", "lunana.family", "set", "slate"])
                }

                RippleButton {
                    Layout.fillWidth: true
                    implicitHeight: 64
                    buttonRadius: Appearance.zzzEverywhere ? Appearance.zzz.controlRadius : Appearance.rounding.small
                    colBackground: modulesPage.isAtoll ? Appearance.colors.colPrimaryContainer : Appearance.colors.colLayer1
                    colBackgroundHover: modulesPage.isAtoll ? Appearance.colors.colPrimaryContainerHover : Appearance.colors.colLayer1Hover
                    colRipple: modulesPage.isAtoll ? Appearance.colors.colPrimaryContainerActive : Appearance.colors.colLayer1Active

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 4
                        MaterialSymbol {
                            Layout.alignment: Qt.AlignHCenter
                            text: "visibility"
                            iconSize: Appearance.font.pixelSize.larger
                            color: modulesPage.isAtoll ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colOnSurface
                        }
                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            text: "Atoll"
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: modulesPage.isAtoll ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colOnSurface
                        }
                    }

                    onClicked: Quickshell.execDetached(["omarchy-shell", "lunana.family", "set", "atoll"])
                }
            }

            ConfigSwitch {
                Layout.fillWidth: true
                buttonIcon: "animation"
                text: Translation.tr("Animated switch")
                checked: Config.options?.familyTransitionAnimation ?? true
                onCheckedChanged: Config.setNestedValue("familyTransitionAnimation", checked)
            }

            StyledText {
                Layout.fillWidth: true
                text: Translation.tr("The switch shortcut goes through, in this order:")
                color: Appearance.colors.colSubtext
                font.pixelSize: Appearance.font.pixelSize.smaller
                wrapMode: Text.WordWrap
            }
            Flow {
                Layout.fillWidth: true
                spacing: 6
                Repeater {
                    model: [
                        { value: "drift", label: "Material", icon: "dashboard" },
                        { value: "slate", label: "Slate", icon: "window" },
                        { value: "atoll", label: "Atoll", icon: "visibility" }
                    ]
                    FilterChip {
                        required property var modelData
                        readonly property var cycle: Array.from(Config.options?.familyCycle ?? ["drift", "slate", "atoll"])
                        chipIcon: modelData.icon
                        text: cycle.includes(modelData.value)
                            ? `${cycle.indexOf(modelData.value) + 1}  ${modelData.label}` : modelData.label
                        selected: cycle.includes(modelData.value)
                        onClicked: {
                            const next = cycle.filter(family => family !== modelData.value)
                            if (!selected) next.push(modelData.value)
                            Config.setNestedValue("familyCycle", next)
                        }
                    }
                }
            }
        }
    }
        }
    }

    // ==================== DEFAULT TERMINAL ====================
    SettingsTaskLoader {
        requested: modulesPage.activeSection === "terminal"
        sourceComponent: Component {
    SettingsCardSection {
        id: terminalSection
        settingsTaskSection: "terminal"
        expanded: true
        icon: "terminal"
        title: Translation.tr("Default Terminal")

        SettingsGroup {
            StyledText {
                Layout.fillWidth: true
                text: Translation.tr("Terminal used by shell actions, tools, keybinds, and package commands.")
                color: Appearance.colors.colSubtext
                font.pixelSize: Appearance.font.pixelSize.smaller
                wrapMode: Text.WordWrap
            }

            readonly property var terminalOptions: [
                { name: "Foot", value: "foot" },
                { name: "Kitty", value: "kitty" },
                { name: "Ghostty", value: "ghostty" },
                { name: "Alacritty", value: "alacritty" },
                { name: "WezTerm", value: "wezterm" },
                { name: "Konsole", value: "konsole" },
            ]

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                // Foot
                RippleButton {
                    Layout.fillWidth: true
                    implicitHeight: 64
                    buttonRadius: Appearance.zzzEverywhere ? Appearance.zzz.controlRadius : Appearance.rounding.small
                    readonly property bool isSelected: (Config.options?.apps?.terminal ?? "kitty") === "foot"
                    colBackground: isSelected ? (Appearance.zzzEverywhere ? Appearance.zzz.sticker : Appearance.colors.colPrimaryContainer) : Appearance.colors.colLayer1
                    colBackgroundHover: isSelected ? (Appearance.zzzEverywhere ? Appearance.colors.colPrimaryHover : Appearance.colors.colPrimaryContainerHover) : Appearance.colors.colLayer1Hover
                    colRipple: isSelected ? (Appearance.zzzEverywhere ? Appearance.colors.colPrimaryActive : Appearance.colors.colPrimaryContainerActive) : Appearance.colors.colLayer1Active
                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 4
                        MaterialSymbol {
                            Layout.alignment: Qt.AlignHCenter
                            text: "terminal"
                            iconSize: Appearance.font.pixelSize.larger
                            color: parent.parent.isSelected ? (Appearance.zzzEverywhere ? Appearance.zzz.onSticker : Appearance.colors.colOnPrimaryContainer) : Appearance.colors.colOnSurface
                            Behavior on color {
                                enabled: Appearance.animationsEnabled
                                ColorAnimation { duration: Appearance.animation.elementMoveFast.duration }
                            }
                        }
                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            text: "Foot"
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: parent.parent.isSelected ? (Appearance.zzzEverywhere ? Appearance.zzz.onSticker : Appearance.colors.colOnPrimaryContainer) : Appearance.colors.colOnSurface
                            Behavior on color {
                                enabled: Appearance.animationsEnabled
                                ColorAnimation { duration: Appearance.animation.elementMoveFast.duration }
                            }
                        }
                    }
                    onClicked: {
                        AppLauncher.applyPreset("terminal", "foot")
                    }
                }

                // Kitty
                RippleButton {
                    Layout.fillWidth: true
                    implicitHeight: 64
                    buttonRadius: Appearance.zzzEverywhere ? Appearance.zzz.controlRadius : Appearance.rounding.small
                    readonly property bool isSelected: (Config.options?.apps?.terminal ?? "kitty") === "kitty"
                    colBackground: isSelected ? (Appearance.zzzEverywhere ? Appearance.zzz.sticker : Appearance.colors.colPrimaryContainer) : Appearance.colors.colLayer1
                    colBackgroundHover: isSelected ? (Appearance.zzzEverywhere ? Appearance.colors.colPrimaryHover : Appearance.colors.colPrimaryContainerHover) : Appearance.colors.colLayer1Hover
                    colRipple: isSelected ? (Appearance.zzzEverywhere ? Appearance.colors.colPrimaryActive : Appearance.colors.colPrimaryContainerActive) : Appearance.colors.colLayer1Active
                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 4
                        MaterialSymbol {
                            Layout.alignment: Qt.AlignHCenter
                            text: "terminal"
                            iconSize: Appearance.font.pixelSize.larger
                            color: parent.parent.isSelected ? (Appearance.zzzEverywhere ? Appearance.zzz.onSticker : Appearance.colors.colOnPrimaryContainer) : Appearance.colors.colOnSurface
                            Behavior on color {
                                enabled: Appearance.animationsEnabled
                                ColorAnimation { duration: Appearance.animation.elementMoveFast.duration }
                            }
                        }
                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            text: "Kitty"
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: parent.parent.isSelected ? (Appearance.zzzEverywhere ? Appearance.zzz.onSticker : Appearance.colors.colOnPrimaryContainer) : Appearance.colors.colOnSurface
                            Behavior on color {
                                enabled: Appearance.animationsEnabled
                                ColorAnimation { duration: Appearance.animation.elementMoveFast.duration }
                            }
                        }
                    }
                    onClicked: {
                        AppLauncher.applyPreset("terminal", "kitty")
                    }
                }

                // Ghostty
                RippleButton {
                    Layout.fillWidth: true
                    implicitHeight: 64
                    buttonRadius: Appearance.zzzEverywhere ? Appearance.zzz.controlRadius : Appearance.rounding.small
                    readonly property bool isSelected: (Config.options?.apps?.terminal ?? "kitty") === "ghostty"
                    colBackground: isSelected ? (Appearance.zzzEverywhere ? Appearance.zzz.sticker : Appearance.colors.colPrimaryContainer) : Appearance.colors.colLayer1
                    colBackgroundHover: isSelected ? (Appearance.zzzEverywhere ? Appearance.colors.colPrimaryHover : Appearance.colors.colPrimaryContainerHover) : Appearance.colors.colLayer1Hover
                    colRipple: isSelected ? (Appearance.zzzEverywhere ? Appearance.colors.colPrimaryActive : Appearance.colors.colPrimaryContainerActive) : Appearance.colors.colLayer1Active
                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 4
                        MaterialSymbol {
                            Layout.alignment: Qt.AlignHCenter
                            text: "terminal"
                            iconSize: Appearance.font.pixelSize.larger
                            color: parent.parent.isSelected ? (Appearance.zzzEverywhere ? Appearance.zzz.onSticker : Appearance.colors.colOnPrimaryContainer) : Appearance.colors.colOnSurface
                            Behavior on color {
                                enabled: Appearance.animationsEnabled
                                ColorAnimation { duration: Appearance.animation.elementMoveFast.duration }
                            }
                        }
                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            text: "Ghostty"
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: parent.parent.isSelected ? (Appearance.zzzEverywhere ? Appearance.zzz.onSticker : Appearance.colors.colOnPrimaryContainer) : Appearance.colors.colOnSurface
                            Behavior on color {
                                enabled: Appearance.animationsEnabled
                                ColorAnimation { duration: Appearance.animation.elementMoveFast.duration }
                            }
                        }
                    }
                    onClicked: {
                        AppLauncher.applyPreset("terminal", "ghostty")
                    }
                }

                // Alacritty
                RippleButton {
                    Layout.fillWidth: true
                    implicitHeight: 64
                    buttonRadius: Appearance.zzzEverywhere ? Appearance.zzz.controlRadius : Appearance.rounding.small
                    readonly property bool isSelected: (Config.options?.apps?.terminal ?? "kitty") === "alacritty"
                    colBackground: isSelected ? (Appearance.zzzEverywhere ? Appearance.zzz.sticker : Appearance.colors.colPrimaryContainer) : Appearance.colors.colLayer1
                    colBackgroundHover: isSelected ? (Appearance.zzzEverywhere ? Appearance.colors.colPrimaryHover : Appearance.colors.colPrimaryContainerHover) : Appearance.colors.colLayer1Hover
                    colRipple: isSelected ? (Appearance.zzzEverywhere ? Appearance.colors.colPrimaryActive : Appearance.colors.colPrimaryContainerActive) : Appearance.colors.colLayer1Active
                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 4
                        MaterialSymbol {
                            Layout.alignment: Qt.AlignHCenter
                            text: "terminal"
                            iconSize: Appearance.font.pixelSize.larger
                            color: parent.parent.isSelected ? (Appearance.zzzEverywhere ? Appearance.zzz.onSticker : Appearance.colors.colOnPrimaryContainer) : Appearance.colors.colOnSurface
                            Behavior on color {
                                enabled: Appearance.animationsEnabled
                                ColorAnimation { duration: Appearance.animation.elementMoveFast.duration }
                            }
                        }
                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            text: "Alacritty"
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: parent.parent.isSelected ? (Appearance.zzzEverywhere ? Appearance.zzz.onSticker : Appearance.colors.colOnPrimaryContainer) : Appearance.colors.colOnSurface
                            Behavior on color {
                                enabled: Appearance.animationsEnabled
                                ColorAnimation { duration: Appearance.animation.elementMoveFast.duration }
                            }
                        }
                    }
                    onClicked: {
                        AppLauncher.applyPreset("terminal", "alacritty")
                    }
                }

                // WezTerm
                RippleButton {
                    Layout.fillWidth: true
                    implicitHeight: 64
                    buttonRadius: Appearance.zzzEverywhere ? Appearance.zzz.controlRadius : Appearance.rounding.small
                    readonly property bool isSelected: (Config.options?.apps?.terminal ?? "kitty") === "wezterm"
                    colBackground: isSelected ? (Appearance.zzzEverywhere ? Appearance.zzz.sticker : Appearance.colors.colPrimaryContainer) : Appearance.colors.colLayer1
                    colBackgroundHover: isSelected ? (Appearance.zzzEverywhere ? Appearance.colors.colPrimaryHover : Appearance.colors.colPrimaryContainerHover) : Appearance.colors.colLayer1Hover
                    colRipple: isSelected ? (Appearance.zzzEverywhere ? Appearance.colors.colPrimaryActive : Appearance.colors.colPrimaryContainerActive) : Appearance.colors.colLayer1Active
                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 4
                        MaterialSymbol {
                            Layout.alignment: Qt.AlignHCenter
                            text: "terminal"
                            iconSize: Appearance.font.pixelSize.larger
                            color: parent.parent.isSelected ? (Appearance.zzzEverywhere ? Appearance.zzz.onSticker : Appearance.colors.colOnPrimaryContainer) : Appearance.colors.colOnSurface
                            Behavior on color {
                                enabled: Appearance.animationsEnabled
                                ColorAnimation { duration: Appearance.animation.elementMoveFast.duration }
                            }
                        }
                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            text: "WezTerm"
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: parent.parent.isSelected ? (Appearance.zzzEverywhere ? Appearance.zzz.onSticker : Appearance.colors.colOnPrimaryContainer) : Appearance.colors.colOnSurface
                            Behavior on color {
                                enabled: Appearance.animationsEnabled
                                ColorAnimation { duration: Appearance.animation.elementMoveFast.duration }
                            }
                        }
                    }
                    onClicked: {
                        AppLauncher.applyPreset("terminal", "wezterm")
                    }
                }

                // Konsole
                RippleButton {
                    Layout.fillWidth: true
                    implicitHeight: 64
                    buttonRadius: Appearance.zzzEverywhere ? Appearance.zzz.controlRadius : Appearance.rounding.small
                    readonly property bool isSelected: (Config.options?.apps?.terminal ?? "kitty") === "konsole"
                    colBackground: isSelected ? (Appearance.zzzEverywhere ? Appearance.zzz.sticker : Appearance.colors.colPrimaryContainer) : Appearance.colors.colLayer1
                    colBackgroundHover: isSelected ? (Appearance.zzzEverywhere ? Appearance.colors.colPrimaryHover : Appearance.colors.colPrimaryContainerHover) : Appearance.colors.colLayer1Hover
                    colRipple: isSelected ? (Appearance.zzzEverywhere ? Appearance.colors.colPrimaryActive : Appearance.colors.colPrimaryContainerActive) : Appearance.colors.colLayer1Active
                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 4
                        MaterialSymbol {
                            Layout.alignment: Qt.AlignHCenter
                            text: "terminal"
                            iconSize: Appearance.font.pixelSize.larger
                            color: parent.parent.isSelected ? (Appearance.zzzEverywhere ? Appearance.zzz.onSticker : Appearance.colors.colOnPrimaryContainer) : Appearance.colors.colOnSurface
                            Behavior on color {
                                enabled: Appearance.animationsEnabled
                                ColorAnimation { duration: Appearance.animation.elementMoveFast.duration }
                            }
                        }
                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            text: "Konsole"
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: parent.parent.isSelected ? (Appearance.zzzEverywhere ? Appearance.zzz.onSticker : Appearance.colors.colOnPrimaryContainer) : Appearance.colors.colOnSurface
                            Behavior on color {
                                enabled: Appearance.animationsEnabled
                                ColorAnimation { duration: Appearance.animation.elementMoveFast.duration }
                            }
                        }
                    }
                    onClicked: {
                        AppLauncher.applyPreset("terminal", "konsole")
                    }
                }
            }

            StyledText {
                Layout.fillWidth: true
                Layout.topMargin: 4
                text: Translation.tr("Mod+T and Mod+Return use this terminal. Run './setup update' to apply keybind migration.")
                color: Appearance.colors.colSubtext
                font.pixelSize: Appearance.font.pixelSize.smaller
                font.italic: true
                wrapMode: Text.WordWrap
            }
        }
    }
        }
    }

    // ==================== MATERIAL II ====================
    SettingsTaskLoader {
        requested: modulesPage.isIi && modulesPage.activeSection === "modules"
        sourceComponent: Component {
    SettingsCardSection {
        settingsTaskSection: "modules"
        expanded: true
        icon: "dashboard"
        title: Translation.tr("Core")

        SettingsGroup {
            SettingsSwitch {
                buttonIcon: "toolbar"
                text: Translation.tr("Bar")
                checked: modulesPage.isDriftBarEnabled()
                onCheckedChanged: modulesPage.setDriftBarEnabled(checked)
                StyledToolTip { text: Translation.tr("Main bar module. Orientation (horizontal/vertical) is configured in Bar settings.") }
            }

            SettingsSwitch {
                buttonIcon: "wallpaper"
                text: Translation.tr("Background")
                checked: modulesPage.isPanelEnabled("driftBackground")
                onCheckedChanged: modulesPage.setPanelEnabled("driftBackground", checked)
                StyledToolTip { text: Translation.tr("Desktop wallpaper with parallax effect and widgets") }
            }

            SettingsSwitch {
                buttonIcon: "blur_on"
                text: Translation.tr("Niri Overview Backdrop")
                checked: modulesPage.isPanelEnabled("driftBackdrop")
                onCheckedChanged: modulesPage.setPanelEnabled("driftBackdrop", checked)
                StyledToolTip { text: Translation.tr("Blurred wallpaper shown in Niri's native overview (Mod+Tab)") }
            }

            SettingsSwitch {
                buttonIcon: "search"
                text: Translation.tr("Overview")
                checked: modulesPage.isPanelEnabled("driftOverview")
                onCheckedChanged: modulesPage.setPanelEnabled("driftOverview", checked)
                StyledToolTip { text: Translation.tr("App launcher, search and workspace grid (Super+Space)") }
            }

            SettingsSwitch {
                buttonIcon: "view_sidebar"
                text: Translation.tr("Workspace Strip")
                checked: modulesPage.isPanelEnabled("driftWorkspaceStrip")
                onCheckedChanged: modulesPage.setPanelEnabled("driftWorkspaceStrip", checked)
                StyledToolTip { text: Translation.tr("Hover a screen edge for visual workspace navigation") }
            }

            SettingsSwitch {
                buttonIcon: "widgets"
                text: Translation.tr("Floating tools (Super+G)")
                checked: modulesPage.isPanelEnabled("driftOverlay")
                onCheckedChanged: modulesPage.setPanelEnabled("driftOverlay", checked)
                StyledToolTip { text: Translation.tr("Floating image and widgets panel (Super+G)") }
            }

            SettingsSwitch {
                buttonIcon: "left_panel_open"
                text: Translation.tr("Left Sidebar")
                checked: modulesPage.isPanelEnabled("driftSidebarLeft")
                onCheckedChanged: modulesPage.setPanelEnabled("driftSidebarLeft", checked)
                StyledToolTip { text: Translation.tr("AI assistant, translator, image browser") }
            }

            SettingsSwitch {
                buttonIcon: "right_panel_open"
                text: Translation.tr("Right Sidebar")
                checked: modulesPage.isPanelEnabled("driftSidebarRight")
                onCheckedChanged: modulesPage.setPanelEnabled("driftSidebarRight", checked)
                StyledToolTip { text: Translation.tr("Quick settings, notifications, calendar, system info") }
            }
        }
    }
        }
    }

    SettingsTaskLoader {
        requested: modulesPage.isIi && modulesPage.activeSection === "modules"
        sourceComponent: Component {
    SettingsCardSection {
        settingsTaskSection: "modules"
        expanded: false
        icon: "notifications"
        title: Translation.tr("Feedback")

        SettingsGroup {
            SettingsSwitch {
                buttonIcon: "notifications"
                text: Translation.tr("Notification Popups")
                checked: modulesPage.isPanelEnabled("driftNotificationPopup")
                onCheckedChanged: modulesPage.setPanelEnabled("driftNotificationPopup", checked)
                StyledToolTip { text: Translation.tr("Toast notifications that appear on screen") }
            }

            SettingsSwitch {
                buttonIcon: "volume_up"
                text: Translation.tr("OSD")
                checked: modulesPage.isPanelEnabled("driftOnScreenDisplay")
                onCheckedChanged: modulesPage.setPanelEnabled("driftOnScreenDisplay", checked)
                StyledToolTip { text: Translation.tr("On-screen display for volume and brightness changes") }
            }

            SettingsSwitch {
                buttonIcon: "music_note"
                text: Translation.tr("Media Controls")
                checked: modulesPage.isPanelEnabled("driftMediaControls")
                onCheckedChanged: modulesPage.setPanelEnabled("driftMediaControls", checked)
                StyledToolTip { text: Translation.tr("Floating media player controls") }
            }
        }
    }
        }
    }

    SettingsTaskLoader {
        requested: modulesPage.isIi && modulesPage.activeSection === "modules"
        sourceComponent: Component {
    SettingsCardSection {
        settingsTaskSection: "modules"
        expanded: false
        icon: "build"
        title: Translation.tr("Utilities")

        SettingsGroup {
            SettingsSwitch {
                buttonIcon: "lock"
                text: Translation.tr("Lock Screen")
                checked: modulesPage.isPanelEnabled("driftLock")
                onCheckedChanged: modulesPage.setPanelEnabled("driftLock", checked)
                StyledToolTip { text: Translation.tr("Custom lock screen with clock and password input") }
            }

            SettingsSwitch {
                buttonIcon: "power_settings_new"
                text: Translation.tr("Session Screen")
                checked: modulesPage.isPanelEnabled("driftSessionScreen")
                onCheckedChanged: modulesPage.setPanelEnabled("driftSessionScreen", checked)
                StyledToolTip { text: Translation.tr("Power menu: lock, logout, suspend, reboot, shutdown") }
            }

            SettingsSwitch {
                buttonIcon: "admin_panel_settings"
                text: Translation.tr("Polkit Agent")
                checked: modulesPage.isPanelEnabled("driftPolkit")
                onCheckedChanged: modulesPage.setPanelEnabled("driftPolkit", checked)
                StyledToolTip { text: Translation.tr("Password prompt for administrative actions") }
            }

            SettingsSwitch {
                buttonIcon: "screenshot_region"
                text: Translation.tr("Region Selector")
                checked: modulesPage.isPanelEnabled("driftRegionSelector")
                onCheckedChanged: modulesPage.setPanelEnabled("driftRegionSelector", checked)
                StyledToolTip { text: Translation.tr("Screen capture, OCR text extraction, color picker") }
            }

            SettingsSwitch {
                buttonIcon: "image"
                text: Translation.tr("Wallpaper Selector")
                checked: modulesPage.isPanelEnabled("driftWallpaperSelector")
                onCheckedChanged: modulesPage.setPanelEnabled("driftWallpaperSelector", checked)
                StyledToolTip { text: Translation.tr("File picker for changing wallpaper") }
            }

            SettingsSwitch {
                buttonIcon: "keyboard"
                text: Translation.tr("Cheatsheet")
                checked: modulesPage.isPanelEnabled("driftCheatsheet")
                onCheckedChanged: modulesPage.setPanelEnabled("driftCheatsheet", checked)
                StyledToolTip { text: Translation.tr("Keyboard shortcuts reference overlay") }
            }

            SettingsSwitch {
                buttonIcon: "keyboard_alt"
                text: Translation.tr("On-Screen Keyboard")
                checked: modulesPage.isPanelEnabled("driftOnScreenKeyboard")
                onCheckedChanged: modulesPage.setPanelEnabled("driftOnScreenKeyboard", checked)
                StyledToolTip { text: Translation.tr("Virtual keyboard for touch input") }
            }

            SettingsSwitch {
                buttonIcon: "tab"
                text: Translation.tr("Alt-Tab Switcher")
                checked: false
                enabled: false
                StyledToolTip { text: Translation.tr("Window switcher popup") }
            }

            SettingsSwitch {
                buttonIcon: "content_paste"
                text: Translation.tr("Clipboard History")
                checked: modulesPage.isPanelEnabled("driftClipboard")
                onCheckedChanged: modulesPage.setPanelEnabled("driftClipboard", checked)
                StyledToolTip { text: Translation.tr("Clipboard manager with history") }
            }
        }
    }
        }
    }

    SettingsTaskLoader {
        requested: modulesPage.isIi && modulesPage.activeSection === "modules"
        sourceComponent: Component {
    SettingsCardSection {
        settingsTaskSection: "modules"
        expanded: false
        icon: "more_horiz"
        title: Translation.tr("Optional")

        SettingsGroup {
            SettingsSwitch {
                buttonIcon: "dock_to_bottom"
                text: Translation.tr("Dock")
                checked: modulesPage.isPanelEnabled("driftDock")
                onCheckedChanged: modulesPage.setPanelEnabled("driftDock", checked)
                StyledToolTip { text: Translation.tr("macOS-style dock with pinned and running apps") }
            }

            SettingsSwitch {
                buttonIcon: "rounded_corner"
                text: Translation.tr("Screen Corners")
                checked: modulesPage.isPanelEnabled("driftScreenCorners")
                onCheckedChanged: modulesPage.setPanelEnabled("driftScreenCorners", checked)
                StyledToolTip { text: Translation.tr("Rounded corner overlays for screens without hardware rounding") }
            }

            SettingsSwitch {
                buttonIcon: "center_focus_strong"
                text: Translation.tr("Crosshair")
                checked: false
                enabled: false
                StyledToolTip { text: Translation.tr("Gaming crosshair overlay for games without built-in crosshair") }
            }

            SettingsSwitch {
                buttonIcon: "graphic_eq"
                text: Translation.tr("EasyEffects Equalizer")
                checked: modulesPage.isPanelEnabled("driftEqualizer")
                onCheckedChanged: modulesPage.setPanelEnabled("driftEqualizer", checked)
                StyledToolTip { text: Translation.tr("Load the native 10-band EasyEffects equalizer and its shell integration. Disabled means the equalizer panel and IPC owner are not constructed.") }
            }
        }
    }
        }
    }

    // ==================== SLATE ====================
    SettingsTaskLoader {
        requested: modulesPage.isSlate && modulesPage.activeSection === "modules"
        sourceComponent: Component {
    SettingsCardSection {
        settingsTaskSection: "modules"
        expanded: false
        icon: "window"
        title: Translation.tr("Slate Core")

        SettingsGroup {
            SettingsSwitch {
                buttonIcon: "toolbar"
                text: Translation.tr("Taskbar")
                checked: modulesPage.isPanelEnabled("slateBar")
                onCheckedChanged: modulesPage.setPanelEnabled("slateBar", checked)
                StyledToolTip { text: Translation.tr("Slate style taskbar with app icons and system tray") }
            }

            SettingsSwitch {
                buttonIcon: "wallpaper"
                text: Translation.tr("Background")
                checked: modulesPage.isPanelEnabled("slateBackground")
                onCheckedChanged: modulesPage.setPanelEnabled("slateBackground", checked)
                StyledToolTip { text: Translation.tr("Desktop wallpaper") }
            }

            SettingsSwitch {
                buttonIcon: "grid_view"
                text: Translation.tr("Start Menu")
                checked: modulesPage.isPanelEnabled("slateStartMenu")
                onCheckedChanged: modulesPage.setPanelEnabled("slateStartMenu", checked)
                StyledToolTip { text: Translation.tr("Slate style start menu with search and pinned apps (Super+Space)") }
            }

            SettingsSwitch {
                buttonIcon: "toggle_on"
                text: Translation.tr("Action Center")
                checked: modulesPage.isPanelEnabled("slateActionCenter")
                onCheckedChanged: modulesPage.setPanelEnabled("slateActionCenter", checked)
                StyledToolTip { text: Translation.tr("Quick settings panel with toggles and sliders") }
            }

            SettingsSwitch {
                buttonIcon: "notifications"
                text: Translation.tr("Notification Center")
                checked: modulesPage.isPanelEnabled("slateNotificationCenter")
                onCheckedChanged: modulesPage.setPanelEnabled("slateNotificationCenter", checked)
                StyledToolTip { text: Translation.tr("Notification panel with calendar") }
            }

            SettingsSwitch {
                buttonIcon: "notifications_active"
                text: Translation.tr("Notification Popups")
                checked: modulesPage.isPanelEnabled("slateNotificationPopup")
                onCheckedChanged: modulesPage.setPanelEnabled("slateNotificationPopup", checked)
                StyledToolTip { text: Translation.tr("Toast notifications that appear on screen (Slate style)") }
            }

            SettingsSwitch {
                buttonIcon: "volume_up"
                text: Translation.tr("OSD")
                checked: modulesPage.isPanelEnabled("slateOnScreenDisplay")
                onCheckedChanged: modulesPage.setPanelEnabled("slateOnScreenDisplay", checked)
                StyledToolTip { text: Translation.tr("On-screen display for volume and brightness") }
            }

            SettingsSwitch {
                buttonIcon: "widgets"
                text: Translation.tr("Widgets Panel")
                checked: modulesPage.isPanelEnabled("slateWidgets")
                onCheckedChanged: modulesPage.setPanelEnabled("slateWidgets", checked)
                StyledToolTip { text: Translation.tr("Slate style widgets sidebar") }
            }
        }
    }
        }
    }

    SettingsTaskLoader {
        requested: modulesPage.isSlate && modulesPage.activeSection === "modules"
        sourceComponent: Component {
    SettingsCardSection {
        settingsTaskSection: "modules"
        expanded: false
        icon: "share"
        title: Translation.tr("Shared Modules")

        SettingsGroup {
            StyledText {
                Layout.fillWidth: true
                text: Translation.tr("Supporting modules used alongside Slate")
                color: Appearance.colors.colSubtext
                font.pixelSize: Appearance.font.pixelSize.smaller
                wrapMode: Text.WordWrap
            }

            SettingsSwitch {
                buttonIcon: "blur_on"
                text: Translation.tr("Niri Overview Backdrop")
                checked: modulesPage.isPanelEnabled("driftBackdrop")
                onCheckedChanged: modulesPage.setPanelEnabled("driftBackdrop", checked)
                StyledToolTip { text: Translation.tr("Blurred wallpaper shown in Niri's native overview (Mod+Tab)") }
            }

            SettingsSwitch {
                buttonIcon: "search"
                text: Translation.tr("Overview")
                checked: modulesPage.isPanelEnabled("driftOverview")
                onCheckedChanged: modulesPage.setPanelEnabled("driftOverview", checked)
                StyledToolTip { text: Translation.tr("Workspace grid (used by Start Menu)") }
            }

            SettingsSwitch {
                buttonIcon: "widgets"
                text: Translation.tr("Floating tools (Super+G)")
                checked: modulesPage.isPanelEnabled("driftOverlay")
                onCheckedChanged: modulesPage.setPanelEnabled("driftOverlay", checked)
                StyledToolTip { text: Translation.tr("Floating image and widgets panel (Super+G)") }
            }

            SettingsSwitch {
                buttonIcon: "lock"
                text: Translation.tr("Lock Screen")
                checked: modulesPage.isPanelEnabled("slateLock")
                onCheckedChanged: modulesPage.setPanelEnabled("slateLock", checked)
                StyledToolTip { text: Translation.tr("Custom lock screen with clock and password input") }
            }

            SettingsSwitch {
                buttonIcon: "power_settings_new"
                text: Translation.tr("Session Screen")
                checked: modulesPage.isPanelEnabled("slateSessionScreen")
                onCheckedChanged: modulesPage.setPanelEnabled("slateSessionScreen", checked)
                StyledToolTip { text: Translation.tr("Power menu: lock, logout, suspend, reboot, shutdown") }
            }

            SettingsSwitch {
                buttonIcon: "admin_panel_settings"
                text: Translation.tr("Polkit Agent")
                checked: modulesPage.isPanelEnabled("slatePolkit")
                onCheckedChanged: modulesPage.setPanelEnabled("slatePolkit", checked)
                StyledToolTip { text: Translation.tr("Password prompt for administrative actions") }
            }

            SettingsSwitch {
                buttonIcon: "screenshot_region"
                text: Translation.tr("Region Selector")
                checked: modulesPage.isPanelEnabled("driftRegionSelector")
                onCheckedChanged: modulesPage.setPanelEnabled("driftRegionSelector", checked)
                StyledToolTip { text: Translation.tr("Screen capture, OCR text extraction, color picker") }
            }

            SettingsSwitch {
                buttonIcon: "image"
                text: Translation.tr("Wallpaper Selector")
                checked: modulesPage.isPanelEnabled("driftWallpaperSelector")
                onCheckedChanged: modulesPage.setPanelEnabled("driftWallpaperSelector", checked)
                StyledToolTip { text: Translation.tr("File picker for changing wallpaper") }
            }

            SettingsSwitch {
                buttonIcon: "keyboard"
                text: Translation.tr("Cheatsheet")
                checked: modulesPage.isPanelEnabled("driftCheatsheet")
                onCheckedChanged: modulesPage.setPanelEnabled("driftCheatsheet", checked)
                StyledToolTip { text: Translation.tr("Keyboard shortcuts reference overlay") }
            }

            SettingsSwitch {
                buttonIcon: "keyboard_alt"
                text: Translation.tr("On-Screen Keyboard")
                checked: modulesPage.isPanelEnabled("driftOnScreenKeyboard")
                onCheckedChanged: modulesPage.setPanelEnabled("driftOnScreenKeyboard", checked)
                StyledToolTip { text: Translation.tr("Virtual keyboard for touch input") }
            }

            SettingsSwitch {
                buttonIcon: "tab"
                text: Translation.tr("Alt-Tab Switcher")
                checked: false
                enabled: false
                StyledToolTip { text: Translation.tr("Window switcher popup") }
            }

            SettingsSwitch {
                buttonIcon: "content_paste"
                text: Translation.tr("Clipboard History")
                checked: modulesPage.isPanelEnabled("driftClipboard")
                onCheckedChanged: modulesPage.setPanelEnabled("driftClipboard", checked)
                StyledToolTip { text: Translation.tr("Clipboard manager with history") }
            }

            SettingsSwitch {
                buttonIcon: "center_focus_strong"
                text: Translation.tr("Crosshair")
                checked: false
                enabled: false
                StyledToolTip { text: Translation.tr("Gaming crosshair overlay") }
            }
        }
    }
        }
    }

    SettingsTaskLoader {
        requested: modulesPage.activeSection === "interface"
        sourceComponent: Component {
    SettingsCardSection {
        settingsTaskSection: "interface"
        expanded: true
        icon: "aspect_ratio"
        title: Translation.tr("Display scaling")

        SettingsGroup {
            ConfigRow {
                uniform: true
                ConfigSpinBox {
                    icon: "zoom_in"
                    text: Translation.tr("UI scale (%)")
                    value: Math.round((Config.options?.appearance?.typography?.sizeScale ?? 1.0) * 100)
                    from: 50
                    to: 200
                    stepSize: 5
                    onValueChanged: {
                        Config.setNestedValue("appearance.typography.sizeScale", value / 100)
                    }
                    StyledToolTip {
                        text: Translation.tr("Scale fonts and spacing throughout the shell. Takes effect immediately.")
                    }
                }
            }

            StyledText {
                Layout.leftMargin: 16
                text: Translation.tr("Current: %1%. Takes effect immediately.").arg(
                    Math.round((Config.options?.appearance?.typography?.sizeScale ?? 1.0) * 100))
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colSubtext
            }

            RowLayout {
                Layout.topMargin: 4
                visible: Math.abs((Config.options?.appearance?.typography?.sizeScale ?? 1.0) - 1.0) > 0.01

                RippleButtonWithIcon {
                    materialIcon: "zoom_out"
                    mainText: Translation.tr("Reset to 100%")
                    onClicked: {
                        Config.setNestedValue("appearance.typography.sizeScale", 1.0)
                    }
                }
            }
        }
    }
        }
    }

    SettingsTaskLoader {
        requested: modulesPage.activeSection === "interface"
        sourceComponent: Component {
    SettingsCardSection {
        settingsTaskSection: "interface"
        expanded: false
        icon: "wallpaper_slideshow"
        title: Translation.tr("Wallpaper selector")

        SettingsGroup {
            ContentSubsection {
                title: Translation.tr("Selector style")

                ConfigSelectionArray {
                    currentValue: Config.options?.wallpaperSelector?.style ?? "grid"
                    options: [
                        { displayName: Translation.tr("Grid"), icon: "grid_view", value: "grid" },
                        { displayName: Translation.tr("Coverflow"), icon: "view_carousel", value: "coverflow" },
                        { displayName: Translation.tr("Launcher"), icon: "wallpaper_slideshow", value: "launcher" }
                    ]
                    onSelected: value => Config.setNestedValue("wallpaperSelector.style", value)
                }

                SettingsSwitch {
                    visible: (Config.options?.wallpaperSelector?.style ?? "grid") === "coverflow"
                    buttonIcon: "view_array"
                    text: Translation.tr("Skew view (parallelogram cards)")
                    checked: (Config.options?.wallpaperSelector?.coverflowView ?? "gallery") === "skew"
                    onCheckedChanged: Config.setNestedValue("wallpaperSelector.coverflowView", checked ? "skew" : "gallery")
                    StyledToolTip {
                        text: Translation.tr("Use tilted parallelogram cards instead of the hero + filmstrip layout.\nYou can also switch between views from the toolbar inside the coverflow.")
                    }
                }
            }

            ContentSubsection {
                title: Translation.tr("Behavior")

                SettingsSwitch {
                    buttonIcon: "open_in_new"
                    text: Translation.tr("Use system file picker")
                    checked: Config.options?.wallpaperSelector?.useSystemFileDialog ?? false
                    onCheckedChanged: Config.setNestedValue("wallpaperSelector.useSystemFileDialog", checked)
                    StyledToolTip {
                        text: Translation.tr("Use your system's native file picker instead of the built-in one")
                    }
                }
            }
        }
    }
        }
    }

    SettingsTaskLoader {
        requested: modulesPage.activeSection === "interface"
        sourceComponent: Component {
    SettingsCardSection {
        settingsTaskSection: "interface"
        expanded: false
        icon: "web_asset"
        title: Translation.tr("Settings UI")

        SettingsGroup {
            StyledText {
                Layout.fillWidth: true
                text: Translation.tr("Choose how the Settings window opens. Overlay mode renders settings as a layer on top of the shell, so you can see changes to the bar, sidebars, and background in real time.")
                color: Appearance.colors.colOnSurfaceVariant
                font.pixelSize: Appearance.font.pixelSize.small
                wrapMode: Text.WordWrap
            }

            SettingsSwitch {
                buttonIcon: "school"
                text: Translation.tr("Easy mode (essentials only)")
                checked: Config.options?.settingsUi?.easyMode ?? false
                onCheckedChanged: Config.setNestedValue("settingsUi.easyMode", checked)
                StyledToolTip {
                    text: Translation.tr("Show a curated set of essential settings and hide the more advanced pages and sections. You can switch back to Advanced anytime from the title bar.")
                }
            }

            SettingsSwitch {
                buttonIcon: "layers"
                text: Translation.tr("Overlay mode (live preview)")
                checked: Config.options?.settingsUi?.overlayMode ?? false
                autoToggle: false
                onToggledByUser: enabled => {
                    const action = enabled ? "openOverlayAt" : "openWindowAt"
                    Quickshell.execDetached([((Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")) + "/omarchy/lunana-vendor/" + ("scripts/lunana")),
                        "ipc", "settings", action, String(modulesPage.settingsPageIndex)])
                    if (enabled && !GlobalStates.settingsOverlayOpen)
                        Qt.quit()
                }
                StyledToolTip {
                    text: Translation.tr("When enabled, Settings opens as a floating overlay inside the shell instead of a separate window. Switching modes takes effect immediately and keeps you on this Settings page.")
                }
            }

            ContentSubsection {
                title: Translation.tr("Overlay layout")
                visible: Config.options?.settingsUi?.overlayMode ?? false

                ConfigSelectionArray {
                    currentValue: Config.options?.settingsUi?.overlayStyle ?? "rail"
                    options: [
                        { displayName: Translation.tr("Nav rail"), icon: "view_sidebar", value: "rail" },
                        { displayName: Translation.tr("Focus"), icon: "grid_view", value: "focus" },
                        { displayName: Translation.tr("Unified"), icon: "side_navigation", value: "unified" },
                        { displayName: Translation.tr("Editorial"), icon: "auto_stories", value: "editorial" }
                    ]
                    onSelected: value => Quickshell.execDetached([((Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")) + "/omarchy/lunana-vendor/" + ("scripts/lunana")),
                        "ipc", "settings", "setOverlayStyle", value, String(modulesPage.settingsPageIndex)])
                }

                StyledText {
                    Layout.fillWidth: true
                    readonly property string overlayStyle: Config.options?.settingsUi?.overlayStyle ?? "rail"
                    text: overlayStyle === "focus"
                        ? Translation.tr("One page at a time: a grid of every settings page, then the page you pick, full width. Escape steps back.")
                        : overlayStyle === "editorial"
                            ? Translation.tr("A paper Settings studio with expressive typography. Pair with the Editorial global style for the complete composition.")
                        : overlayStyle === "unified"
                            ? Translation.tr("A fast, consistent Settings layout with a fixed sidebar and unified controls.")
                            : Translation.tr("A persistent category rail beside the page you are editing.")
                    color: Appearance.colors.colSubtext
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    wrapMode: Text.WordWrap
                }
            }

            ContentSubsection {
                title: Translation.tr("Overlay appearance")
                visible: Config.options?.settingsUi?.overlayMode ?? false

                ConfigSpinBox {
                    icon: "blur_on"
                    text: Translation.tr("Backdrop blur (%)")
                    value: Config.options?.settingsUi?.overlayAppearance?.backdropBlur ?? 0
                    from: 0
                    to: 100
                    stepSize: 10
                    onValueChanged: Config.setNestedValue("settingsUi.overlayAppearance.backdropBlur", value)
                    StyledToolTip {
                        text: Translation.tr("Blur the wallpaper behind the Settings overlay while it is open, using the same glass the rest of the shell paints. 0 turns it off and costs nothing.")
                    }
                }

                ConfigSpinBox {
                    icon: "water"
                    text: Translation.tr("Background dim (%)")
                    value: Config.options?.settingsUi?.overlayAppearance?.scrimDim ?? 35
                    from: 0
                    to: 80
                    stepSize: 5
                    onValueChanged: Config.setNestedValue("settingsUi.overlayAppearance.scrimDim", value)
                    StyledToolTip {
                        text: Translation.tr("How dark the backdrop behind the Settings panel should be (0 = transparent, 80 = very dark)")
                    }
                }

                // Floor is 60, not 20: the panel is a reading surface and the
                // solid styles carry no backdrop of their own, so anything lower
                // put the wallpaper straight behind the text. Both settings
                // hosts clamp on read too, so an older stored value cannot reach
                // the panel even if this page is never opened.
                ConfigSpinBox {
                    icon: "opacity"
                    text: Translation.tr("Panel background opacity (%)")
                    value: Math.round((Config.options?.settingsUi?.overlayAppearance?.backgroundOpacity ?? 1.0) * 100)
                    from: 60
                    to: 100
                    stepSize: 5
                    onValueChanged: Config.setNestedValue("settingsUi.overlayAppearance.backgroundOpacity", value / 100)
                    StyledToolTip {
                        text: Translation.tr("Opacity of the Settings panel background. Lower values let the shell show through; with a glass style it thins the frosted tint instead.")
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: modeHintRow.implicitHeight + 16
                radius: Appearance.zzzEverywhere ? Appearance.zzz.cardRadius : Appearance.rounding.small
                color: Appearance.zzzEverywhere ? "transparent" : Appearance.colors.colSurfaceContainerLow
                border.width: Appearance.zzzEverywhere ? 0 : 1
                border.color: Appearance.zzzEverywhere ? "transparent" : Appearance.colors.colLayer0Border
                Behavior on radius {
                    enabled: Appearance.animationsEnabled
                    NumberAnimation { duration: Appearance.animation.elementMoveFast.duration }
                }
                Behavior on color {
                    enabled: Appearance.animationsEnabled
                    ColorAnimation { duration: Appearance.animation.elementMoveFast.duration }
                }
                Behavior on border.width {
                    enabled: Appearance.animationsEnabled
                    NumberAnimation { duration: Appearance.animation.elementMoveFast.duration }
                }
                Behavior on border.color {
                    enabled: Appearance.animationsEnabled
                    ColorAnimation { duration: Appearance.animation.elementMoveFast.duration }
                }

                ZzzPlate {
                    anchors.fill: parent
                    visible: Appearance.zzzEverywhere
                    fillColor: Appearance.colors.colLayer1
                    strokeColor: Appearance.zzz.hairline
                    radius: Appearance.zzz.cardRadius
                    chamfer: Appearance.zzz.cutCorner * 0.45
                    chamferTopRight: !Appearance.zzz.round
                }

                RowLayout {
                    id: modeHintRow
                    anchors {
                        fill: parent
                        margins: 8
                    }
                    spacing: 8

                    MaterialSymbol {
                        text: (Config.options?.settingsUi?.overlayMode ?? false) ? "layers" : "open_in_new"
                        iconSize: Appearance.font.pixelSize.huge
                        color: Appearance.colors.colPrimary
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        StyledText {
                            text: (Config.options?.settingsUi?.overlayMode ?? false)
                                ? Translation.tr("Overlay mode")
                                : Translation.tr("Window mode")
                            font {
                                pixelSize: Appearance.font.pixelSize.small
                                weight: Font.Medium
                            }
                            color: Appearance.colors.colOnSurface
                        }
                        StyledText {
                            Layout.fillWidth: true
                            text: (Config.options?.settingsUi?.overlayMode ?? false)
                                ? Translation.tr("Settings will open as a floating panel over the shell. Press Esc or click outside to close.")
                                : Translation.tr("Settings will open as a separate application window (current behavior).")
                            font.pixelSize: Appearance.font.pixelSize.smallest
                            color: Appearance.colors.colSubtext
                            wrapMode: Text.WordWrap
                        }
                    }
                }
            }
        }
    }
        }
    }
}
