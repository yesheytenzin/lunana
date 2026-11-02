pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../../../../services"
import "../../../common"
import "../../looks"
import ".."

// Slate-side settings for the shared Workspace Strip module (the strip itself
// loads in both families; this mirrors modules/settings/WorkspaceStripConfig.qml).
SSettingsPage {
    id: root
    settingsPageIndex: 13
    pageTitle: Translation.tr("Workspace Strip")
    pageIcon: "desktop"
    pageDescription: Translation.tr("Edge-hover workspace navigator")

    function isPanelEnabled(): bool {
        return (Config.options?.enabledPanels ?? []).includes("driftWorkspaceStrip")
    }

    function setPanelEnabled(enabled: bool): void {
        const panels = [...(Config.options?.enabledPanels ?? [])]
        const index = panels.indexOf("driftWorkspaceStrip")
        if (enabled && index === -1)
            panels.push("driftWorkspaceStrip")
        else if (!enabled && index !== -1)
            panels.splice(index, 1)
        Config.setNestedValue("enabledPanels", panels)
    }

    SSettingsInfoBar {
        severity: SSettingsInfoBar.Severity.Info
        message: Translation.tr("Optional edge navigator, disabled on fresh installs. Hover the configured edge to open it, hover a workspace to inspect it, click cards or windows to focus them, drag windows between cards, and hold × to close. Window snapshots are available on Niri.")
    }

    SSettingsCard {
        title: Translation.tr("Edge behavior")
        icon: "desktop"

        SSettingsSwitch {
            label: Translation.tr("Enable workspace strip")
            icon: "desktop"
            description: Translation.tr("Keeps a compact workspace strip visible on the configured edge")
            checked: root.isPanelEnabled()
            onCheckedChanged: root.setPanelEnabled(checked)
        }

        SSettingsRow {
            label: Translation.tr("Edge")
            icon: "border-outside"

            control: Component {
                SSettingsChoiceGroup {
                    columns: 2
                    currentValue: Config.options?.workspaceStrip?.side ?? "right"
                    onSelected: newValue => Config.setNestedValue("workspaceStrip.side", newValue)
                    options: [
                        { value: "left", label: Translation.tr("Left") },
                        { value: "right", label: Translation.tr("Right") }
                    ]
                }
            }
        }

        SSettingsRow {
            label: Translation.tr("Look")
            icon: "image"

            control: Component {
                SSettingsChoiceGroup {
                    columns: 3
                    currentValue: Config.options?.workspaceStrip?.style ?? "auto"
                    onSelected: newValue => Config.setNestedValue("workspaceStrip.style", newValue)
                    options: [
                        { value: "auto", label: Translation.tr("Follow bar") },
                        { value: "island", label: Translation.tr("Island") },
                        { value: "stock", label: Translation.tr("Stock") }
                    ]
                }
            }
        }

        SSettingsSpinBox {
            label: Translation.tr("Panel width")
            icon: "desktop"
            suffix: "px"
            from: 360; to: 760; stepSize: 4
            value: Config.options?.workspaceStrip?.panelWidth ?? 480
            onValueChanged: Config.setNestedValue("workspaceStrip.panelWidth", value)
        }

        SSettingsSpinBox {
            label: Translation.tr("Preview size")
            icon: "image"
            suffix: "px"
            from: 96; to: 260; stepSize: 4
            value: Config.options?.workspaceStrip?.previewSize ?? 150
            onValueChanged: Config.setNestedValue("workspaceStrip.previewSize", value)
        }

        SSettingsSpinBox {
            label: Translation.tr("Trigger width")
            icon: "panel-left-expand"
            suffix: "px"
            from: 1; to: 16; stepSize: 1
            value: Config.options?.workspaceStrip?.triggerWidth ?? 6
            onValueChanged: Config.setNestedValue("workspaceStrip.triggerWidth", value)
        }

        SSettingsSpinBox {
            label: Translation.tr("Open delay")
            icon: "timer"
            suffix: "ms"
            from: 1; to: 500; stepSize: 10
            value: Config.options?.workspaceStrip?.openDelay ?? 110
            onValueChanged: Config.setNestedValue("workspaceStrip.openDelay", value)
        }

        SSettingsSpinBox {
            label: Translation.tr("Close delay")
            icon: "timer"
            suffix: "ms"
            from: 100; to: 1200; stepSize: 20
            value: Config.options?.workspaceStrip?.closeDelay ?? 320
            onValueChanged: Config.setNestedValue("workspaceStrip.closeDelay", value)
        }
    }

    SSettingsCard {
        title: Translation.tr("Navigation")
        icon: "arrow-sync"

        SSettingsSwitch {
            label: Translation.tr("Scroll to navigate")
            icon: "arrow-sync"
            description: Translation.tr("Use the mouse wheel over the strip to move between workspaces instead of scrolling the thumbnail list")
            checked: Config.options?.workspaceStrip?.scrollNavigation ?? false
            onCheckedChanged: Config.setNestedValue("workspaceStrip.scrollNavigation", checked)
        }

        SSettingsSwitch {
            visible: Config.options?.workspaceStrip?.scrollNavigation ?? false
            label: Translation.tr("Switch workspace on scroll")
            icon: "desktop"
            description: Translation.tr("Also focus the workspace in the compositor when scrolling through the strip")
            checked: Config.options?.workspaceStrip?.scrollNavigationSwitchWorkspace ?? true
            onCheckedChanged: Config.setNestedValue("workspaceStrip.scrollNavigationSwitchWorkspace", checked)
        }

        SSettingsSpinBox {
            visible: Config.options?.workspaceStrip?.scrollNavigation ?? false
            label: Translation.tr("Scroll debounce")
            icon: "timer"
            suffix: "ms"
            from: 50; to: 800; stepSize: 10
            value: Config.options?.workspaceStrip?.scrollNavigationDebounceMs ?? 180
            onValueChanged: Config.setNestedValue("workspaceStrip.scrollNavigationDebounceMs", value)
        }
    }

    SSettingsCard {
        title: Translation.tr("Workspace cards")
        icon: "apps"

        SSettingsSwitch {
            label: Translation.tr("Window previews")
            icon: "image"
            description: Translation.tr("Live preview for the active workspace and refreshed snapshots for hidden workspaces")
            checked: Config.options?.workspaceStrip?.showPreviews ?? true
            onCheckedChanged: Config.setNestedValue("workspaceStrip.showPreviews", checked)
        }

        SSettingsSwitch {
            label: Translation.tr("Window metadata")
            icon: "info"
            description: Translation.tr("Show workspace name, focused window title and window count")
            checked: Config.options?.workspaceStrip?.showMetadata ?? true
            onCheckedChanged: Config.setNestedValue("workspaceStrip.showMetadata", checked)
        }

        SSettingsSwitch {
            label: Translation.tr("App icons")
            icon: "apps"
            description: Translation.tr("Show icons for open applications on the selected workspace card")
            checked: Config.options?.workspaceStrip?.showAppIcons ?? true
            onCheckedChanged: Config.setNestedValue("workspaceStrip.showAppIcons", checked)
        }

        SSettingsSwitch {
            label: Translation.tr("Now-playing player")
            icon: "settings"
            description: Translation.tr("Add a media card at the top of the strip with playback controls when music is playing")
            checked: Config.options?.workspaceStrip?.showMediaPlayer ?? true
            onCheckedChanged: Config.setNestedValue("workspaceStrip.showMediaPlayer", checked)
        }

        SSettingsSwitch {
            enabled: CompositorService.isNiri
            label: Translation.tr("Per-monitor workspaces")
            icon: "desktop"
            description: CompositorService.isNiri
                ? Translation.tr("Each screen shows only its own Niri workspaces")
                : Translation.tr("Only available on Niri")
            checked: Config.options?.workspaceStrip?.perMonitor ?? true
            onCheckedChanged: Config.setNestedValue("workspaceStrip.perMonitor", checked)
        }
    }
}
