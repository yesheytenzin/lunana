import QtQuick
import Quickshell
import "vendor/" as Inir
import "vendor/modules/controlPanel" as LnMod

// lunana.control-center — Lunana exact ii control-center host (quick settings). (kind: overlay).
//
// Hosts inir's exact ControlPanel (modules/controlPanel); visibility is the vendored tree's own
// GlobalStates.controlPanelOpen, flipped here so `omarchy-shell shell toggle lunana.control-center`
// summons it.
Item {
  id: root

  property var shell: null
  property var manifest: null

  readonly property bool opened: Inir.GlobalStates.controlPanelOpen

  function open(payloadJson) { Inir.GlobalStates.controlPanelOpen = true }
  function close() { Inir.GlobalStates.controlPanelOpen = false }
  function toggle() { root.opened ? root.close() : root.open("") }

  ShellIpc {
    target: "lunana.control-center"
    function toggle(): void { root.toggle() }
    function open(): void { root.open("") }
    function close(): void { root.close() }
  }

  LnMod.ControlPanel {
  }
}
