import QtQuick
import Quickshell
import qs.Commons
import "../../lunana-vendor/" as Inir

// lunana.settings — Lunana ii settings host (kind: overlay).
//
// inir's settings.qml is an ApplicationWindow (always visible), so it is
// Loader-gated on `opened` instead of resident-mounted. Every page loads; the
// Compositor page shows Hyprland-relevant options (Wave 5).
Item {
  id: root

  property var shell: null
  property var manifest: null

  property bool opened: false

  function open(payloadJson) { root.opened = true }
  function close() { root.opened = false }
  function toggle() { root.opened = !root.opened }

  ShellIpc {
    target: "lunana.settings"
    function toggle(): void { root.toggle() }
    function open(): void { root.open("") }
    function close(): void { root.close() }
  }

  Loader {
    active: root.opened
    // File-URL, not the Inir.Settings type: the root qmldir registers the
    // lowercase stem and the host must not depend on that spelling.
    source: "../../lunana-vendor/settings.qml"
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
