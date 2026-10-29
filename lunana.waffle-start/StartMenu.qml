import QtQuick
import Quickshell
import qs.Commons
import "vendor/" as Inir
import "vendor/modules/waffle/startMenu" as LnMod

// lunana.waffle-start — Lunana Waffle start-menu host (search). (kind: overlay).
//
// Hosts inir's exact WaffleStartMenu (modules/waffle/startMenu); visibility is the vendored tree's own
// GlobalStates.searchOpen, flipped here so `omarchy-shell shell toggle lunana.waffle-start`
// summons it.
Item {
  id: root

  property var shell: null
  property var manifest: null

  readonly property bool opened: Inir.GlobalStates.searchOpen

  function open(payloadJson) { Inir.GlobalStates.searchOpen = true }
  function close() { Inir.GlobalStates.searchOpen = false }
  function toggle() { root.opened ? root.close() : root.open("") }

  ShellIpc {
    target: "lunana.waffle-start"
    function toggle(): void { root.toggle() }
    function open(): void { root.open("") }
    function close(): void { root.close() }
  }

  LnMod.WaffleStartMenu {
  }
}
