import QtQuick
import Quickshell
import qs.Commons
import Quickshell.Wayland
import "../../lunana-vendor/" as Lunana
import "../../lunana-vendor/modules/atoll/wallpaper" as LnMod

// lunana.atoll-wallpaper — Atoll wallpaper gallery host (the chassis galleryLoader). (kind: overlay).
//
// AtollWallpaperPicker is content (a plain Item), so — like lunana.atoll-control —
// the host wraps it per screen in a layershell PanelWindow and drives
// GlobalStates.wallpaperSelectorOpen. The picker's own `here`/`morphOpen` logic
// keys off GlobalStates.wallpaperSelectorTargetMonitor, so it reveals on the
// targeted output and stays dormant on the others.
Item {
  id: root

  property var shell: null
  property var manifest: null

  readonly property bool opened: Lunana.GlobalStates.wallpaperSelectorOpen

  function open(payloadJson) { Lunana.GlobalStates.wallpaperSelectorOpen = true }
  function close() { Lunana.GlobalStates.wallpaperSelectorOpen = false }
  function toggle() { root.opened ? root.close() : root.open("") }

  ShellIpc {
    target: "lunana.atoll-wallpaper"
    function toggle(): void { root.toggle() }
    function open(): void { root.open("") }
    function close(): void { root.close() }
  }

  Variants {
    model: Quickshell.screens
    delegate: Component {
      PanelWindow {
        required property var modelData
        screen: modelData
        visible: root.opened
        color: "transparent"
        WlrLayershell.namespace: "lunana-atoll-wallpaper"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: root.opened ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        anchors { top: true; bottom: true; left: true; right: true }
        MouseArea { anchors.fill: parent; onClicked: root.close() }
        Item { anchors.fill: parent; focus: root.opened; Keys.onEscapePressed: root.close() }
        Loader {
          anchors.fill: parent
          active: root.opened
          sourceComponent: Component {
            LnMod.AtollWallpaperPicker {
              screen: modelData
            }
          }
        }
      }
    }
  }

  Timer {
    interval: 200; repeat: false; running: true
    onTriggered: {
      Lunana.GlobalStates.shellEntryReady = true;
      Lunana.GlobalStates.deferredPanelsReady = true;
    }
  }
}
