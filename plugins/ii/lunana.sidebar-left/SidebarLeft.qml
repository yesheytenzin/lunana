import QtQuick
import Quickshell
import "../../lunana-vendor/" as Inir
import Quickshell.Wayland
import qs.Commons
import "../../lunana-vendor/modules/common" as LnCommon

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
  property bool _contentWarningLogged: false

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
        //
        // The vendored sidebar compiles in its own file so a missing optional
        // QML module (org.kde.syntaxhighlighting, used by AiChat code blocks)
        // becomes a Loader error here instead of failing the whole overlay
        // plugin. Without that isolation the host never loads and the layer
        // never opens at all.
        Loader {
          id: contentLoader
          anchors { top: parent.top; bottom: parent.bottom; left: parent.left }
          width: LnCommon.Appearance.sizes.sidebarWidth
          // Resident, like the original host: the vendored panel keeps its
          // selected tab and widget state across open/close cycles. The
          // PanelWindow's visibility and panelVisible gate what is shown.
          source: "SidebarContent.qml"

          Binding { target: contentLoader.item; property: "panelVisible"; value: root.opened; when: contentLoader.item !== null }
          Binding { target: contentLoader.item; property: "panelScreen"; value: sbWindow.screen; when: contentLoader.item !== null }
          Binding { target: contentLoader.item; property: "screenWidth"; value: sbWindow.width; when: contentLoader.item !== null }
          Binding { target: contentLoader.item; property: "screenHeight"; value: sbWindow.height; when: contentLoader.item !== null }

          onStatusChanged: {
            if (status === Loader.Error && !root._contentWarningLogged) {
              root._contentWarningLogged = true
              console.warn("[lunana.sidebar-left] content failed to load; the AI chat tab needs org.kde.syntaxhighlighting (syntax-highlighting)")
            }
          }
        }

        // Diagnostic shown instead of the panel when the vendored content
        // cannot compile. It deliberately accepts no mouse input, so the
        // backdrop MouseArea still closes the overlay on click.
        Rectangle {
          id: fallback
          visible: contentLoader.status === Loader.Error
          anchors { top: parent.top; bottom: parent.bottom; left: parent.left }
          width: LnCommon.Appearance.sizes.sidebarWidth
          color: LnCommon.Appearance.colors.colLayer0
          radius: LnCommon.Appearance.rounding.large
          border.width: 1
          border.color: LnCommon.Appearance.colors.colLayer0Border

          Column {
            anchors.centerIn: parent
            width: parent.width - 48
            spacing: 12

            Text {
              width: parent.width
              text: "Left sidebar unavailable"
              color: LnCommon.Appearance.colors.colOnLayer0
              font.pixelSize: 18
              font.bold: true
              horizontalAlignment: Text.AlignHCenter
              wrapMode: Text.WordWrap
            }
            Text {
              width: parent.width
              text: "The sidebar content could not load. The AI chat tab requires the KDE syntax-highlighting QML module.\n\nInstall `syntax-highlighting` (org.kde.syntaxhighlighting) and restart the shell. If it is already installed, check the shell log for the QML error."
              color: LnCommon.Appearance.colors.colOnLayer0
              opacity: 0.8
              font.pixelSize: 13
              horizontalAlignment: Text.AlignHCenter
              wrapMode: Text.WordWrap
              lineHeight: 1.2
            }
            Text {
              width: parent.width
              text: "Click anywhere to close."
              color: LnCommon.Appearance.colors.colOnLayer0
              opacity: 0.6
              font.pixelSize: 12
              horizontalAlignment: Text.AlignHCenter
            }
          }
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
