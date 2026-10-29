import QtQuick
import Quickshell
import "vendor/" as Inir
import "vendor/modules/regionSelector" as LnMod

// lunana.region — Lunana exact region-selector host (screenshot/OCR/record via grim/slurp). (kind: overlay).
//
// Hosts inir's exact RegionSelector (modules/regionSelector); visibility is the vendored tree's own
// GlobalStates.regionSelectorOpen, flipped here so `omarchy-shell shell toggle lunana.region`
// summons it.
Item {
  id: root

  property var shell: null
  property var manifest: null

  readonly property bool opened: Inir.GlobalStates.regionSelectorOpen

  function open(payloadJson) { Inir.GlobalStates.regionSelectorOpen = true }
  function close() { Inir.GlobalStates.regionSelectorOpen = false }
  function toggle() { root.opened ? root.close() : root.open("") }

  ShellIpc {
    target: "lunana.region"
    function toggle(): void { root.toggle() }
    function open(): void { root.open("") }
    function close(): void { root.close() }
  }

  LnMod.RegionSelector {
  }
}
