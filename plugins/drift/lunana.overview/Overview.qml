import QtQuick
import Quickshell
import qs.Commons
import "../../lunana-vendor/" as Lunana
import "../../lunana-vendor/modules/overview" as LnMod

// lunana.overview — Lunana exact drift overview host (grid + search + calculator, Hyprland path). (kind: overlay).
//
// Hosts lunana's exact Overview (modules/overview); visibility is the vendored tree's own
// GlobalStates.overviewOpen, flipped here so `omarchy-shell shell toggle lunana.overview`
// summons it.
Item {
  id: root

  property var shell: null
  property var manifest: null

  readonly property bool opened: Lunana.GlobalStates.overviewOpen

  function open(payloadJson) { Lunana.GlobalStates.overviewOpen = true }
  function close() { Lunana.GlobalStates.overviewOpen = false }
  function toggle() { root.opened ? root.close() : root.open("") }

  ShellIpc {
    target: "lunana.overview"
    function toggle(): void { root.toggle() }
    function open(): void { root.open("") }
    function close(): void { root.close() }
  }

  LnMod.Overview {
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
