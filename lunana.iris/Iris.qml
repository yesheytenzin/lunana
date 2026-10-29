import QtQuick
import Quickshell
import "vendor/" as Inir
import Quickshell.Wayland
import qs.Commons
import qs.Commons as Commons
import "vendor/modules/iris/bar" as LnIris

// lunana.iris — exact iRiS island panel (kind: service, on by default).
//
// Mounts inir's exact IrisIsland DIRECTLY, not through IrisBar: the full
// IrisBar chassis (frame bands, dock/control-center/spotlight loaders,
// tuck + canvas-suppress gating) assumes iRiS owns the whole shell and hides
// the island whenever the ii suite owns bar+dock — which is always here.
// The island alone is the panel: morphing clock/media/apps/tray pill.
// Toggle with `omarchy lunana.iris toggle` (Super+Shift+I).
Item {
    id: root

    property var shell: null
    property var manifest: null
    property bool opened: true

    function open() { root.opened = true }
    function close() { root.opened = false }
    function toggle() { root.opened = !root.opened }

    ShellIpc {
        target: "lunana.iris"
        function toggle(): void { root.toggle() }
        function open(): void { root.open() }
        function close(): void { root.close() }
    }

    Variants {
        model: Quickshell.screens
        delegate: Component {
            PanelWindow {
                required property var modelData
                screen: modelData
                visible: root.opened
                color: "transparent"
                WlrLayershell.namespace: "lunana-iris"
                WlrLayershell.layer: WlrLayer.Top
                anchors { top: true; left: true; right: true }
                implicitHeight: 120

                LnIris.IrisIsland {
                    anchors.top: parent.top
                    anchors.horizontalCenter: parent.horizontalCenter
                    targetScreen: modelData
                }
            }
        }
    }

    // Shell-entry handshake in this plugin's singleton universe (each
    // installed plugin carries its own vendor/ copy, hence its own
    // GlobalStates): the vendored tree gates first paint on
    // shellEntryReady/deferredPanelsReady, which only inir's shell.qml boot
    // sets. Mirror the minimal sequence here.
    Timer {
        interval: 200; repeat: false; running: true
        onTriggered: {
            Inir.GlobalStates.shellEntryReady = true;
            Inir.GlobalStates.deferredPanelsReady = true;
        }
    }
}
