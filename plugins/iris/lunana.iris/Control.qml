pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../lunana-vendor/" as Inir
import "../../lunana-vendor/modules/iris/control" as LnControl
import "../../lunana-vendor/modules/iris/field" as LnField

// iRiS control centre. Content (not self-windowing), wrapped per output and
// gated on GlobalStates.controlPanelOpen — which the island's "controls" button
// sets in this same plugin's GlobalStates.
Variants {
    model: Quickshell.screens
    delegate: Component {
        PanelWindow {
            required property var modelData
            readonly property bool shown: Inir.GlobalStates.controlPanelOpen
            screen: modelData
            visible: shown
            color: "transparent"
            WlrLayershell.namespace: "lunana-iris-control"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
            anchors { top: true; bottom: true; left: true; right: true }
            MouseArea { anchors.fill: parent; onClicked: Inir.GlobalStates.controlPanelOpen = false }
            Item { anchors.fill: parent; focus: parent.shown; Keys.onEscapePressed: Inir.GlobalStates.controlPanelOpen = false }
            LnField.IrisField {
                anchors.fill: parent
                compositorAllowed: true
                providesBackdrop: true
                shapes: controlLoader.item?.fieldShapes ?? []
            }
            Loader {
                id: controlLoader
                anchors.fill: parent
                active: parent.shown
                sourceComponent: Component {
                    LnControl.IrisControlCenter {
                        screenData: modelData
                    }
                }
            }
        }
    }
}
