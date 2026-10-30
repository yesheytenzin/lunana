pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../lunana-vendor/" as Inir
import "../../lunana-vendor/modules/iris/frame" as LnFrame

// Edge-space reservations so tiled windows warp around the island/dock/pinned
// sidebars. Reserves the resting visual footprint via IrisFrame.inset(edge)
// plus the sidebar depth. Now in the same plugin as the island/dock/sidebars,
// so it reacts to their live GlobalStates.
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
