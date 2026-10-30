pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../lunana-vendor/modules/iris/field" as LnField
import "../../lunana-vendor/modules/iris/frame" as LnFrame

// iRiS surround frame — a per-output fullscreen IrisField over the windows with
// framed=true, so the glass band molds the tiled area around the island/dock.
// Inert until iris.surround.enable (IrisFrame.framed). Input passes through.
// In this one plugin the frame shares the island/dock field state.
Variants {
    model: Quickshell.screens
    delegate: Component {
        PanelWindow {
            required property var modelData
            screen: modelData
            visible: LnFrame.IrisFrame.framed
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            exclusiveZone: 0
            WlrLayershell.namespace: "lunana-iris-frame"
            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            anchors { top: true; bottom: true; left: true; right: true }
            mask: Region {}

            LnField.IrisField {
                anchors.fill: parent
                compositorAllowed: true
                providesBackdrop: true
                framed: true
                shapes: LnFrame.IrisFrame.placeShapesOn(modelData?.name ?? "")
            }
        }
    }
}
