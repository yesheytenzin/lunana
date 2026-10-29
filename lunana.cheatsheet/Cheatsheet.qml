import QtQuick
import Quickshell
import qs.Commons
import "../lunana-vendor/" as Inir
import "../lunana-vendor/modules/cheatsheet" as LnMod

// lunana.cheatsheet — Lunana exact ii cheatsheet host (reads Omarchy bindings.lua). (kind: overlay).
//
// Hosts inir's exact Cheatsheet (modules/cheatsheet); visibility is the vendored tree's own
// GlobalStates.cheatsheetOpen, flipped here so `omarchy-shell shell toggle lunana.cheatsheet`
// summons it.
Item {
  id: root

  property var shell: null
  property var manifest: null

  readonly property bool opened: Inir.GlobalStates.cheatsheetOpen

  function open(payloadJson) { Inir.GlobalStates.cheatsheetOpen = true }
  function close() { Inir.GlobalStates.cheatsheetOpen = false }
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
