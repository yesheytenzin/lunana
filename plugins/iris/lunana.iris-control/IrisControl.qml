import QtQuick
import Quickshell
import "../../lunana-vendor/" as Inir
import qs.Commons
import Quickshell.Wayland
import "../../lunana-vendor/modules/iris/control" as LnMod
import "../../lunana-vendor/modules/iris/field" as LnField

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

  // IrisControlCenter is the bar's morph surface: it renders only when the
  // shared control-panel state is open and the screen is the focused one.
  // Drive that state here so the standalone overlay has visible content, and
  // pass the delegate's screen through (the component needs screenData.name).
  function open(payloadJson) {
    root.opened = true
    Inir.GlobalStates.controlPanelOpen = true
    Inir.GlobalStates.irisMorphOwner = "stage"
    Inir.GlobalStates.irisMorphOrigin = null
  }
  function close() {
    root.opened = false
    Inir.GlobalStates.controlPanelOpen = false
    if (Inir.GlobalStates.irisMorphOwner === "stage")
      Inir.GlobalStates.irisMorphOwner = ""
  }
  function toggle() { root.opened ? root.close() : root.open("") }

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

        // The control card paints no body itself: in inir the chassis field
        // paints its published shapes. Dedicated per-output field here,
        // behind the content (declared first paints first).
        LnField.IrisField {
          anchors.fill: parent
          compositorAllowed: true
          providesBackdrop: true
          shapes: controlLoader.item?.fieldShapes ?? []
        }

        Loader {
          id: controlLoader
          anchors.fill: parent
          active: root.opened
          sourceComponent: Component {
            LnMod.IrisControlCenter {
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
