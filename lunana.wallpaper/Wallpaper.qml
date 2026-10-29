import QtQuick
import Quickshell
import "vendor/" as Inir
import "vendor/modules/wallpaperSelector" as LnSel
import "vendor/modules/wallpaperLauncher" as LnLaunch

// lunana.wallpaper — Lunana wallpaper host (kind: overlay).
//
// The selector is summoned here via GlobalStates.wallpaperSelectorOpen; the
// launcher stays resident for the background/widget flows that open it.
Item {
  id: root

  property var shell: null
  property var manifest: null

  readonly property bool opened: Inir.GlobalStates.wallpaperSelectorOpen

  function open(payloadJson) { Inir.GlobalStates.wallpaperSelectorOpen = true }
  function close() { Inir.GlobalStates.wallpaperSelectorOpen = false }
  function toggle() { root.opened ? root.close() : root.open("") }

  ShellIpc {
    target: "lunana.wallpaper"
    function toggle(): void { root.toggle() }
    function open(): void { root.open("") }
    function close(): void { root.close() }
  }

  LnSel.WallpaperSelector {
  }

  LnLaunch.WallpaperLauncher {
  }
}
