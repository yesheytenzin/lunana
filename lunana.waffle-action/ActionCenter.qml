import QtQuick
import Quickshell
import qs.Commons
import "../lunana-vendor/" as Inir
import "../lunana-vendor/modules/waffle/actionCenter" as LnMod

// lunana.waffle-action — Lunana Waffle action-center host. (kind: overlay).
//
// Hosts inir's exact WaffleActionCenter (modules/waffle/actionCenter); visibility is the vendored tree's own
// GlobalStates.waffleActionCenterOpen, flipped here so `omarchy-shell shell toggle lunana.waffle-action`
// summons it.
Item {
  id: root

  property var shell: null
  property var manifest: null

  readonly property bool opened: Inir.GlobalStates.waffleActionCenterOpen

  function open(payloadJson) { Inir.GlobalStates.waffleActionCenterOpen = true }
  function close() { Inir.GlobalStates.waffleActionCenterOpen = false }
  function toggle() { root.opened ? root.close() : root.open("") }

  ShellIpc {
    target: "lunana.waffle-action"
    function toggle(): void { root.toggle() }
    function open(): void { root.open("") }
    function close(): void { root.close() }
  }

  LnMod.WaffleActionCenter {
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
