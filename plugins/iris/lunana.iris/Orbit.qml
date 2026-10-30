pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../lunana-vendor/" as Inir
import "../../lunana-vendor/modules/iris/orbit" as LnOrbit

// iRiS orbit (task view). Gated on GlobalStates.irisOrbitOpen.
Variants {
    model: Quickshell.screens
    delegate: Component {
        PanelWindow {
            required property var modelData
            readonly property bool shown: Inir.GlobalStates.irisOrbitOpen
            screen: modelData
            visible: shown
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            exclusiveZone: 0
            WlrLayershell.namespace: "lunana-iris-orbit"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
            anchors { top: true; bottom: true; left: true; right: true }
            Item { anchors.fill: parent; focus: parent.shown; Keys.onEscapePressed: Inir.GlobalStates.irisOrbitOpen = false }
            LnOrbit.IrisOrbit {
                anchors.fill: parent
                screen: modelData
            }
        }
    }
}
