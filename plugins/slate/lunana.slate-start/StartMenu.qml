import QtQuick
import Quickshell
import qs.Commons
import "../../lunana-vendor/" as Lunana
import "../../lunana-vendor/modules/slate/startMenu" as LnMod

// lunana.slate-start — Lunana Slate start-menu host (search). (kind: overlay).
//
// Hosts lunana's exact SlateStartMenu (modules/slate/startMenu); visibility is the vendored tree's own
// GlobalStates.searchOpen, flipped here so `omarchy-shell shell toggle lunana.slate-start`
// summons it.
Item {
  id: root

  property var shell: null
  property var manifest: null

  readonly property bool opened: Lunana.GlobalStates.searchOpen

  function open(payloadJson) { Lunana.GlobalStates.searchOpen = true }
  function close() { Lunana.GlobalStates.searchOpen = false }
  function toggle() { root.opened ? root.close() : root.open("") }

  ShellIpc {
    target: "lunana.slate-start"
    function toggle(): void { root.toggle() }
    function open(): void { root.open("") }
    function close(): void { root.close() }
  }

  LnMod.SlateStartMenu {
  }

    // Shell-entry handshake in this plugin's singleton universe (each
    // installed plugin carries its own vendor/ copy, hence its own
    // GlobalStates): the vendored tree gates first paint on
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
