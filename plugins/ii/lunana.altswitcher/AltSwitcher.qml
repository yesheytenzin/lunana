import QtQuick
import Quickshell
import qs.Commons
import "../../lunana-vendor/" as Inir
import "../../lunana-vendor/modules/altSwitcher" as LnMod

// lunana.altswitcher — Lunana exact alt-switcher host (MRU order). (kind: overlay).
//
// Hosts inir's exact AltSwitcher (modules/altSwitcher); visibility is the vendored tree's own
// GlobalStates.altSwitcherOpen, flipped here so `omarchy-shell shell toggle lunana.altswitcher`
// summons it.
Item {
  id: root

  property var shell: null
  property var manifest: null

  readonly property bool opened: Inir.GlobalStates.altSwitcherOpen

  function open(payloadJson) { Inir.GlobalStates.altSwitcherOpen = true }
  function close() { Inir.GlobalStates.altSwitcherOpen = false }
  function toggle() { root.opened ? root.close() : root.open("") }

  ShellIpc {
    target: "lunana.altswitcher"
    function toggle(): void { root.toggle() }
    function open(): void { root.open("") }
    function close(): void { root.close() }
  }

  LnMod.AltSwitcher {
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
