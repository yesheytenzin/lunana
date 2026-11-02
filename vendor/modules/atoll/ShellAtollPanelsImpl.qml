pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import "../.."
import "../../services"
import "../common"
import "notificationPopup"
import "onScreenDisplay"
import "session"
import "polkit"
import "style"
import "pieces"
import "settings"
import "studio"
import "lock"
import "sidebar"
import "orbit"
import "osk"
import "../background"
import "../lock"

Item {
    id: root

    component PanelLoader: LazyLoader {
        required property string identifier
        property bool extraCondition: true
        readonly property bool enabledPanel: Config.ready && AtollGate.official
            && (Config.options?.enabledPanels ?? []).includes(identifier)
            && extraCondition
        loading: enabledPanel
        activeAsync: enabledPanel
    }

    component DeferredPanelLoader: LazyLoader {
        required property string identifier
        property bool extraCondition: true
        readonly property bool enabledPanel: Config.ready && AtollGate.official
            && (Config.options?.enabledPanels ?? []).includes(identifier)
            && extraCondition
        loading: enabledPanel && GlobalStates.shellEntryReady
        activeAsync: enabledPanel && GlobalStates.deferredPanelsReady
    }

    component OnDemandPanelLoader: LazyLoader {
        id: loader
        required property string identifier
        required property bool open
        property bool extraCondition: true
        property bool requireEnabledPanel: true
        property int closeGraceMs: AtollStyle.revealDuration + 30
        property bool resident: open
        property Timer closeGrace: Timer {
            interval: loader.closeGraceMs
            onTriggered: loader.resident = loader.open
        }
        readonly property bool enabledPanel: Config.ready && AtollGate.official
            && (!requireEnabledPanel || (Config.options?.enabledPanels ?? []).includes(identifier))
            && extraCondition

        onOpenChanged: {
            if (open) {
                closeGrace.stop()
                resident = true
            } else {
                closeGrace.restart()
            }
        }

        loading: enabledPanel && resident
        activeAsync: enabledPanel && GlobalStates.deferredPanelsReady && resident
    }

    AtollAppsSync {}

    // Orbit's hot corner: a few pixels in one screen corner, on Top, only while it is on and something can use it.
    LazyLoader {
        active: AtollGate.official && (Config.options?.atoll?.orbit?.enable ?? false) && (Config.options?.atoll?.orbit?.hotCorner ?? true)
        component: AtollOrbitCorner {}
    }

    LazyLoader {
        active: AtollGate.official
        component: AtollSidebarEdge { side: "left" }
    }
    LazyLoader {
        active: AtollGate.official
        component: AtollSidebarEdge { side: "right" }
    }

    OnDemandPanelLoader {
        identifier: "atollSidebarLeft"
        requireEnabledPanel: false
        open: GlobalStates.sidebarLeftOpen
        extraCondition: Config.options?.atoll?.sidebars?.left?.enable ?? true
        closeGraceMs: AtollStyle.settleDuration + 80
        component: AtollSidebar { side: "left" }
    }

    OnDemandPanelLoader {
        identifier: "atollSidebarRight"
        requireEnabledPanel: false
        open: GlobalStates.sidebarRightOpen
        extraCondition: Config.options?.atoll?.sidebars?.right?.enable ?? true
        closeGraceMs: AtollStyle.settleDuration + 80
        component: AtollSidebar { side: "right" }
    }

    OnDemandPanelLoader {
        identifier: "atollNotificationPopup"
        open: (Notifications.popupList?.length ?? 0) > 0
        closeGraceMs: AtollStyle.settleDuration * 2 + 160
        extraCondition: (Config.options?.atoll?.modules?.notificationPopup ?? true)
            && (!(Config.options?.enabledPanels ?? []).includes("atollBar")
                || (CompositorService.isNiri && GameMode.hasFullscreenOnOutput(GlobalStates.focusedScreen?.name ?? "") && !NiriService.inOverview
                    && (Config.options?.atoll?.notifications?.fullscreen ?? true)))
        component: AtollNotificationPopup {}
    }

    OnDemandPanelLoader {
        identifier: "atollStudio"
        requireEnabledPanel: false
        open: GlobalStates.atollStudioOpen
        closeGraceMs: AtollStyle.settleDuration + 120
        component: AtollStudio {}
    }

    OnDemandPanelLoader {
        identifier: "atollSettings"
        requireEnabledPanel: false
        open: !root.settingsWindowed && (GlobalStates.settingsOverlayOpen || GlobalStates.atollSettingsWarm)
        closeGraceMs: AtollStyle.settleDuration + 120
        component: AtollSettingsOverlay {}
    }

    readonly property bool settingsWindowed: (Config.options?.atoll?.appearance?.settingsHost ?? "overlay") === "window"
    OnDemandPanelLoader {
        identifier: "atollSettingsWindow"
        requireEnabledPanel: false
        open: root.settingsWindowed && GlobalStates.settingsOverlayOpen
        closeGraceMs: 0
        component: AtollSettingsWindow {}
    }

    LazyLoader {
        activeAsync: Config.ready && AtollGate.official && GlobalStates.deferredPanelsReady
            && CompositorService.isNiri
            && (Config.options?.background?.backdrop?.enable ?? false)
        source: "../background/Backdrop.qml"
    }

    LazyLoader {
        activeAsync: Config.ready && AtollGate.official && GlobalStates.deferredPanelsReady
            && (Config.options?.enabledPanels ?? []).includes("atollBackground")
            && (Config.options?.atoll?.modules?.desktopWidgets ?? true)
        component: Background {}
    }

    PanelLoader {
        identifier: "atollOnScreenDisplay"
        extraCondition: (Config.options?.atoll?.modules?.osd ?? true)
            && (!GlobalStates.barOpen
                || (CompositorService.isNiri && GameMode.hasFullscreenOnOutput(GlobalStates.focusedScreen?.name ?? "") && !NiriService.inOverview)
                || !(Config.options?.enabledPanels ?? []).includes("atollBar")
                || ((Config.options?.atoll?.bar?.screenList ?? []).length > 0
                    && !(Config.options.atoll.bar.screenList).includes(GlobalStates.focusedScreen?.name ?? "")))
        component: AtollOSD {}
    }

    OnDemandPanelLoader {
        identifier: "atollSessionScreen"
        open: GlobalStates.sessionOpen
        extraCondition: Config.options?.atoll?.modules?.sessionScreen ?? true
        component: AtollSessionScreen {}
    }

    DeferredPanelLoader {
        identifier: "atollLock"
        extraCondition: Config.options?.atoll?.modules?.lock ?? true
        component: Lock {}
    }

    DeferredPanelLoader {
        identifier: "atollPolkit"
        extraCondition: Config.options?.atoll?.modules?.polkit ?? true
        component: AtollPolkit {}
    }

    OnDemandPanelLoader {
        identifier: "atollOverlay"
        open: GlobalStates.overlayOpen
        requireEnabledPanel: false
        closeGraceMs: AtollStyle.settleDuration + 120
        source: "../drift/overlay/Overlay.qml"
    }

    OnDemandPanelLoader {
        identifier: "atollCheatsheet"
        open: GlobalStates.cheatsheetOpen
        requireEnabledPanel: false
        source: "../cheatsheet/Cheatsheet.qml"
    }

    OnDemandPanelLoader {
        identifier: "atollOnScreenKeyboard"
        open: GlobalStates.oskOpen
        requireEnabledPanel: false
        closeGraceMs: AtollStyle.settleDuration + 80
        component: AtollOnScreenKeyboard {}
    }

    OnDemandPanelLoader {
        identifier: "atollRegionSelector"
        open: GlobalStates.regionSelectorOpen || GlobalStates.annotationEditorOpen
        requireEnabledPanel: false
        source: "../regionSelector/RegionSelector.qml"
    }


    OnDemandPanelLoader {
        identifier: "atollLockRehearsal"
        open: GlobalStates.atollLockEdit
        requireEnabledPanel: false
        component: AtollLockRehearsal {}
    }

    OnDemandPanelLoader {
        identifier: "atollWallpaperLauncher"
        open: GlobalStates.wallpaperLauncherOpen
        requireEnabledPanel: false
        source: "../wallpaperLauncher/WallpaperLauncher.qml"
    }

    OnDemandPanelLoader {
        identifier: "atollCoverflowSelector"
        open: GlobalStates.coverflowSelectorOpen
        requireEnabledPanel: false
        source: "../wallpaperSelector/WallpaperCoverflow.qml"
    }

    OnDemandPanelLoader {
        identifier: "atollRecordingOsd"
        open: RecorderStatus.isRecording
        requireEnabledPanel: false
        extraCondition: !(GlobalStates.barOpen
            && (Config.options?.enabledPanels ?? []).includes("atollBar"))
        source: "../recordingOsd/RecordingOsd.qml"
    }

    OnDemandPanelLoader {
        identifier: "atollTilingOverlay"
        open: GlobalStates.tilingOverlayPickerOpen || GlobalStates.tilingOverlayOsdOpen
        requireEnabledPanel: false
        source: "../tilingOverlay/TilingOverlay.qml"
    }
}
