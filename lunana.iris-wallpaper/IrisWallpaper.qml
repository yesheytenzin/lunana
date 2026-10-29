import QtQuick
import Quickshell
import qs.Commons
import Quickshell.Wayland
import "../../lunana-vendor/" as Inir
import "../../lunana-vendor/modules/iris/wallpaper" as LnMod

// lunana.iris-wallpaper — iRiS wallpaper gallery host (the chassis galleryLoader). (kind: overlay).
//
// IrisWallpaperPicker is content (a plain Item), so — like lunana.iris-control —
// the host wraps it per screen in a layershell PanelWindow and drives
// GlobalStates.wallpaperSelectorOpen. The picker's own `here`/`morphOpen` logic
// keys off GlobalStates.wallpaperSelectorTargetMonitor, so it reveals on the
// targeted output and stays dormant on the others.
Item {
  id: root

  property var shell: null
  property var manifest: null

  readonly property bool opened: Inir.GlobalStates.wallpaperSelectorOpen

  function open(payloadJson) { Inir.GlobalStates.wallpaperSelectorOpen = true }
  function close() { Inir.GlobalStates.wallpaperSelectorOpen = false }
  function toggle() { root.opened ? root.close() : root.open("") }

  ShellIpc {
    target: "lunana.iris-wallpaper"
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
        WlrLayershell.namespace: "lunana-iris-wallpaper"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: root.opened ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        anchors { top: true; bottom: true; left: true; right: true }
        MouseArea { anchors.fill: parent; onClicked: root.close() }
        Item { anchors.fill: parent; focus: root.opened; Keys.onEscapePressed: root.close() }
        Loader {
          anchors.fill: parent
          active: root.opened
          sourceComponent: Component {
            LnMod.IrisWallpaperPicker {
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
      Inir.GlobalStates.shellEntryReady = true;
      Inir.GlobalStates.deferredPanelsReady = true;
    }
  }
}
