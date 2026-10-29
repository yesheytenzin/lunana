import QtQuick
import Quickshell
import qs.Commons
import "../lunana-vendor/" as Inir
import "../lunana-vendor/modules/waffle/startMenu" as LnMod

// lunana.waffle-start — Lunana Waffle start-menu host (search). (kind: overlay).
//
// Hosts inir's exact WaffleStartMenu (modules/waffle/startMenu); visibility is the vendored tree's own
// GlobalStates.searchOpen, flipped here so `omarchy-shell shell toggle lunana.waffle-start`
// summons it.
Item {
  id: root

  property var shell: null
  property var manifest: null

  readonly property bool opened: Inir.GlobalStates.searchOpen

  function open(payloadJson) { Inir.GlobalStates.searchOpen = true }
  function close() { Inir.GlobalStates.searchOpen = false }
  function toggle() { root.opened ? root.close() : root.open("") }

  ShellIpc {
    target: "lunana.waffle-start"
    function toggle(): void { root.toggle() }
    function open(): void { root.open("") }
    function close(): void { root.close() }
  }

  LnMod.WaffleStartMenu {
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
