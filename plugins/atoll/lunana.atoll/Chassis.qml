pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import "../../lunana-vendor/modules/common" as LnCommon
import "../../lunana-vendor/modules/atoll/bar" as LnBar
import "../../lunana-vendor/modules/atoll/frame" as LnFrame
import "../../lunana-vendor/modules/atoll/background" as LnAtollBg

// Mirrors vendor/modules/atoll/critical/ShellAtollCriticalPanels.qml.
//
// The real Atoll chassis: AtollBar brings the island, dock, control centre,
// spotlight, gallery, orbit, edit bar, stage and banners in ONE surface with
// the full input mask (island extension/menu/notch zones, dock hitItem, the 24
// desktop-piece hit regions from AtollStage, armed-state → full input, and
// outside-click/Escape dismiss) plus every bit of gating. Mounted directly:
// omarchy-shell is not lunana's host, so AtollGate.official is false and lunana's
// own CriticalPanelLoader would gate this off. AtollReservations reserves the
// island/dock edge space (reserve() includes the island depth because the
// chassis is present) so tiled windows warp around them.
Item {
    id: root

    readonly property bool desktopWidgets: LnCommon.Config.options?.atoll?.modules?.desktopWidgets ?? true
    // Mirrors lunana's CriticalPanelLoader gating (Config.ready; AtollGate.official
    // is false in the re-host so it is dropped, but readiness + the atollBar
    // identifier are kept): no chassis, reservations, or background before
    // the config is ready, and trimming atollBar out of enabledPanels stands
    // the bar down like lunana.
    readonly property bool barEnabled: LnCommon.Config.ready
        && (LnCommon.Config.options?.enabledPanels ?? []).includes("atollBar")

    Loader {
        active: LnCommon.Config.ready
        sourceComponent: Component { LnFrame.AtollReservations {} }
    }

    // Background without desktop widgets (the widgets-on path mounts the shared
    // Background in Panels.qml, matching lunana). Identifier gate mirrors lunana's
    // CriticalPanelLoader("atollBackground").
    Loader {
        active: LnCommon.Config.ready
            && (LnCommon.Config.options?.enabledPanels ?? []).includes("atollBackground")
            && !root.desktopWidgets
        sourceComponent: Component { LnAtollBg.AtollBackground {} }
    }

    Loader {
        active: root.barEnabled
        sourceComponent: Component { LnBar.AtollBar {} }
    }
}
