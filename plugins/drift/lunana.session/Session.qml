import QtQuick
import Quickshell
import qs.Commons
import "../../lunana-vendor/" as Lunana
import "../../lunana-vendor/modules/sessionScreen" as LnMod

// lunana.session — Lunana exact drift session-screen host. (kind: overlay).
//
// Hosts lunana's exact SessionScreen (modules/sessionScreen); visibility is the vendored tree's own
// GlobalStates.sessionOpen, flipped here so `omarchy-shell shell toggle lunana.session`
// summons it.
Item {
  id: root

  property var shell: null
  property var manifest: null

  readonly property bool opened: Lunana.GlobalStates.sessionOpen

  function open(payloadJson) { Lunana.GlobalStates.sessionOpen = true }
  function close() { Lunana.GlobalStates.sessionOpen = false }
  function toggle() { root.opened ? root.close() : root.open("") }

  ShellIpc {
    target: "lunana.session"
    function toggle(): void { root.toggle() }
    function open(): void { root.open("") }
    function close(): void { root.close() }
  }

  LnMod.SessionScreen {
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
