import QtQuick
import Quickshell
import qs.Commons
import "../../lunana-vendor/" as Inir
import "../../lunana-vendor/modules/lock" as LnMod

// lunana.iris-lock — Lunana iRiS lock host (dormant unless the iris family owns locking). (kind: service).
//
// Resident host for inir's exact Lock; with panelFamily=iris it shows the
// IrisLockSurface. The full Lock owns the LockContext (PAM), the
// WlSessionLock surface, the fallback path, and the iris unlock timing —
// mounting IrisLockSurface directly leaves its required `context` unset and
// the plugin fails to create. Same shape as the ii/waffle lock hosts: only
// one family lock is enabled at a time.
//
// open() locks now; close() is a deliberate no-op — only the lock screen's
// own auth UI unlocks.
Item {
  id: root

  property var shell: null
  property var manifest: null

  function open(payloadJson) { Inir.GlobalStates.screenLocked = true }
  function close() { }
  function toggle() { root.open("") }

  ShellIpc {
    target: "lunana.iris-lock"
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
