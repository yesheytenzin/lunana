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
        if (!root.allowMultiplePanels && GlobalStates.slateNotificationCenterOpen) {
            GlobalStates.searchOpen = false
            GlobalStates.slateActionCenterOpen = false
        }
    }

    Component.onCompleted: {
        root.panelMapped = GlobalStates.slateNotificationCenterOpen
        Notifications.ensureInitialized()
        root.enforceExclusivity()
    }

    Connections {
        target: GlobalStates
        function onSlateNotificationCenterOpenChanged() {
            if (GlobalStates.slateNotificationCenterOpen)
                root.panelMapped = true
            root.enforceExclusivity()
        }
    }

    PanelWindow {
        visible: root.panelMapped
        anchors { top: true; bottom: true; left: true; right: true }
        WlrLayershell.namespace: "quickshell:wNotificationCenterBg"
        WlrLayershell.layer: WlrLayer.Top
        color: "transparent"

        MouseArea {
            anchors.fill: parent
            onClicked: GlobalStates.slateNotificationCenterOpen = false
        }
    }

    PanelWindow {
        id: panelWindow
        visible: root.panelMapped
        exclusiveZone: 0
        WlrLayershell.namespace: "quickshell:wNotificationCenter"
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

        NotificationCenterContent {
            id: content
            anchors.fill: parent
            presented: GlobalStates.slateNotificationCenterOpen
            panelRightAligned: true
            onClosed: {
                if (!GlobalStates.slateNotificationCenterOpen)
                    root.panelMapped = false
            }
        }
    }
}
