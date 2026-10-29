import QtQuick
import Quickshell
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
}
