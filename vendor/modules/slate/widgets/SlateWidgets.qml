import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../../.."
import "../../../services"
import "../../common"
import "../../common/widgets"

Scope {
    id: root

    Connections {
        target: GlobalStates
        function onSlateWidgetsOpenChanged() {
            if (GlobalStates.slateWidgetsOpen) panelLoader.active = true
        }
    }

    // Click-outside-to-close overlay
    LazyLoader {
        active: GlobalStates.slateWidgetsOpen
        component: PanelWindow {
            anchors { top: true; bottom: true; left: true; right: true }
            WlrLayershell.namespace: "quickshell:wWidgetsBg"
            WlrLayershell.layer: WlrLayer.Top
            color: "transparent"
            MouseArea {
                anchors.fill: parent
                onClicked: GlobalStates.slateWidgetsOpen = false
            }
        }
    }

    Loader {
        id: panelLoader
        active: GlobalStates.slateWidgetsOpen
        sourceComponent: PanelWindow {
            id: panelWindow
            exclusiveZone: 0
            WlrLayershell.namespace: "quickshell:wWidgets"
            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            color: "transparent"

            anchors {
                bottom: Config.options?.slate?.bar?.bottom ?? false
                top: !(Config.options?.slate?.bar?.bottom ?? false)
                left: true
            }

            implicitWidth: content.implicitWidth
            implicitHeight: content.implicitHeight

            Connections {
                target: GlobalStates
                function onSlateWidgetsOpenChanged() {
                    if (!GlobalStates.slateWidgetsOpen) content.close()
                }
            }

            SidgetsContent {
                id: content
                anchors.fill: parent

                onClosed: {
                    GlobalStates.slateWidgetsOpen = false
                    panelLoader.active = false
                }
            }
        }
    }

}
