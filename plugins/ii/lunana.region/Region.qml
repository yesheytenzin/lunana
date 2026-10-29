import QtQuick
import Quickshell
import qs.Commons
import "../../lunana-vendor/" as Inir
import "../../lunana-vendor/modules/regionSelector" as LnMod

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
