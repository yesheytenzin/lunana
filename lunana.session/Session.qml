import QtQuick
import Quickshell
import qs.Commons
import "vendor/" as Inir
import "vendor/modules/sessionScreen" as LnMod

// lunana.session — Lunana exact ii session-screen host. (kind: overlay).
//
// Hosts inir's exact SessionScreen (modules/sessionScreen); visibility is the vendored tree's own
// GlobalStates.sessionOpen, flipped here so `omarchy-shell shell toggle lunana.session`
// summons it.
Item {
  id: root

  property var shell: null
  property var manifest: null

  readonly property bool opened: Inir.GlobalStates.sessionOpen

  function open(payloadJson) { Inir.GlobalStates.sessionOpen = true }
  function close() { Inir.GlobalStates.sessionOpen = false }
  function toggle() { root.opened ? root.close() : root.open("") }

  ShellIpc {
    target: "lunana.session"
    function toggle(): void { root.toggle() }
    function open(): void { root.open("") }
    function close(): void { root.close() }
  }

  LnMod.SessionScreen {
  }
}
