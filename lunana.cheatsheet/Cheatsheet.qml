import QtQuick
import Quickshell
import qs.Commons
import "vendor/" as Inir
import "vendor/modules/cheatsheet" as LnMod

// lunana.cheatsheet — Lunana exact ii cheatsheet host (reads Omarchy bindings.lua). (kind: overlay).
//
// Hosts inir's exact Cheatsheet (modules/cheatsheet); visibility is the vendored tree's own
// GlobalStates.cheatsheetOpen, flipped here so `omarchy-shell shell toggle lunana.cheatsheet`
// summons it.
Item {
  id: root

  property var shell: null
  property var manifest: null

  readonly property bool opened: Inir.GlobalStates.cheatsheetOpen

  function open(payloadJson) { Inir.GlobalStates.cheatsheetOpen = true }
  function close() { Inir.GlobalStates.cheatsheetOpen = false }
  function toggle() { root.opened ? root.close() : root.open("") }

  ShellIpc {
    target: "lunana.cheatsheet"
    function toggle(): void { root.toggle() }
    function open(): void { root.open("") }
    function close(): void { root.close() }
  }

  LnMod.Cheatsheet {
  }
}
