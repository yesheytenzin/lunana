import QtQuick
import Quickshell
import "vendor/" as Inir
import "vendor/modules/waffle/actionCenter" as LnMod

// lunana.waffle-action — Lunana Waffle action-center host. (kind: overlay).
//
// Hosts inir's exact WaffleActionCenter (modules/waffle/actionCenter); visibility is the vendored tree's own
// GlobalStates.waffleActionCenterOpen, flipped here so `omarchy-shell shell toggle lunana.waffle-action`
// summons it.
Item {
  id: root

  property var shell: null
  property var manifest: null

  readonly property bool opened: Inir.GlobalStates.waffleActionCenterOpen

  function open(payloadJson) { Inir.GlobalStates.waffleActionCenterOpen = true }
  function close() { Inir.GlobalStates.waffleActionCenterOpen = false }
  function toggle() { root.opened ? root.close() : root.open("") }

  ShellIpc {
    target: "lunana.waffle-action"
    function toggle(): void { root.toggle() }
    function open(): void { root.open("") }
    function close(): void { root.close() }
  }

  LnMod.WaffleActionCenter {
  }
}
