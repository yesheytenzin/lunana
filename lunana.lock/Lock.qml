import QtQuick
import Quickshell
import qs.Commons
import "vendor/" as Inir
import "vendor/modules/lock" as LnMod

// lunana.lock — Lunana exact ii lock host (Hyprland session-lock branches). (kind: service).
//
// Resident host for inir's exact Lock; the vendored WlSessionLock surface
// shows on GlobalStates.screenLocked. open() locks now; close() is a deliberate
// no-op — only the lock screen's own auth UI unlocks.
Item {
  id: root

  property var shell: null
  property var manifest: null

  function open(payloadJson) { Inir.GlobalStates.screenLocked = true }
  function close() { }
  function toggle() { root.open("") }

  ShellIpc {
    target: "lunana.lock"
    function toggle(): void { root.toggle() }
    function open(): void { root.open("") }
    function close(): void { root.close() }
  }

  LnMod.Lock {
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
