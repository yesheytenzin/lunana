pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import "../../lunana-vendor/" as Lunana
import "../../lunana-vendor/modules/common" as LnCommon
import "../../lunana-vendor/services" as LnServ
import "../../lunana-vendor/modules/atoll/style" as LnStyle
import "../../lunana-vendor/modules/atoll/sidebar" as LnSidebar
import "../../lunana-vendor/modules/atoll/settings" as LnSettings
import "../../lunana-vendor/modules/atoll/session" as LnSession
import "../../lunana-vendor/modules/atoll/onScreenDisplay" as LnOsd
import "../../lunana-vendor/modules/atoll/notificationPopup" as LnNotifications
import "../../lunana-vendor/modules/atoll/orbit" as LnOrbit
import "../../lunana-vendor/modules/atoll/studio" as LnStudio
import "../../lunana-vendor/modules/atoll/osk" as LnOsk
import "../../lunana-vendor/modules/atoll/polkit" as LnPolkit
import "../../lunana-vendor/modules/atoll/lock" as LnAtollLock
import "../../lunana-vendor/modules/lock" as LnLock
import "../../lunana-vendor/modules/background" as LnBg
import "../../lunana-vendor/modules/cheatsheet" as LnCheat
import "../../lunana-vendor/modules/regionSelector" as LnRegion
import "../../lunana-vendor/modules/wallpaperLauncher" as LnWallLauncher
import "../../lunana-vendor/modules/wallpaperSelector" as LnWallSel
import "../../lunana-vendor/modules/recordingOsd" as LnRec
import "../../lunana-vendor/modules/tilingOverlay" as LnTiling
import "../../lunana-vendor/modules/drift/overlay" as LnOverlay

// Mirrors lunana/modules/atoll/ShellIrisPanelsImpl.qml — the Atoll panel set that
// lives beside the chassis. Mounted directly (bypassing the AtollGate.official
// loaders, false in the re-host) while keeping each panel's real open-condition
// and module gating. The chassis owns notifications (banners), OSD feedback,
// dock, control, spotlight, orbit, edit and stage, so those are not re-mounted
// here (lunana only mounts a standalone OSD/notification popup when the bar is
// absent, which it never is in this family).
Item {
    id: root

    readonly property var opts: LnCommon.Config.options ?? ({})
    readonly property var enabledPanels: root.opts.enabledPanels ?? []
    readonly property bool desktopWidgets: root.opts?.atoll?.modules?.desktopWidgets ?? true
    readonly property bool settingsWindowed: (root.opts?.atoll?.appearance?.settingsHost ?? "overlay") === "window"
    readonly property bool atollBarEnabled: root.enabledPanels.includes("atollBar")

    // Re-host lunana's on-demand panel lifecycle without AtollGate. The grace
    // period keeps a closing panel alive through its native exit animation.
    component OnDemandPanelLoader: Loader {
        id: loader

        required property string identifier
        required property bool open
        property bool extraCondition: true
        property bool requireEnabledPanel: true
        property int closeGraceMs: LnStyle.AtollStyle.revealDuration + 30
        property bool resident: open
        readonly property bool enabledPanel: LnCommon.Config.ready
            && (!loader.requireEnabledPanel || root.enabledPanels.includes(loader.identifier))
            && loader.extraCondition

        Timer {
            id: closeGrace
            interval: loader.closeGraceMs
            onTriggered: loader.resident = loader.open
        }

        onOpenChanged: {
            if (open) {
                closeGrace.stop()
                resident = true
            } else {
                closeGrace.restart()
            }
        }

        active: loader.enabledPanel && loader.resident
    }

    LnStyle.AtollAppsSync {}

    // Orbit hot corner.
    Loader {
        active: (root.opts?.atoll?.orbit?.enable ?? false) && (root.opts?.atoll?.orbit?.hotCorner ?? true)
        sourceComponent: Component { LnOrbit.AtollOrbitCorner {} }
    }

    // Sidebar edge reveal strips (always).
    LnSidebar.AtollSidebarEdge { side: "left" }
    LnSidebar.AtollSidebarEdge { side: "right" }

    // Focus / today side panels.
    OnDemandPanelLoader {
        identifier: "atollSidebarLeft"
        requireEnabledPanel: false
        open: Lunana.GlobalStates.sidebarLeftOpen
        extraCondition: root.opts?.atoll?.sidebars?.left?.enable ?? true
        closeGraceMs: LnStyle.AtollStyle.settleDuration + 80
        sourceComponent: Component { LnSidebar.AtollSidebar { side: "left" } }
    }
    OnDemandPanelLoader {
        identifier: "atollSidebarRight"
        requireEnabledPanel: false
        open: Lunana.GlobalStates.sidebarRightOpen
        extraCondition: root.opts?.atoll?.sidebars?.right?.enable ?? true
        closeGraceMs: LnStyle.AtollStyle.settleDuration + 80
        sourceComponent: Component { LnSidebar.AtollSidebar { side: "right" } }
    }

    // Settings — overlay by default, window host when chosen.
    OnDemandPanelLoader {
        identifier: "atollSettings"
        requireEnabledPanel: false
        open: !root.settingsWindowed && (Lunana.GlobalStates.settingsOverlayOpen || Lunana.GlobalStates.atollSettingsWarm)
        closeGraceMs: LnStyle.AtollStyle.settleDuration + 120
        sourceComponent: Component { LnSettings.AtollSettingsOverlay {} }
    }
    OnDemandPanelLoader {
        identifier: "atollSettingsWindow"
        requireEnabledPanel: false
        open: root.settingsWindowed && Lunana.GlobalStates.settingsOverlayOpen
        closeGraceMs: 0
        sourceComponent: Component { LnSettings.AtollSettingsWindow {} }
    }

    // Session screen.
    OnDemandPanelLoader {
        identifier: "atollSessionScreen"
        open: Lunana.GlobalStates.sessionOpen
        extraCondition: root.opts?.atoll?.modules?.sessionScreen ?? true
        sourceComponent: Component { LnSession.AtollSessionScreen {} }
    }

    // OSD (its own internal show/hide on the GlobalStates.osd*Open flags).
    // Identifier gate mirrors lunana's PanelLoader("atollOnScreenDisplay").
    Loader {
        active: LnCommon.Config.ready && root.enabledPanels.includes("atollOnScreenDisplay")
            && (root.opts?.atoll?.modules?.osd ?? true)
            && (!Lunana.GlobalStates.barOpen
                || (LnServ.CompositorService.isNiri
                    && LnServ.GameMode.hasFullscreenOnOutput(Lunana.GlobalStates.focusedScreen?.name ?? "")
                    && !LnServ.NiriService.inOverview)
                || !root.atollBarEnabled
                || ((root.opts?.atoll?.bar?.screenList ?? []).length > 0
                    && !(root.opts.atoll.bar.screenList).includes(Lunana.GlobalStates.focusedScreen?.name ?? "")))
        sourceComponent: Component { LnOsd.AtollOSD {} }
    }

    // The island's banners handle normal notifications. This fallback is for
    // a missing chassis or a fullscreen Niri output, like lunana's own loader.
    OnDemandPanelLoader {
        identifier: "atollNotificationPopup"
        open: (LnServ.Notifications.popupList?.length ?? 0) > 0
        closeGraceMs: LnStyle.AtollStyle.settleDuration * 2 + 160
        extraCondition: (root.opts?.atoll?.modules?.notificationPopup ?? true)
            && (!root.atollBarEnabled
                || (LnServ.CompositorService.isNiri
                    && LnServ.GameMode.hasFullscreenOnOutput(Lunana.GlobalStates.focusedScreen?.name ?? "")
                    && !LnServ.NiriService.inOverview
                    && (root.opts?.atoll?.notifications?.fullscreen ?? true)))
        sourceComponent: Component { LnNotifications.AtollNotificationPopup {} }
    }

    // Lock + polkit (resident). Identifier gates mirror lunana's
    // DeferredPanelLoader("atollLock") / ("atollPolkit").
    Loader {
        active: LnCommon.Config.ready && root.enabledPanels.includes("atollLock")
            && (root.opts?.atoll?.modules?.lock ?? true)
        sourceComponent: Component { LnLock.Lock {} }
    }
    Loader {
        active: LnCommon.Config.ready && root.enabledPanels.includes("atollPolkit")
            && (root.opts?.atoll?.modules?.polkit ?? true)
        sourceComponent: Component { LnPolkit.AtollPolkit {} }
    }

    // Desktop background with widgets (the no-widgets path is in Chassis.qml).
    // Identifier gate mirrors lunana (atollBackground + desktopWidgets).
    // Niri-only background/backdrop path is intentionally omitted on Hyprland.
    Loader {
        active: LnCommon.Config.ready && root.enabledPanels.includes("atollBackground")
            && root.desktopWidgets
        sourceComponent: Component { LnBg.Background {} }
    }

    // Studio / on-screen keyboard / lock rehearsal.
    OnDemandPanelLoader {
        identifier: "atollStudio"
        requireEnabledPanel: false
        open: Lunana.GlobalStates.atollStudioOpen
        closeGraceMs: LnStyle.AtollStyle.settleDuration + 120
        sourceComponent: Component { LnStudio.AtollStudio {} }
    }
    OnDemandPanelLoader {
        identifier: "atollOnScreenKeyboard"
        requireEnabledPanel: false
        open: Lunana.GlobalStates.oskOpen
        closeGraceMs: LnStyle.AtollStyle.settleDuration + 80
        sourceComponent: Component { LnOsk.AtollOnScreenKeyboard {} }
    }
    OnDemandPanelLoader {
        identifier: "atollLockRehearsal"
        requireEnabledPanel: false
        open: Lunana.GlobalStates.atollLockEdit
        sourceComponent: Component { LnAtollLock.AtollLockRehearsal {} }
    }

    // Cheatsheet / overlay / region / wallpaper / recording / tiling.
    OnDemandPanelLoader {
        identifier: "atollCheatsheet"
        requireEnabledPanel: false
        open: Lunana.GlobalStates.cheatsheetOpen
        sourceComponent: Component { LnCheat.Cheatsheet {} }
    }
    OnDemandPanelLoader {
        identifier: "atollOverlay"
        requireEnabledPanel: false
        open: Lunana.GlobalStates.overlayOpen
        closeGraceMs: LnStyle.AtollStyle.settleDuration + 120
        sourceComponent: Component { LnOverlay.Overlay {} }
    }
    OnDemandPanelLoader {
        identifier: "atollRegionSelector"
        requireEnabledPanel: false
        open: Lunana.GlobalStates.regionSelectorOpen || Lunana.GlobalStates.annotationEditorOpen
        sourceComponent: Component { LnRegion.RegionSelector {} }
    }
    OnDemandPanelLoader {
        identifier: "atollWallpaperLauncher"
        requireEnabledPanel: false
        open: Lunana.GlobalStates.wallpaperLauncherOpen
        sourceComponent: Component { LnWallLauncher.WallpaperLauncher {} }
    }
    OnDemandPanelLoader {
        identifier: "atollCoverflowSelector"
        requireEnabledPanel: false
        open: Lunana.GlobalStates.coverflowSelectorOpen
        sourceComponent: Component { LnWallSel.WallpaperCoverflow {} }
    }
    OnDemandPanelLoader {
        identifier: "atollRecordingOsd"
        requireEnabledPanel: false
        open: LnServ.RecorderStatus.isRecording
        extraCondition: !(Lunana.GlobalStates.barOpen && root.atollBarEnabled)
        sourceComponent: Component { LnRec.RecordingOsd {} }
    }
    OnDemandPanelLoader {
        identifier: "atollTilingOverlay"
        requireEnabledPanel: false
        open: Lunana.GlobalStates.tilingOverlayPickerOpen || Lunana.GlobalStates.tilingOverlayOsdOpen
        sourceComponent: Component { LnTiling.TilingOverlay {} }
    }
}
