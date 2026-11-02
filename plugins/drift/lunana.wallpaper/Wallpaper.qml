import QtQuick
import Quickshell
import qs.Commons
import "../../lunana-vendor/" as Lunana
import "../../lunana-vendor/modules/wallpaperSelector" as LnSel
import "../../lunana-vendor/modules/wallpaperLauncher" as LnLaunch

// lunana.wallpaper — Lunana wallpaper host (kind: overlay).
//
// The selector is summoned here via GlobalStates.wallpaperSelectorOpen; the
// launcher stays resident for the background/widget flows that open it.
Item {
  id: root

  property var shell: null
  property var manifest: null

  readonly property bool opened: Lunana.GlobalStates.wallpaperSelectorOpen

  function open(payloadJson) { Lunana.GlobalStates.wallpaperSelectorOpen = true }
  function close() { Lunana.GlobalStates.wallpaperSelectorOpen = false }
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

    // Shell-entry handshake in this plugin's singleton universe (each
    // installed plugin carries its own vendor/ copy, hence its own
    // GlobalStates): the vendored tree gates first paint on
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
