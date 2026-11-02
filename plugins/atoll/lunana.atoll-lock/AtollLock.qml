import QtQuick
import Quickshell
import qs.Commons
import "../../lunana-vendor/" as Lunana
import "../../lunana-vendor/modules/lock" as LnMod

// lunana.atoll-lock — Lunana Atoll lock host (dormant unless the atoll family owns locking). (kind: service).
//
// Resident host for lunana's exact Lock; with panelFamily=atoll it shows the
// AtollLockSurface. The full Lock owns the LockContext (PAM), the
// WlSessionLock surface, the fallback path, and the atoll unlock timing —
// mounting AtollLockSurface directly leaves its required `context` unset and
// the plugin fails to create. Same shape as the drift/slate lock hosts: only
// one family lock is enabled at a time.
//
// open() locks now; close() is a deliberate no-op — only the lock screen's
// own auth UI unlocks.
Item {
  id: root

  property var shell: null
  property var manifest: null

  function open(payloadJson) { Lunana.GlobalStates.screenLocked = true }
  function close() { }
  function toggle() { root.open("") }

  ShellIpc {
    target: "lunana.atoll-lock"
    function toggle(): void { root.toggle() }
    function open(): void { root.open("") }
    function close(): void { root.close() }
  }

  LnMod.Lock {
  }

  // Shell-entry handshake against the shared lunana-vendor/ tree (one
  // GlobalStates universe for all hosts): the vendored tree gates first paint on
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
