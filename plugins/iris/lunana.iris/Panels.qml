pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import "../../lunana-vendor/" as Inir
import "../../lunana-vendor/modules/common" as LnCommon
import "../../lunana-vendor/services" as LnServ
import "../../lunana-vendor/modules/iris/style" as LnStyle
import "../../lunana-vendor/modules/iris/sidebar" as LnSidebar
import "../../lunana-vendor/modules/iris/settings" as LnSettings
import "../../lunana-vendor/modules/iris/session" as LnSession
import "../../lunana-vendor/modules/iris/onScreenDisplay" as LnOsd
import "../../lunana-vendor/modules/iris/notificationPopup" as LnNotifications
import "../../lunana-vendor/modules/iris/orbit" as LnOrbit
import "../../lunana-vendor/modules/iris/studio" as LnStudio
import "../../lunana-vendor/modules/iris/osk" as LnOsk
import "../../lunana-vendor/modules/iris/polkit" as LnPolkit
import "../../lunana-vendor/modules/iris/lock" as LnIrisLock
import "../../lunana-vendor/modules/lock" as LnLock
import "../../lunana-vendor/modules/background" as LnBg
import "../../lunana-vendor/modules/cheatsheet" as LnCheat
import "../../lunana-vendor/modules/regionSelector" as LnRegion
import "../../lunana-vendor/modules/wallpaperLauncher" as LnWallLauncher
import "../../lunana-vendor/modules/wallpaperSelector" as LnWallSel
import "../../lunana-vendor/modules/recordingOsd" as LnRec
import "../../lunana-vendor/modules/tilingOverlay" as LnTiling
import "../../lunana-vendor/modules/ii/overlay" as LnOverlay

// Mirrors inir/modules/iris/ShellIrisPanelsImpl.qml — the iRiS panel set that
// lives beside the chassis. Mounted directly (bypassing the IrisGate.official
// loaders, false in the re-host) while keeping each panel's real open-condition
// and module gating. The chassis owns notifications (banners), OSD feedback,
// dock, control, spotlight, orbit, edit and stage, so those are not re-mounted
// here (inir only mounts a standalone OSD/notification popup when the bar is
// absent, which it never is in this family).
Item {
    id: root

    readonly property var opts: LnCommon.Config.options ?? ({})
    readonly property var enabledPanels: root.opts.enabledPanels ?? []
    readonly property bool desktopWidgets: root.opts?.iris?.modules?.desktopWidgets ?? true
    readonly property bool settingsWindowed: (root.opts?.iris?.appearance?.settingsHost ?? "overlay") === "window"
    readonly property bool irisBarEnabled: root.enabledPanels.includes("irisBar")

    // Re-host inir's on-demand panel lifecycle without IrisGate. The grace
    // period keeps a closing panel alive through its native exit animation.
    component OnDemandPanelLoader: Loader {
        id: loader

        required property string identifier
        required property bool open
        property bool extraCondition: true
        property bool requireEnabledPanel: true
        property int closeGraceMs: LnStyle.IrisStyle.revealDuration + 30
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

    LnStyle.IrisAppsSync {}

    // Orbit hot corner.
    Loader {
        active: (root.opts?.iris?.orbit?.enable ?? false) && (root.opts?.iris?.orbit?.hotCorner ?? true)
        sourceComponent: Component { LnOrbit.IrisOrbitCorner {} }
    }

    // Sidebar edge reveal strips (always).
    LnSidebar.IrisSidebarEdge { side: "left" }
    LnSidebar.IrisSidebarEdge { side: "right" }

    // Focus / today side panels.
    OnDemandPanelLoader {
        identifier: "irisSidebarLeft"
        requireEnabledPanel: false
        open: Inir.GlobalStates.sidebarLeftOpen
        extraCondition: root.opts?.iris?.sidebars?.left?.enable ?? true
        closeGraceMs: LnStyle.IrisStyle.settleDuration + 80
        sourceComponent: Component { LnSidebar.IrisSidebar { side: "left" } }
    }
    OnDemandPanelLoader {
        identifier: "irisSidebarRight"
        requireEnabledPanel: false
        open: Inir.GlobalStates.sidebarRightOpen
        extraCondition: root.opts?.iris?.sidebars?.right?.enable ?? true
        closeGraceMs: LnStyle.IrisStyle.settleDuration + 80
        sourceComponent: Component { LnSidebar.IrisSidebar { side: "right" } }
    }

    // Settings — overlay by default, window host when chosen.
    OnDemandPanelLoader {
        identifier: "irisSettings"
        requireEnabledPanel: false
        open: !root.settingsWindowed && (Inir.GlobalStates.settingsOverlayOpen || Inir.GlobalStates.irisSettingsWarm)
        closeGraceMs: LnStyle.IrisStyle.settleDuration + 120
        sourceComponent: Component { LnSettings.IrisSettingsOverlay {} }
    }
    OnDemandPanelLoader {
        identifier: "irisSettingsWindow"
        requireEnabledPanel: false
        open: root.settingsWindowed && Inir.GlobalStates.settingsOverlayOpen
        closeGraceMs: 0
        sourceComponent: Component { LnSettings.IrisSettingsWindow {} }
    }

    // Session screen.
    OnDemandPanelLoader {
        identifier: "irisSessionScreen"
        open: Inir.GlobalStates.sessionOpen
        extraCondition: root.opts?.iris?.modules?.sessionScreen ?? true
        sourceComponent: Component { LnSession.IrisSessionScreen {} }
    }

    // OSD (its own internal show/hide on the GlobalStates.osd*Open flags).
    Loader {
        active: LnCommon.Config.ready && (root.opts?.iris?.modules?.osd ?? true)
            && (!Inir.GlobalStates.barOpen
                || (LnServ.CompositorService.isNiri
                    && LnServ.GameMode.hasFullscreenOnOutput(Inir.GlobalStates.focusedScreen?.name ?? "")
                    && !LnServ.NiriService.inOverview)
                || !root.irisBarEnabled
                || ((root.opts?.iris?.bar?.screenList ?? []).length > 0
                    && !(root.opts.iris.bar.screenList).includes(Inir.GlobalStates.focusedScreen?.name ?? "")))
        sourceComponent: Component { LnOsd.IrisOSD {} }
    }

    // The island's banners handle normal notifications. This fallback is for
    // a missing chassis or a fullscreen Niri output, like inir's own loader.
    OnDemandPanelLoader {
        identifier: "irisNotificationPopup"
        open: (LnServ.Notifications.popupList?.length ?? 0) > 0
        closeGraceMs: LnStyle.IrisStyle.settleDuration * 2 + 160
        extraCondition: (root.opts?.iris?.modules?.notificationPopup ?? true)
            && (!root.irisBarEnabled
                || (LnServ.CompositorService.isNiri
                    && LnServ.GameMode.hasFullscreenOnOutput(Inir.GlobalStates.focusedScreen?.name ?? "")
                    && !LnServ.NiriService.inOverview
                    && (root.opts?.iris?.notifications?.fullscreen ?? true)))
        sourceComponent: Component { LnNotifications.IrisNotificationPopup {} }
    }

    // Lock + polkit (resident).
    Loader {
        active: root.opts?.iris?.modules?.lock ?? true
        sourceComponent: Component { LnLock.Lock {} }
    }
    Loader {
        active: root.opts?.iris?.modules?.polkit ?? true
        sourceComponent: Component { LnPolkit.IrisPolkit {} }
    }

    // Desktop background with widgets (the no-widgets path is in Chassis.qml).
    Loader {
        active: root.desktopWidgets
        sourceComponent: Component { LnBg.Background {} }
    }

    // Studio / on-screen keyboard / lock rehearsal.
    OnDemandPanelLoader {
        identifier: "irisStudio"
        requireEnabledPanel: false
        open: Inir.GlobalStates.irisStudioOpen
        closeGraceMs: LnStyle.IrisStyle.settleDuration + 120
        sourceComponent: Component { LnStudio.IrisStudio {} }
    }
    OnDemandPanelLoader {
        identifier: "irisOnScreenKeyboard"
        requireEnabledPanel: false
        open: Inir.GlobalStates.oskOpen
        closeGraceMs: LnStyle.IrisStyle.settleDuration + 80
        sourceComponent: Component { LnOsk.IrisOnScreenKeyboard {} }
    }
    OnDemandPanelLoader {
        identifier: "irisLockRehearsal"
        requireEnabledPanel: false
        open: Inir.GlobalStates.irisLockEdit
        sourceComponent: Component { LnIrisLock.IrisLockRehearsal {} }
    }

    // Cheatsheet / overlay / region / wallpaper / recording / tiling.
    OnDemandPanelLoader {
        identifier: "irisCheatsheet"
        requireEnabledPanel: false
        open: Inir.GlobalStates.cheatsheetOpen
        sourceComponent: Component { LnCheat.Cheatsheet {} }
    }
    OnDemandPanelLoader {
        identifier: "irisOverlay"
        requireEnabledPanel: false
        open: Inir.GlobalStates.overlayOpen
        closeGraceMs: LnStyle.IrisStyle.settleDuration + 120
        sourceComponent: Component { LnOverlay.Overlay {} }
    }
    OnDemandPanelLoader {
        identifier: "irisRegionSelector"
        requireEnabledPanel: false
        open: Inir.GlobalStates.regionSelectorOpen || Inir.GlobalStates.annotationEditorOpen
        sourceComponent: Component { LnRegion.RegionSelector {} }
    }
    OnDemandPanelLoader {
        identifier: "irisWallpaperLauncher"
        requireEnabledPanel: false
        open: Inir.GlobalStates.wallpaperLauncherOpen
        sourceComponent: Component { LnWallLauncher.WallpaperLauncher {} }
    }
    OnDemandPanelLoader {
        identifier: "irisCoverflowSelector"
        requireEnabledPanel: false
        open: Inir.GlobalStates.coverflowSelectorOpen
        sourceComponent: Component { LnWallSel.WallpaperCoverflow {} }
    }
    OnDemandPanelLoader {
        identifier: "irisRecordingOsd"
        requireEnabledPanel: false
        open: LnServ.RecorderStatus.isRecording
        extraCondition: !(Inir.GlobalStates.barOpen && root.irisBarEnabled)
        sourceComponent: Component { LnRec.RecordingOsd {} }
    }
    OnDemandPanelLoader {
        identifier: "irisTilingOverlay"
        requireEnabledPanel: false
        open: Inir.GlobalStates.tilingOverlayPickerOpen || Inir.GlobalStates.tilingOverlayOsdOpen
        sourceComponent: Component { LnTiling.TilingOverlay {} }
    }
}
