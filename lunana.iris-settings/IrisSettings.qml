import QtQuick
import Quickshell
import qs.Commons
import "../../lunana-vendor/" as Inir
import "../../lunana-vendor/modules/iris/settings" as LnMod

// lunana.iris-settings — Lunana iRiS settings host (Compositor page shows Hyprland options). (kind: overlay).
//
// Hosts inir's exact IrisSettingsOverlay (modules/iris/settings); visibility is the vendored tree's own
// GlobalStates.settingsOverlayOpen, flipped here so `omarchy-shell shell toggle lunana.iris-settings`
// summons it.
Item {
  id: root

  property var shell: null
  property var manifest: null

  readonly property bool opened: Inir.GlobalStates.settingsOverlayOpen

  function open(payloadJson) { Inir.GlobalStates.settingsOverlayOpen = true }
  function close() { Inir.GlobalStates.settingsOverlayOpen = false }
  function toggle() { root.opened ? root.close() : root.open("") }

  ShellIpc {
    target: "lunana.iris-settings"
    function toggle(): void { root.toggle() }
    function open(): void { root.open("") }
    function close(): void { root.close() }
  }

  LnMod.IrisSettingsOverlay {
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
