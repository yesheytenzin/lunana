import QtQuick
import Quickshell
import qs.Commons
import "../../lunana-vendor/" as Lunana
import "../../lunana-vendor/modules/slate/actionCenter" as LnMod

// lunana.slate-action — Lunana Slate action-center host. (kind: overlay).
//
// Hosts lunana's exact SlateActionCenter (modules/slate/actionCenter); visibility is the vendored tree's own
// GlobalStates.slateActionCenterOpen, flipped here so `omarchy-shell shell toggle lunana.slate-action`
// summons it.
Item {
  id: root

  property var shell: null
  property var manifest: null

  readonly property bool opened: Lunana.GlobalStates.slateActionCenterOpen

  function open(payloadJson) { Lunana.GlobalStates.slateActionCenterOpen = true }
  function close() { Lunana.GlobalStates.slateActionCenterOpen = false }
  function toggle() { root.opened ? root.close() : root.open("") }

  ShellIpc {
    target: "lunana.slate-action"
    function toggle(): void { root.toggle() }
    function open(): void { root.open("") }
    function close(): void { root.close() }
  }

  LnMod.SlateActionCenter {
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
