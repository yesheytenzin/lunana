pragma ComponentBehavior: Bound
import "../../.."
import "../../../services"
import ".."
import "."
import "../functions"
import QtQuick
import Quickshell
import Quickshell.Wayland

Scope {
    id: root
    required property Component contentComponent
    property var targetScreen: null

    Connections {
        target: PolkitService
        function onActiveChanged(): void {
            if (PolkitService.active)
                root.targetScreen = GlobalStates.focusedScreen
            else
                root.targetScreen = null
        }
    }

    Loader {
        active: PolkitService.active
        sourceComponent: PanelWindow {
            id: panelWindow
            screen: root.targetScreen ?? GlobalStates.focusedScreen

            anchors {
                top: true
                left: true
                right: true
                bottom: true
            }

            color: "transparent"
            WlrLayershell.namespace: "quickshell:polkit"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
            WlrLayershell.layer: WlrLayer.Overlay
            exclusionMode: ExclusionMode.Ignore

            Loader {
                anchors.fill: parent
                sourceComponent: root.contentComponent
            }
        }
    }
}
