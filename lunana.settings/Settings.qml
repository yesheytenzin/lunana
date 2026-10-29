import QtQuick
import Quickshell
import qs.Commons
import "vendor/" as Inir

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
    sourceComponent: Component {
      Inir.Settings {
      }
    }
  }
}
