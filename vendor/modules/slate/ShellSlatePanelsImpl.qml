pragma ComponentBehavior: Bound

import "../bootGreeting"
import "../cheatsheet"
import "../lock"
import "../mascot"
import "../onScreenKeyboard"
import "../recordingOsd"
import "../tilingOverlay"
import "../overview"
import "../polkit"
import "../regionSelector"
import "../screenCorners"
import "../sessionScreen"
import "../shellUpdate"
import "../wallpaperSelector"
import "../wallpaperLauncher"
import "../drift/overlay"
import "../workspaceStrip"
import "../clipboard" as ClipboardModule

import "actionCenter"
import "altSwitcher" as SlateAltSwitcherModule
import "background" as SlateBackgroundModule
import "bar" as SlateBarModule
import "clipboard" as SlateClipboardModule
import "notificationCenter"
import "onScreenDisplay" as SlateOSDModule
import "startMenu"
import "widgets"
import "backdrop" as SlateBackdropModule
import "notificationPopup" as SlateNotificationPopupModule
import "taskview" as SlateTaskViewModule

import QtQuick
import Quickshell
import Quickshell.Io
import "../.."
import "../common"
import "../../services"
import "../../services/deferred"

Item {
    id: root

    readonly property var slateAltSwitcherOptions:
        Config.options?.slate?.altSwitcher ?? ({})
    readonly property string slateAltSwitcherPreset:
        root.slateAltSwitcherOptions.preset ?? "thumbnails"
    readonly property bool slateAltSwitcherVisual:
        root.slateAltSwitcherPreset !== "none"
        && !((root.slateAltSwitcherOptions.noVisualUi ?? false)
            && root.slateAltSwitcherPreset !== "skew")

    // Immediate panels — visible at first frame or must catch early events
    component PanelLoader: LazyLoader {
        required property string identifier
        property bool extraCondition: true
        active: Config.ready && (Config.options?.enabledPanels ?? []).includes(identifier) && extraCondition
    }

    // Deferred panels — loaded asynchronously after first frame to reduce boot contention
    component DeferredPanelLoader: LazyLoader {
        required property string identifier
        property bool extraCondition: true
        loading: Config.ready && GlobalStates.shellEntryReady
            && (Config.options?.enabledPanels ?? []).includes(identifier) && extraCondition
        activeAsync: Config.ready && GlobalStates.deferredPanelsReady && (Config.options?.enabledPanels ?? []).includes(identifier) && extraCondition
    }

    component OnDemandPanelLoader: LazyLoader {
        id: onDemandLoader
        required property string identifier
        required property bool open
        property bool retainAfterUse: false
        property bool used: false
        property int closeGraceMs: 250
        property int retainIdleMs: 5 * 60 * 1000
        property bool resident: open
        property Timer closeGrace: Timer {
            interval: onDemandLoader.closeGraceMs
            onTriggered: onDemandLoader.resident = onDemandLoader.open
        }
        property Timer retainIdle: Timer {
            interval: onDemandLoader.retainIdleMs
            onTriggered: onDemandLoader.resident = onDemandLoader.open
        }
        readonly property bool enabledPanel: Config.ready
            && (Config.options?.enabledPanels ?? []).includes(identifier)
        onOpenChanged: {
            if (open) {
                used = true
                closeGrace.stop()
                retainIdle.stop()
                resident = true
            } else if (retainAfterUse && used) {
                retainIdle.restart()
            } else {
                closeGrace.restart()
            }
        }
        loading: enabledPanel && resident
        activeAsync: enabledPanel && GlobalStates.deferredPanelsReady && resident
    }

    // === Immediate feedback panels within the deferred host ===
    // Core Slate surfaces (bar/background/backdrop) are owned by the critical
    // startup host so they are not delayed by the rest of this module.
    PanelLoader { identifier: "slateNotificationPopup"; component: SlateNotificationPopupModule.SlateNotificationPopup {} }
    PanelLoader { identifier: "slateOnScreenDisplay"; component: SlateOSDModule.SlateOSD {} }

    // === Deferred panels ===
    OnDemandPanelLoader { identifier: "slateStartMenu"; open: GlobalStates.searchOpen; retainAfterUse: true; component: SlateStartMenu {} }
    OnDemandPanelLoader { identifier: "slateActionCenter"; open: GlobalStates.slateActionCenterOpen; retainAfterUse: true; component: SlateActionCenter {} }
    OnDemandPanelLoader { identifier: "slateNotificationCenter"; open: GlobalStates.slateNotificationCenterOpen; component: SlateNotificationCenter {} }
    OnDemandPanelLoader { identifier: "slateWidgets"; open: GlobalStates.slateWidgetsOpen && (Config.options?.slate?.modules?.widgets ?? true); component: SlateWidgets {} }
    DeferredPanelLoader { identifier: "slateLock"; component: Lock {} }
    DeferredPanelLoader { identifier: "slatePolkit"; component: Polkit {} }
    OnDemandPanelLoader { identifier: "slateSessionScreen"; open: GlobalStates.sessionOpen; component: SessionScreen {} }
    OnDemandPanelLoader { identifier: "slateTaskView"; open: GlobalStates.slateTaskViewOpen; component: SlateTaskViewModule.SlateTaskView {} }

    // Shared modules that work with slate
    DeferredPanelLoader { identifier: "driftBootGreeting"; component: BootGreeting {} }
    OnDemandPanelLoader { identifier: "driftCheatsheet"; open: GlobalStates.cheatsheetOpen; component: Cheatsheet {} }
    OnDemandPanelLoader { identifier: "driftOnScreenKeyboard"; open: GlobalStates.oskOpen; component: OnScreenKeyboard {} }
    OnDemandPanelLoader { identifier: "driftOverlay"; open: GlobalStates.overlayOpen || OverlayContext.hasPinnedWidgets || OverlayContext.nativeDialogOpen; component: Overlay {} }
    OnDemandPanelLoader { identifier: "driftOverview"; open: GlobalStates.overviewOpen; retainAfterUse: true; closeGraceMs: 300; component: Overview {} }

    DeferredPanelLoader { identifier: "driftRegionSelector"; component: RegionSelector {} }
    DeferredPanelLoader { identifier: "driftScreenCorners"; component: ScreenCorners {} }

    OnDemandPanelLoader { identifier: "driftWallpaperSelector"; open: GlobalStates.wallpaperSelectorOpen; retainAfterUse: true; closeGraceMs: 250; component: WallpaperSelector {} }
    OnDemandPanelLoader { identifier: "driftWallpaperLauncher"; open: GlobalStates.wallpaperLauncherOpen; retainAfterUse: true; closeGraceMs: 250; component: WallpaperLauncher {} }
    OnDemandPanelLoader { identifier: "driftCoverflowSelector"; open: GlobalStates.coverflowSelectorOpen; retainAfterUse: true; closeGraceMs: 300; component: WallpaperCoverflow {} }
    DeferredPanelLoader { identifier: "driftClipboard"; extraCondition: Config.options?.panelFamily !== "slate"; component: ClipboardModule.ClipboardPanel {} }
    OnDemandPanelLoader { identifier: "driftRecordingOsd"; open: RecorderStatus.isRecording; closeGraceMs: 250; component: RecordingOsd {} }
    OnDemandPanelLoader { identifier: "driftShellUpdate"; open: ShellUpdates.overlayOpen; closeGraceMs: 250; component: ShellUpdateOverlay {} }

    OnDemandPanelLoader {
        identifier: "driftTilingOverlay"
        open: GlobalStates.tilingOverlayPickerOpen || GlobalStates.tilingOverlayOsdOpen
        closeGraceMs: 250
        component: TilingOverlay {}
    }
    DeferredPanelLoader { identifier: "driftWorkspaceStrip"; component: WorkspaceStrip {} }
    DeferredPanelLoader { identifier: "driftMascotCompanion"; extraCondition: true; component: MascotCompanion {} }

    LazyLoader {
        loading: Config.ready && GlobalStates.shellEntryReady
            && Config.options?.panelFamily === "slate"
        activeAsync: Config.ready && GlobalStates.deferredPanelsReady && Config.options?.panelFamily === "slate"
        component: SlateClipboardModule.SlateClipboard {}
    }

    LazyLoader {
        loading: Config.ready && GlobalStates.shellEntryReady
            && Config.options?.panelFamily === "slate"
            && root.slateAltSwitcherVisual
        activeAsync: Config.ready && GlobalStates.deferredPanelsReady
            && Config.options?.panelFamily === "slate"
            && root.slateAltSwitcherVisual
        component: SlateAltSwitcherModule.SlateAltSwitcher {}
    }

    SlateBackgroundModule.SlateShellEditHud {}
}
