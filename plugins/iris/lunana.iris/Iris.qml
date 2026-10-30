import QtQuick
import Quickshell
import "../../lunana-vendor/" as Inir
import Quickshell.Wayland
import qs.Commons
import "../../lunana-vendor/modules/iris/bar" as LnIris
import "../../lunana-vendor/modules/iris/field" as LnField

// lunana.iris — exact iRiS island panel (kind: service, on by default).
//
// Mounts inir's exact IrisIsland DIRECTLY, not through IrisBar: the full
// IrisBar chassis (frame bands, dock/control-center/spotlight loaders,
// tuck + canvas-suppress gating) assumes iRiS owns the whole shell and hides
// the island whenever the ii suite owns bar+dock — which is always here.
// The island alone is the panel: morphing clock/media/apps/tray pill.
// Toggle with `omarchy lunana.iris toggle` (Super+Shift+I).
//
// The island's glass body is not painted by IrisIsland itself: in inir the
// shared chassis IrisField paints every piece's published shapes. This host
// mounts a per-output field behind the island fed by island.fieldShapes, so
// the pill renders exactly as in inir (no cross-surface fusion with the
// dock/control satellites, which stay separate pills).
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
                exclusionMode: ExclusionMode.Ignore
                exclusiveZone: 0
                WlrLayershell.namespace: "lunana-iris"
                WlrLayershell.layer: WlrLayer.Top
                anchors { top: true; bottom: true; left: true; right: true }
                // Fullscreen transparent surface: only the island itself
                // takes input, everything else passes through.
                mask: Region {
                    x: islandItem.x
                    y: islandItem.y
                    width: islandItem.width
                    height: islandItem.height
                }

                LnField.IrisField {
                    anchors.fill: parent
                    compositorAllowed: true
                    providesBackdrop: true
                    shapes: islandItem.fieldShapes ?? []
                }

                LnIris.IrisIsland {
                    id: islandItem
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
