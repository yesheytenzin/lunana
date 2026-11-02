pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import "../../.."
import "../../../services"
import "../../common"
import "../style"
import "../field" as Field

FloatingWindow {
    id: root
    title: Translation.tr("Lunana Settings")
    visible: GlobalStates.settingsOverlayOpen
    color: body.frame.material === "compositor" ? "transparent" : AtollStyle.surface
    implicitWidth: Math.round(1180 * AtollStyle.density)
    implicitHeight: Math.round(820 * AtollStyle.density)
    minimumSize: Qt.size(Math.round(560 * AtollStyle.density), Math.round(420 * AtollStyle.density))
    onClosed: GlobalStates.settingsOverlayOpen = false

    readonly property var niriWindow: {
        const list = NiriService.windows ?? []
        return list.find(w => w.title === root.title && w.pid === Quickshell.processId) ?? null
    }
    Binding {
        target: GlobalStates
        property: "settingsWindowBehind"
        value: root.visible && root.niriWindow !== null && !root.niriWindow.is_focused
    }
    // Opened over IPC it carries no activation token, so Niri maps it without focus.
    property bool focusedOnce: false
    onNiriWindowChanged: if (root.niriWindow && !root.focusedOnce) {
        root.focusedOnce = true
        NiriService.focusWindow(root.niriWindow.id)
    }
    onVisibleChanged: if (!root.visible) root.focusedOnce = false
    Component.onDestruction: GlobalStates.settingsWindowBehind = false
    Connections {
        target: GlobalStates
        function onSettingsRaiseRequestChanged(): void {
            if (root.niriWindow) NiriService.focusWindow(root.niriWindow.id)
        }
    }

    Field.AtollBlurRegion {
        window: root
        shapes: body.frame.blurShapes
        windowWidth: root.width
        windowHeight: root.height
    }

    AtollSettings {
        id: body
        anchors.fill: parent
        windowed: true
    }
}
