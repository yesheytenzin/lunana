import QtQuick
import Quickshell
import "vendor/" as Inir
import qs.Commons
import Quickshell.Wayland
import "vendor/modules/iris/control" as LnMod

// lunana.iris-control — Lunana IrisControlCenter grid host. (kind: overlay).
//
// inir's IrisControlCenter (modules/iris/control) is an embeddable item, so this host provides the
// Omarchy overlay shell (summon, layer, close) around it. Toggled via
// `omarchy-shell shell toggle lunana.iris-control`.
Item {
  id: root

  property var shell: null
  property var manifest: null

  property bool opened: false

  function open(payloadJson) { root.opened = true }
  function close() { root.opened = false }
  function toggle() { root.opened = !root.opened }

  ShellIpc {
    target: "lunana.iris-control"
    function toggle(): void { root.toggle() }
    function open(): void { root.open("") }
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
        WlrLayershell.namespace: "lunana-iris-control"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: root.opened ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        anchors { top: true; bottom: true; left: true; right: true }

        MouseArea { anchors.fill: parent; onClicked: root.close() }
        Item { anchors.fill: parent; focus: root.opened; Keys.onEscapePressed: root.close() }

        Loader {
          anchors.centerIn: parent
          active: root.opened
          sourceComponent: Component {
            LnMod.IrisControlCenter {
            }
          }
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
