pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../.."
import "../frame"
import "../components"
import "../field" as Field

PanelWindow {
    id: root
    visible: GlobalStates.settingsOverlayOpen || body.frame.progress > 0
    AtollOutputHold {
        id: outputHold
        wanted: GlobalStates.focusedScreen
        live: root.visible
    }
    screen: outputHold.output
    color: "transparent"
    anchors { left: true; right: true; top: true; bottom: true }
    margins {
        left: AtollFrame.band
        right: AtollFrame.band
        top: AtollFrame.band
        bottom: AtollFrame.band
    }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "quickshell:atoll-settings"
    WlrLayershell.layer: GlobalStates.settingsNativeDialogOpen ? WlrLayer.Bottom : WlrLayer.Overlay
    WlrLayershell.keyboardFocus: GlobalStates.settingsNativeDialogOpen ? WlrKeyboardFocus.None : WlrKeyboardFocus.Exclusive
    mask: GlobalStates.settingsOverlayOpen && body.frame.armed ? null : frameRegion
    Region { id: frameRegion; item: body.frame }
    Field.AtollBlurRegion {
        window: root
        shapes: body.frame.blurShapes
        windowWidth: root.width
        windowHeight: root.height
    }

    AtollSettings {
        id: body
        anchors.fill: parent
    }
}
