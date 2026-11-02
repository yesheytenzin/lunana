import QtQuick
import Quickshell
import qs.Commons
import "../../lunana-vendor/" as Lunana
import "../../lunana-vendor/modules/cheatsheet" as LnMod

// lunana.cheatsheet — Lunana exact drift cheatsheet host (reads Omarchy bindings.lua). (kind: overlay).
//
// Hosts lunana's exact Cheatsheet (modules/cheatsheet); visibility is the vendored tree's own
// GlobalStates.cheatsheetOpen, flipped here so `omarchy-shell shell toggle lunana.cheatsheet`
// summons it.
Item {
  id: root

  property var shell: null
  property var manifest: null

  readonly property bool opened: Lunana.GlobalStates.cheatsheetOpen

  function open(payloadJson) { Lunana.GlobalStates.cheatsheetOpen = true }
  function close() { Lunana.GlobalStates.cheatsheetOpen = false }
  function toggle() { root.opened ? root.close() : root.open("") }

  ShellIpc {
    target: "lunana.cheatsheet"
    function toggle(): void { root.toggle() }
    function open(): void { root.open("") }
    function close(): void { root.close() }
  }

  LnMod.Cheatsheet {
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
