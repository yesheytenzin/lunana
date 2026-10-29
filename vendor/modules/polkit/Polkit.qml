import "../.."
import "../../services"
import "../common"
import "../common/widgets"
import "../common/functions"
import QtQuick
import Quickshell
import Quickshell.Wayland

Scope {
    id: root
    
    Loader {
        // Only activate if Polkit module is available AND there's an active auth request
        active: PolkitService.available && PolkitService.active
        sourceComponent: Variants {
            model: Quickshell.screens
            delegate: PanelWindow {
                id: panelWindow
                required property var modelData
                screen: modelData
                
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

                PolkitContent {
                    anchors.fill: parent
                }
            }
        }
    }
}
