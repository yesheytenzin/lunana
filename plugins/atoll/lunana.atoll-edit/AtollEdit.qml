import QtQuick
import Quickshell
import "../../lunana-vendor/" as Lunana
import qs.Commons
import Quickshell.Wayland
import "../../lunana-vendor/modules/atoll/edit" as LnMod
import "../../lunana-vendor/modules/atoll/field" as LnField

// lunana.atoll-edit — Lunana Atoll edit-mode host (interim: AtollEditBar gated panel). (kind: overlay).
//
// lunana's AtollEditBar (modules/atoll/edit) is an embeddable item, so this host provides the
// Omarchy overlay shell (summon, layer, close) around it. Toggled via
// `omarchy-shell shell toggle lunana.atoll-edit`.
Item {
  id: root

  property var shell: null
  property var manifest: null

  property bool opened: false

  // Edit mode is chassis state in lunana (GlobalStates.atollEdit); drive it
  // here so the standalone overlay has visible content, and clear it on
  // close like the chassis does when edit ends.
  function open(payloadJson) {
    root.opened = true
    Lunana.GlobalStates.atollEdit = true
  }
  function close() {
    root.opened = false
    Lunana.GlobalStates.atollEdit = false
  }
  function toggle() { root.opened ? root.close() : root.open("") }

  ShellIpc {
    target: "lunana.atoll-edit"
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
        WlrLayershell.namespace: "lunana-atoll-edit"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: root.opened ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        anchors { top: true; bottom: true; left: true; right: true }

        MouseArea { anchors.fill: parent; onClicked: root.close() }
        Item { anchors.fill: parent; focus: root.opened; Keys.onEscapePressed: root.close() }

        // The edit bar paints no body itself: in lunana the chassis field
        // paints its published shapes. Dedicated per-output field here,
        // behind the content.
        LnField.AtollField {
          anchors.fill: parent
          compositorAllowed: true
          providesBackdrop: true
          shapes: editLoader.item?.fieldShapes ?? []
        }

        Loader {
          id: editLoader
          anchors.fill: parent
          active: root.opened
          sourceComponent: Component {
            LnMod.AtollEditBar {
              screenData: modelData
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
