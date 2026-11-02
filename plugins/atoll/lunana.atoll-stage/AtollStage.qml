import QtQuick
import Quickshell
import "../../lunana-vendor/" as Lunana
import qs.Commons
import Quickshell.Wayland
import "../../lunana-vendor/modules/atoll/stage" as LnMod
import "../../lunana-vendor/modules/atoll/field" as LnField

// lunana.atoll-stage — Lunana AtollStage host. (kind: overlay).
//
// lunana's AtollStage (modules/atoll/stage) is an embeddable item, so this host provides the
// Omarchy overlay shell (summon, layer, close) around it. Toggled via
// `omarchy-shell shell toggle lunana.atoll-stage`.
Item {
  id: root

  property var shell: null
  property var manifest: null

  property bool opened: false

  function open(payloadJson) { root.opened = true }
  function close() { root.opened = false }
  function toggle() { root.opened = !root.opened }

  ShellIpc {
    target: "lunana.atoll-stage"
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
        WlrLayershell.namespace: "lunana-atoll-stage"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: root.opened ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        anchors { top: true; bottom: true; left: true; right: true }

        MouseArea { anchors.fill: parent; onClicked: root.close() }
        Item { anchors.fill: parent; focus: root.opened; Keys.onEscapePressed: root.close() }

        // The stage cards paint no bodies themselves: in lunana the chassis
        // field paints their published shapes. Dedicated per-output field
        // here, behind the content.
        LnField.AtollField {
          anchors.fill: parent
          compositorAllowed: true
          providesBackdrop: true
          shapes: stageLoader.item?.fieldShapes ?? []
        }

        Loader {
          id: stageLoader
          anchors.fill: parent
          active: root.opened
          sourceComponent: Component {
            LnMod.AtollStage {
              modelData: modelData
            }
          }
        }
      }
    }
  }

    // Shell-entry handshake against the shared lunana-vendor/ tree (one
    // GlobalStates universe for all hosts): the vendored tree gates first paint on
    // shellEntryReady/deferredPanelsReady, which only lunana's shell.qml boot
    // sets. Mirror the minimal sequence here.
    Timer {
        interval: 200; repeat: false; running: true
        onTriggered: {
            Lunana.GlobalStates.shellEntryReady = true;
            Lunana.GlobalStates.deferredPanelsReady = true;
        }
    }
}
