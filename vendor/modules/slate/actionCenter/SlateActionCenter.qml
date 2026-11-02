import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../../services"
import "../../.."
import "../../common"

Scope {
    id: root

    property bool panelMapped: false
    readonly property bool allowMultiplePanels:
        Config.options?.slate?.behavior?.allowMultiplePanels ?? false

    function enforceExclusivity(): void {
        if (!root.allowMultiplePanels && GlobalStates.slateActionCenterOpen) {
            GlobalStates.searchOpen = false
            GlobalStates.slateNotificationCenterOpen = false
        }
    }

    Component.onCompleted: {
        root.panelMapped = GlobalStates.slateActionCenterOpen
        root.enforceExclusivity()
    }

    Connections {
        target: GlobalStates
        function onSlateActionCenterOpenChanged() {
            if (GlobalStates.slateActionCenterOpen)
                root.panelMapped = true
            root.enforceExclusivity()
        }
    }

    PanelWindow {
        visible: root.panelMapped
        anchors { top: true; bottom: true; left: true; right: true }
        WlrLayershell.namespace: "quickshell:wActionCenterBg"
        WlrLayershell.layer: WlrLayer.Top
        color: "transparent"

        MouseArea {
            anchors.fill: parent
            onClicked: GlobalStates.slateActionCenterOpen = false
        }
    }

    PanelWindow {
        id: panelWindow
        visible: root.panelMapped
        exclusiveZone: 0
        WlrLayershell.namespace: "quickshell:wactionCenter"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: visible
            ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        color: "transparent"

        anchors {
            bottom: Config.options?.slate?.bar?.bottom ?? false
            top: !(Config.options?.slate?.bar?.bottom ?? false)
            right: true
        }

        implicitWidth: content.implicitWidth
        implicitHeight: content.implicitHeight

        ActionCenterContent {
            id: content
            anchors.fill: parent
            presented: GlobalStates.slateActionCenterOpen
            panelRightAligned: true
            onClosed: {
                if (!GlobalStates.slateActionCenterOpen)
                    root.panelMapped = false
            }
        }
    }
}
