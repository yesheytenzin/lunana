import QtQuick
import Quickshell
import qs.Commons
import "vendor/modules/closeConfirm" as LnMod

// lunana.closeconfirm — Lunana exact close-confirm host (kind: overlay).
//
// Resident mount of inir's exact CloseConfirm; its IpcHandler owns the dialog
// lifecycle (trigger/close). This host only re-exposes it on the Omarchy
// ShellIpc path. NOTE: the vendored trigger falls back to `niri msg` when its
// cache is stale, which has no Hyprland analog yet (PORTING.md Wave 1).
Item {
  id: root

  property var shell: null
  property var manifest: null

  property bool opened: confirmItem.dialogVisible

  function open(payloadJson) { confirmItem.trigger() }
  function close() { confirmItem.close() }
  function toggle() { root.opened ? root.close() : root.open("") }

  ShellIpc {
    target: "lunana.closeconfirm"
    function toggle(): void { root.toggle() }
    function open(): void { root.open("") }
    function close(): void { root.close() }
  }

  LnMod.CloseConfirm {
    id: confirmItem
  }
}
