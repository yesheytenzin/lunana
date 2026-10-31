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
    readonly property bool desktopWidgets: root.opts?.iris?.modules?.desktopWidgets ?? true
    readonly property bool settingsWindowed: (root.opts?.iris?.appearance?.settingsHost ?? "overlay") === "window"

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
    Loader {
        active: Inir.GlobalStates.sidebarLeftOpen && (root.opts?.iris?.sidebars?.left?.enable ?? true)
        sourceComponent: Component { LnSidebar.IrisSidebar { side: "left" } }
    }
    Loader {
        active: Inir.GlobalStates.sidebarRightOpen && (root.opts?.iris?.sidebars?.right?.enable ?? true)
        sourceComponent: Component { LnSidebar.IrisSidebar { side: "right" } }
    }

    // Settings — overlay by default, window host when chosen.
    Loader {
        active: !root.settingsWindowed && (Inir.GlobalStates.settingsOverlayOpen || Inir.GlobalStates.irisSettingsWarm)
        sourceComponent: Component { LnSettings.IrisSettingsOverlay {} }
    }
    Loader {
        active: root.settingsWindowed && Inir.GlobalStates.settingsOverlayOpen
        sourceComponent: Component { LnSettings.IrisSettingsWindow {} }
    }

    // Session screen.
    Loader {
        active: Inir.GlobalStates.sessionOpen && (root.opts?.iris?.modules?.sessionScreen ?? true)
        sourceComponent: Component { LnSession.IrisSessionScreen {} }
    }

    // OSD (its own internal show/hide on the GlobalStates.osd*Open flags).
    Loader {
        active: root.opts?.iris?.modules?.osd ?? true
        sourceComponent: Component { LnOsd.IrisOSD {} }
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
    Loader {
        active: Inir.GlobalStates.irisStudioOpen
        sourceComponent: Component { LnStudio.IrisStudio {} }
    }
    Loader {
        active: Inir.GlobalStates.oskOpen
        sourceComponent: Component { LnOsk.IrisOnScreenKeyboard {} }
    }
    Loader {
        active: Inir.GlobalStates.irisLockEdit
        sourceComponent: Component { LnIrisLock.IrisLockRehearsal {} }
    }

    // Cheatsheet / overlay / region / wallpaper / recording / tiling.
    Loader {
        active: Inir.GlobalStates.cheatsheetOpen
        sourceComponent: Component { LnCheat.Cheatsheet {} }
    }
    Loader {
        active: Inir.GlobalStates.overlayOpen
        sourceComponent: Component { LnOverlay.Overlay {} }
    }
    Loader {
        active: Inir.GlobalStates.regionSelectorOpen || Inir.GlobalStates.annotationEditorOpen
        sourceComponent: Component { LnRegion.RegionSelector {} }
    }
    Loader {
        active: Inir.GlobalStates.wallpaperLauncherOpen
        sourceComponent: Component { LnWallLauncher.WallpaperLauncher {} }
    }
    Loader {
        active: Inir.GlobalStates.coverflowSelectorOpen
        sourceComponent: Component { LnWallSel.WallpaperCoverflow {} }
    }
    Loader {
        active: LnServ.RecorderStatus.isRecording
        sourceComponent: Component { LnRec.RecordingOsd {} }
    }
    Loader {
        active: Inir.GlobalStates.tilingOverlayPickerOpen || Inir.GlobalStates.tilingOverlayOsdOpen
        sourceComponent: Component { LnTiling.TilingOverlay {} }
    }
}
