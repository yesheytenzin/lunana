import QtQuick
import Quickshell
import qs.Commons
import "../../lunana-vendor/" as Lunana
import "../../lunana-vendor/modules/atoll/onScreenDisplay" as LnMod

// lunana.atoll-osd — Atoll on-screen-display host (volume/brightness/layout). (kind: service).
//
// The Atoll counterpart of lunana.osd. AtollOSD self-windows on the vendored
// tree's own osd*Open state (GlobalStates.osdVolumeOpen/osdBrightnessOpen/…),
// so there is no toggle: it shows itself when the family's OSD fires. Enabled
// only while the Atoll family is active (family-cycle owns the set), so exactly
// one family's OSD is live at a time.
//
// Test hook: real volume-key traffic cannot reach the nest reliably, so
// `omarchy-shell lunana.atoll-osd test [kind]` drives the OSD render path
// directly (default kind "volume", 8s hold). The Audio→OSD signal wiring
// itself is untouched vendored lunana code.
Item {
  id: root

  property var shell: null
  property var manifest: null

  function test(kind) {
    const next = kind && String(kind).length > 0 ? String(kind) : "volume"
    if (!osdItem.allows(next))
      return "refused kind=" + next + " (game-rule/prefs, nothing rendered)"
    osdItem.show(next, 8000)
    return "shown kind=" + next
  }

  ShellIpc {
    target: "lunana.atoll-osd"
    function test(kind: string): string { return root.test(kind) }
  }

  LnMod.AtollOSD {
    id: osdItem

    // Shell-entry handshake against the shared lunana-vendor/ tree (one
    // GlobalStates universe for all hosts): the vendored
    // tree gates first paint on shellEntryReady/deferredPanelsReady, which only
    // lunana's shell.qml boot sets. Mirror the minimal sequence here.
    Timer {
        interval: 200; repeat: false; running: true
        onTriggered: {
            Lunana.GlobalStates.shellEntryReady = true;
            Lunana.GlobalStates.deferredPanelsReady = true;
        }
    }
  }
}
