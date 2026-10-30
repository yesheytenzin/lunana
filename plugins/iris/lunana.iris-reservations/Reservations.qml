pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../lunana-vendor/" as Inir
import "../../lunana-vendor/modules/iris/frame" as LnFrame

// lunana.iris-reservations — edge-space reservations for the iRiS family. (kind: service).
//
// In native iRiS the IrisBar chassis hosts inir's IrisReservations, whose
// invisible Background-layer stubs reserve an exclusive zone at each screen
// edge so tiled windows warp around the island, dock and pinned sidebars.
// Lunana runs the satellite model (Option A — no monolithic chassis), so
// IrisReservations is never instantiated and apps open underneath the island,
// dock and side panels. This host supplies the reservation directly.
//
// It reserves the resting VISUAL footprint via IrisFrame.inset(edge) — band +
// island visual depth on the island edge, dock visual depth on the dock edge —
// NOT reserve(edge, chassisPresent), whose island term is gated on a chassis we
// do not run (so reserve() would leave the island edge unreserved here). Sidebar
// depth is reserved when a sidebar is pinned with reserveSpace, mirroring inir's
// IrisReservations.sidebarDepth exactly. Stubs live on the Background layer with
// an empty input mask, so they take no input and paint nothing.
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
            readonly property var leftSidebar: Inir.Config.options?.iris?.sidebars?.left ?? ({})
            readonly property var rightSidebar: Inir.Config.options?.iris?.sidebars?.right ?? ({})

            function sidebarDepth(edge: string): real {
                const left = edge === "left"
                if (!left && edge !== "right") return 0
                const options = left ? screenScope.leftSidebar : screenScope.rightSidebar
                const open = left ? Inir.GlobalStates.sidebarLeftOpen : Inir.GlobalStates.sidebarRightOpen
                const output = left ? Inir.GlobalStates.sidebarLeftPresentationOutput : Inir.GlobalStates.sidebarRightPresentationOutput
                if (Inir.GlobalStates.screenLocked || !open || !(options?.enable ?? true)
                        || !(options?.pinned ?? false) || !(options?.reserveSpace ?? true)
                        || output !== screenScope.outputName) return 0
                const width = Math.max(300, Math.min(600, Number(options?.width ?? 380))) * LnFrame.IrisFrame.d
                const held = LnFrame.IrisFrame.clear(edge) - LnFrame.IrisFrame.band
                const air = (options?.notch ?? false) && held <= 0 ? 0 : 12 * LnFrame.IrisFrame.d
                return Math.round(LnFrame.IrisFrame.band + held + width + air)
            }

            component Reservation: PanelWindow {
                id: stub
                required property string edge
                screen: screenScope.modelData
                visible: true
                color: "transparent"
                WlrLayershell.namespace: "lunana-iris-reserve-" + stub.edge
                WlrLayershell.layer: WlrLayer.Background
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
                exclusionMode: ExclusionMode.Normal
                exclusiveZone: Math.max(LnFrame.IrisFrame.inset(stub.edge), screenScope.sidebarDepth(stub.edge))
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

    // Shell-entry handshake in this plugin's singleton universe: the vendored
    // tree gates on shellEntryReady/deferredPanelsReady, which only inir's
    // shell.qml boot sets. Mirror the minimal sequence here.
    Timer {
        interval: 200; repeat: false; running: true
        onTriggered: {
            Inir.GlobalStates.shellEntryReady = true;
            Inir.GlobalStates.deferredPanelsReady = true;
        }
    }
}
