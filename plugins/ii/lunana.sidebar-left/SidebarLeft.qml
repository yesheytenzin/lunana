import QtQuick
import Quickshell
import "../../lunana-vendor/" as Inir
import Quickshell.Wayland
import qs.Commons
import qs.Commons as Commons
import "../../lunana-vendor/modules/common" as LnCommon
import "../../lunana-vendor/modules/sidebarLeft" as LSLeft

// lunana.sidebar-left — exact ii left sidebar (kind: overlay).
//
// A fullscreen transparent layer hosting inir's exact SidebarLeftContent from
// the shared lunana-vendor/ tree. This file is only the Omarchy overlay shell
// (summon, layer, close) around it.
//
// Toggled via `omarchy-shell lunana.sidebar-left toggle`.
Item {
  id: root

  property string omarchyPath: Quickshell.env("OMARCHY_PATH")
  property var shell: null
  property var manifest: null

  property bool opened: false

  function open(payloadJson) { root.opened = true }
  function close() { root.opened = false }
  function toggle() { root.opened = !root.opened }

  ShellIpc {
    target: "lunana.sidebar-left"
    function toggle(): void { root.toggle() }
    function open(): void { root.open("") }
    function close(): void { root.close() }
  }

  Variants {
    model: Quickshell.screens

    delegate: Component {
      PanelWindow {
        id: sbWindow
        required property var modelData
        screen: modelData

        visible: root.opened
        color: "transparent"
        WlrLayershell.namespace: "lunana-sidebar-left"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: root.opened ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        anchors { top: true; bottom: true; left: true; right: true }

        MouseArea { anchors.fill: parent; onClicked: root.close() }
        Item { anchors.fill: parent; focus: root.opened; Keys.onEscapePressed: root.close() }

        // The exact ii panel, edge-anchored at inir's own sidebar width.
        // (anchors.fill would stretch the panel full-screen; the wallpaper
        // backdrop child still covers the output via screenWidth/Height.)
        LSLeft.SidebarLeftContent {
          anchors { top: parent.top; bottom: parent.bottom; left: parent.left }
          width: LnCommon.Appearance.sizes.sidebarWidth
          panelVisible: root.opened
          panelScreen: sbWindow.screen
          screenWidth: sbWindow.width
          screenHeight: sbWindow.height
        }
      }
    }
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
