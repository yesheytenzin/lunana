import QtQuick
import Quickshell
import qs.Commons
import "vendor/" as Inir
import "vendor/modules/iris/settings" as LnMod

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
}
