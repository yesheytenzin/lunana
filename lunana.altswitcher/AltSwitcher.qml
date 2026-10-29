import QtQuick
import Quickshell
import qs.Commons
import "vendor/" as Inir
import "vendor/modules/altSwitcher" as LnMod

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
}
