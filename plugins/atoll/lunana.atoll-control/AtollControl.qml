import QtQuick
import Quickshell
import "../../lunana-vendor/" as Lunana
import qs.Commons
import Quickshell.Wayland
import "../../lunana-vendor/modules/atoll/control" as LnMod
import "../../lunana-vendor/modules/atoll/field" as LnField

// lunana.atoll-control — Lunana AtollControlCenter grid host. (kind: overlay).
//
// lunana's AtollControlCenter (modules/atoll/control) is an embeddable item, so this host provides the
// Omarchy overlay shell (summon, layer, close) around it. Toggled via
// `omarchy-shell shell toggle lunana.atoll-control`.
Item {
  id: root

  property var shell: null
  property var manifest: null

  property bool opened: false

  // AtollControlCenter is the bar's morph surface: it renders only when the
  // shared control-panel state is open and the screen is the focused one.
  // Drive that state here so the standalone overlay has visible content, and
  // pass the delegate's screen through (the component needs screenData.name).
  // Matches the chassis (AtollBar): opening from the island leaves
  // atollMorphOwner empty ("" = from island; "stage" = from a stage piece).
  function open(payloadJson) {
    root.opened = true
    Lunana.GlobalStates.controlPanelOpen = true
    Lunana.GlobalStates.atollMorphOwner = ""
  }
  function close() {
    root.opened = false
    Lunana.GlobalStates.controlPanelOpen = false
    Lunana.GlobalStates.atollMorphOwner = ""
  }
  function toggle() { root.opened ? root.close() : root.open("") }

  ShellIpc {
    target: "lunana.atoll-control"
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
        WlrLayershell.namespace: "lunana-atoll-control"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: root.opened ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        anchors { top: true; bottom: true; left: true; right: true }

        MouseArea { anchors.fill: parent; onClicked: root.close() }
        Item { anchors.fill: parent; focus: root.opened; Keys.onEscapePressed: root.close() }

        // The control card paints no body itself: in lunana the chassis field
        // paints its published shapes. Dedicated per-output field here,
        // behind the content (declared first paints first).
        LnField.AtollField {
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
            LnMod.AtollControlCenter {
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
