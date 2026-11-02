pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../lunana-vendor/" as Lunana
import "../../lunana-vendor/modules/atoll/frame" as LnFrame

// lunana.atoll-reservations — edge-space reservations for the Atoll family. (kind: service).
//
// DORMANT satellite: family-cycle enables only the consolidated lunana.atoll
// plugin (whose Chassis.qml already mounts lunana's AtollReservations with
// reserve()), so this host is never active alongside it — enabling both
// would double-reserve every edge. Kept for standalone use without the
// consolidated chassis: it reserves the resting VISUAL footprint via
// AtollFrame.inset(edge) — band + island visual depth on the island edge,
// dock visual depth on the dock edge — NOT reserve(edge, chassisPresent),
// whose island term needs a chassis this standalone host cannot assume.
// Sidebar depth is reserved when a sidebar is pinned with reserveSpace,
// mirroring lunana's AtollReservations.sidebarDepth exactly. Stubs live on the
// Background layer with an empty input mask, so they take no input and paint
// nothing.
Scope {
    id: root

    property var shell: null
    property var manifest: null

    Variants {
        model: Quickshell.screens

        delegate: Scope {
            id: screenScope
            required property var modelData
            readonly property string outputName: screenScope.modelData?.name ?? ""
            readonly property var leftSidebar: Lunana.Config.options?.atoll?.sidebars?.left ?? ({})
            readonly property var rightSidebar: Lunana.Config.options?.atoll?.sidebars?.right ?? ({})

            function sidebarDepth(edge: string): real {
                const left = edge === "left"
                if (!left && edge !== "right") return 0
                const options = left ? screenScope.leftSidebar : screenScope.rightSidebar
                const open = left ? Lunana.GlobalStates.sidebarLeftOpen : Lunana.GlobalStates.sidebarRightOpen
                const output = left ? Lunana.GlobalStates.sidebarLeftPresentationOutput : Lunana.GlobalStates.sidebarRightPresentationOutput
                if (Lunana.GlobalStates.screenLocked || !open || !(options?.enable ?? true)
                        || !(options?.pinned ?? false) || !(options?.reserveSpace ?? true)
                        || output !== screenScope.outputName) return 0
                const width = Math.max(300, Math.min(600, Number(options?.width ?? 380))) * LnFrame.AtollFrame.d
                const held = LnFrame.AtollFrame.clear(edge) - LnFrame.AtollFrame.band
                const air = (options?.notch ?? false) && held <= 0 ? 0 : 12 * LnFrame.AtollFrame.d
                return Math.round(LnFrame.AtollFrame.band + held + width + air)
            }

            component Reservation: PanelWindow {
                id: stub
                required property string edge
                screen: screenScope.modelData
                visible: true
                color: "transparent"
                WlrLayershell.namespace: "lunana-atoll-reserve-" + stub.edge
                WlrLayershell.layer: WlrLayer.Background
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
                exclusionMode: ExclusionMode.Normal
                exclusiveZone: Math.max(LnFrame.AtollFrame.inset(stub.edge), screenScope.sidebarDepth(stub.edge))
                // One edge only: opposite-edge anchors lose the exclusive zone.
                anchors {
                    top: stub.edge === "top"
                    bottom: stub.edge === "bottom"
                    left: stub.edge === "left"
                    right: stub.edge === "right"
                }
                implicitWidth: 1
                implicitHeight: 1
                mask: Region {}
            }

            Reservation { edge: "top" }
            Reservation { edge: "bottom" }
            Reservation { edge: "left" }
            Reservation { edge: "right" }
        }
    }

    // Shell-entry handshake against the shared lunana-vendor/ tree (one
    // GlobalStates universe for all hosts): the vendored
    // tree gates on shellEntryReady/deferredPanelsReady, which only lunana's
    // shell.qml boot sets. Mirror the minimal sequence here.
    Timer {
        interval: 200; repeat: false; running: true
        onTriggered: {
            Lunana.GlobalStates.shellEntryReady = true;
            Lunana.GlobalStates.deferredPanelsReady = true;
        }
    }
}
