pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../lunana-vendor/" as Inir
import "../../lunana-vendor/modules/iris/edit" as LnEdit

// iRiS edit/customize bar. Gated on GlobalStates.irisEdit.
Variants {
    model: Quickshell.screens
    delegate: Component {
        PanelWindow {
            required property var modelData
            readonly property bool shown: Inir.GlobalStates.irisEdit
            screen: modelData
            visible: shown
            color: "transparent"
            WlrLayershell.namespace: "lunana-iris-edit"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
            anchors { top: true; bottom: true; left: true; right: true }
            MouseArea { anchors.fill: parent; onClicked: Inir.GlobalStates.irisEdit = false }
            Item { anchors.fill: parent; focus: parent.shown; Keys.onEscapePressed: Inir.GlobalStates.irisEdit = false }
            Loader {
                anchors.fill: parent
                active: parent.shown
                sourceComponent: Component {
                    LnEdit.IrisEditBar {
                    }
                }
            }
        }
    }
}
