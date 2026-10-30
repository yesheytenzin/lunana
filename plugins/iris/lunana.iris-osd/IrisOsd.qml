import QtQuick
import Quickshell
import qs.Commons
import "../../lunana-vendor/" as Inir
import "../../lunana-vendor/modules/iris/onScreenDisplay" as LnMod

// lunana.iris-osd — iRiS on-screen-display host (volume/brightness/layout). (kind: service).
//
// The iRiS counterpart of lunana.osd. IrisOSD self-windows on the vendored
// tree's own osd*Open state (GlobalStates.osdVolumeOpen/osdBrightnessOpen/…),
// so there is no toggle: it shows itself when the family's OSD fires. Enabled
// only while the iRiS family is active (family-cycle owns the set), so exactly
// one family's OSD is live at a time.
//
// Test hook: real volume-key traffic cannot reach the nest reliably, so
// `omarchy-shell lunana.iris-osd test [kind]` drives the OSD render path
// directly (default kind "volume", 8s hold). The Audio→OSD signal wiring
// itself is untouched vendored inir code.
Item {
  id: root

  property var shell: null
  property var manifest: null

  function test(kind) {
    osdItem.show(kind && String(kind).length > 0 ? String(kind) : "volume", 8000)
    return "shown"
  }

  ShellIpc {
    target: "lunana.iris-osd"
    function test(kind: string): string { return root.test(kind) }
  }

  LnMod.IrisOSD {
    id: osdItem

    // Shell-entry handshake in this plugin's singleton universe: the vendored
    // tree gates first paint on shellEntryReady/deferredPanelsReady, which only
    // inir's shell.qml boot sets. Mirror the minimal sequence here.
    Timer {
        interval: 200; repeat: false; running: true
        onTriggered: {
            Inir.GlobalStates.shellEntryReady = true;
            Inir.GlobalStates.deferredPanelsReady = true;
        }
    }
  }
}
