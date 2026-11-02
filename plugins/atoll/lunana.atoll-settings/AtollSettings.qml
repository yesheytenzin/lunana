import QtQuick
import Quickshell
import qs.Commons
import "../../lunana-vendor/" as Lunana
import "../../lunana-vendor/modules/atoll/settings" as LnMod

// lunana.atoll-settings — Lunana Atoll settings host (Compositor page shows Hyprland options). (kind: overlay).
//
// Hosts lunana's exact AtollSettingsOverlay (modules/atoll/settings); visibility is the vendored tree's own
// GlobalStates.settingsOverlayOpen, flipped here so `omarchy-shell shell toggle lunana.atoll-settings`
// summons it.
Item {
  id: root

  property var shell: null
  property var manifest: null

  readonly property bool opened: Lunana.GlobalStates.settingsOverlayOpen

  function open(payloadJson) { Lunana.GlobalStates.settingsOverlayOpen = true }
  function close() { Lunana.GlobalStates.settingsOverlayOpen = false }
  function toggle() { root.opened ? root.close() : root.open("") }

  ShellIpc {
    target: "lunana.atoll-settings"
    function toggle(): void { root.toggle() }
    function open(): void { root.open("") }
    function close(): void { root.close() }
  }

  LnMod.AtollSettingsOverlay {
  }

    // Shell-entry handshake against the shared lunana-vendor/ tree (one
    // GlobalStates universe for all hosts): the vendored tree gates first paint on
    // shellEntryReady/deferredPanelsReady, which only lunana's shell.qml boot
    // sets. Mirror the minimal sequence here.
    Timer {
        interval: 200; repeat: false; running: true
        onTriggered: {
            Lunana.GlobalStates.shellEntryReady = true;
            Lunana.GlobalStates.deferredPanelsReady = true;
        }
    }
}
