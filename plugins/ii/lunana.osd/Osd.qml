import QtQuick
import Quickshell
import qs.Commons
import "../../lunana-vendor/" as Inir
import "../../lunana-vendor/modules/onScreenDisplay" as LnMod

// lunana.osd — Lunana exact ii on-screen-display host (volume/brightness/layout). (kind: service).
//
// Resident host for inir's exact OnScreenDisplay (modules/onScreenDisplay); it shows itself on the
// vendored tree's own state. No toggle: summoned only through the family
// switcher or not at all (see PORTING.md).
//
// Test-only `test` IPC (see PORTING.md): real volume keys do not exist in the
// nest and the vendored Audio backend never fires there, so this drives the
// exact render path directly — first call opens the volume pill via the
// module's own setOpenStates, second call clears it.
Item {
  id: root

  property var shell: null
  property var manifest: null

  function test() {
    if (Inir.GlobalStates.osdVolumeOpen) {
      osdItem.setOpenStates(false, false, false, false, false)
      return "cleared"
    }
    osdItem.setOpenStates(true, false, false, false, false)
    return "shown"
  }

  ShellIpc {
    target: "lunana.osd"
    function test(): string { return root.test() }
  }

  LnMod.OnScreenDisplay {
    id: osdItem
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
