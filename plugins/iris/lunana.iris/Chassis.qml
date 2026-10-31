pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import "../../lunana-vendor/modules/common" as LnCommon
import "../../lunana-vendor/modules/iris/bar" as LnBar
import "../../lunana-vendor/modules/iris/frame" as LnFrame
import "../../lunana-vendor/modules/iris/background" as LnIrisBg

// Mirrors inir/modules/iris/critical/ShellIrisCriticalPanels.qml.
//
// The real iRiS chassis: IrisBar brings the island, dock, control centre,
// spotlight, gallery, orbit, edit bar, stage and banners in ONE surface with
// the full input mask (island extension/menu/notch zones, dock hitItem, the 24
// desktop-piece hit regions from IrisStage, armed-state → full input, and
// outside-click/Escape dismiss) plus every bit of gating. Mounted directly:
// omarchy-shell is not inir's host, so IrisGate.official is false and inir's
// own CriticalPanelLoader would gate this off. IrisReservations reserves the
// island/dock edge space (reserve() includes the island depth because the
// chassis is present) so tiled windows warp around them.
Item {
    id: root

    readonly property bool desktopWidgets: LnCommon.Config.options?.iris?.modules?.desktopWidgets ?? true

    LnFrame.IrisReservations {}

    // Background without desktop widgets (the widgets-on path mounts the shared
    // Background in Panels.qml, matching inir).
    Loader {
        active: !root.desktopWidgets
        sourceComponent: Component { LnIrisBg.IrisBackground {} }
    }

    LnBar.IrisBar {}
}
