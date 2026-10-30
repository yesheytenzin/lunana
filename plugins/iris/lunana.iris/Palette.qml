pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../lunana-vendor/" as Inir
import "../../lunana-vendor/modules/iris/palette" as LnPalette

// iRiS spotlight/palette launcher. Gated on GlobalStates.searchOpen.
Variants {
    model: Quickshell.screens
    delegate: Component {
        PanelWindow {
            required property var modelData
            readonly property bool shown: Inir.GlobalStates.searchOpen
            screen: modelData
            visible: shown
            color: "transparent"
            WlrLayershell.namespace: "lunana-iris-palette"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
            anchors { top: true; bottom: true; left: true; right: true }
            MouseArea { anchors.fill: parent; onClicked: Inir.GlobalStates.searchOpen = false }
            Item { anchors.fill: parent; focus: parent.shown; Keys.onEscapePressed: Inir.GlobalStates.searchOpen = false }
            Loader {
                anchors.fill: parent
                active: parent.shown
                sourceComponent: Component {
                    LnPalette.IrisPalette {
                        screen: modelData
                    }
                }
            }
        }
    }
}
