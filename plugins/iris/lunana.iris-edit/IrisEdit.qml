import QtQuick
import Quickshell
import "../../lunana-vendor/" as Inir
import qs.Commons
import Quickshell.Wayland
import "../../lunana-vendor/modules/iris/edit" as LnMod
import "../../lunana-vendor/modules/iris/field" as LnField

// lunana.iris-edit — Lunana iRiS edit-mode host (interim: IrisEditBar gated panel). (kind: overlay).
//
// inir's IrisEditBar (modules/iris/edit) is an embeddable item, so this host provides the
// Omarchy overlay shell (summon, layer, close) around it. Toggled via
// `omarchy-shell shell toggle lunana.iris-edit`.
Item {
  id: root

  property var shell: null
  property var manifest: null

  property bool opened: false

  // Edit mode is chassis state in inir (GlobalStates.irisEdit); drive it
  // here so the standalone overlay has visible content, and clear it on
  // close like the chassis does when edit ends.
  function open(payloadJson) {
    root.opened = true
    Inir.GlobalStates.irisEdit = true
  }
  function close() {
    root.opened = false
    Inir.GlobalStates.irisEdit = false
  }
  function toggle() { root.opened = !root.opened }

  ShellIpc {
    target: "lunana.iris-edit"
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
        WlrLayershell.namespace: "lunana-iris-edit"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: root.opened ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        anchors { top: true; bottom: true; left: true; right: true }

        MouseArea { anchors.fill: parent; onClicked: root.close() }
        Item { anchors.fill: parent; focus: root.opened; Keys.onEscapePressed: root.close() }

        // The edit bar paints no body itself: in inir the chassis field
        // paints its published shapes. Dedicated per-output field here,
        // behind the content.
        LnField.IrisField {
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
            LnMod.IrisEditBar {
              screenData: modelData
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
