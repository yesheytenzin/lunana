import QtQuick
import Quickshell
import qs.Commons
import "../../lunana-vendor/" as Inir
import "../../lunana-vendor/modules/iris/session" as LnMod

// lunana.iris-session — iRiS session screen host (kind: overlay).
//
// The iRiS counterpart of lunana.session. IrisSessionScreen self-windows
// (namespace quickshell:iris-session) and keys off GlobalStates.sessionOpen;
// the host drives that flag and exposes the overlay lifecycle so the surface
// is summonable via `omarchy-shell shell toggle lunana.iris-session`.
Item {
  id: root

  property var shell: null
  property var manifest: null

  readonly property bool opened: Inir.GlobalStates.sessionOpen

  function open(payloadJson) { Inir.GlobalStates.sessionOpen = true }
  function close() { Inir.GlobalStates.sessionOpen = false }
  function toggle() { root.opened ? root.close() : root.open("") }

  ShellIpc {
    target: "lunana.iris-session"
    function toggle(): void { root.toggle() }
    function open(): void { root.open("") }
    function close(): void { root.close() }
  }

  LnMod.IrisSessionScreen {
  }

  Timer {
    interval: 200; repeat: false; running: true
    onTriggered: {
      Inir.GlobalStates.shellEntryReady = true;
      Inir.GlobalStates.deferredPanelsReady = true;
    }
  }
}
