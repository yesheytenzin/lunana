import QtQuick
import Quickshell
import "../../lunana-vendor/" as Inir
import qs.Commons
import Quickshell.Wayland
import "../../lunana-vendor/modules/iris/palette" as LnMod

// lunana.iris-palette — Lunana IrisPalette launcher host. (kind: overlay).
//
// inir's IrisPalette (modules/iris/palette) is an embeddable item, so this host provides the
// Omarchy overlay shell (summon, layer, close) around it. Toggled via
// `omarchy-shell shell toggle lunana.iris-palette`.
Item {
  id: root

  property var shell: null
  property var manifest: null

  property bool opened: false

  // Spotlight is chassis state in inir (GlobalStates.searchOpen); drive it
  // here so the standalone overlay has visible content, and clear it on
  // close like the chassis does when the palette dismisses.
  function open(payloadJson) {
    root.opened = true
    Inir.GlobalStates.searchOpen = true
  }
  function close() {
    root.opened = false
    Inir.GlobalStates.searchOpen = false
  }
  function toggle() { root.opened = !root.opened }

  ShellIpc {
    target: "lunana.iris-palette"
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
        WlrLayershell.namespace: "lunana-iris-palette"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: root.opened ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        anchors { top: true; bottom: true; left: true; right: true }

        MouseArea { anchors.fill: parent; onClicked: root.close() }
        Item { anchors.fill: parent; focus: root.opened; Keys.onEscapePressed: root.close() }

        Loader {
          anchors.fill: parent
          active: root.opened
          sourceComponent: Component {
            LnMod.IrisPalette {
              screen: modelData
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
