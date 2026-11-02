import QtQuick
import Quickshell
import qs.Commons
import "../../lunana-vendor/" as Lunana
import "../../lunana-vendor/modules/atoll/session" as LnMod

// lunana.atoll-session — Atoll session screen host (kind: overlay).
//
// The Atoll counterpart of lunana.session. AtollSessionScreen self-windows
// (namespace quickshell:atoll-session) and keys off GlobalStates.sessionOpen;
// the host drives that flag and exposes the overlay lifecycle so the surface
// is summonable via `omarchy-shell shell toggle lunana.atoll-session`.
Item {
  id: root

  property var shell: null
  property var manifest: null

  readonly property bool opened: Lunana.GlobalStates.sessionOpen

  function open(payloadJson) { Lunana.GlobalStates.sessionOpen = true }
  function close() { Lunana.GlobalStates.sessionOpen = false }
  function toggle() { root.opened ? root.close() : root.open("") }

  ShellIpc {
    target: "lunana.atoll-session"
    function toggle(): void { root.toggle() }
    function open(): void { root.open("") }
    function close(): void { root.close() }
  }

  LnMod.AtollSessionScreen {
  }

  Timer {
    interval: 200; repeat: false; running: true
    onTriggered: {
      Lunana.GlobalStates.shellEntryReady = true;
      Lunana.GlobalStates.deferredPanelsReady = true;
    }
  }
}
