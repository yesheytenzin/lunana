import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.Commons
import qs.Commons as Commons

// lunana.overview — M2 workspace overview (kind: overlay).
//
// A dim fullscreen overlay showing workspaces 1..N as columns, each listing its
// live Hyprland windows. Click a window to focus it; click a workspace header
// to switch to it; Escape or a background click closes. Toggled from a keybind
// via `omarchy-shell lunana.overview toggle` (ShellIpc) or the host's
// `shell toggle lunana.overview` (open/close/toggle lifecycle).
Item {
  id: root

  // Host-injected (overlay plugins receive these).
  property string omarchyPath: Quickshell.env("OMARCHY_PATH")
  property var shell: null
  property var manifest: null

  property bool opened: false
  readonly property int workspaceCount: 5

  function open(payloadJson) { root.opened = true }
  function close() { root.opened = false }
  function toggle() { root.opened = !root.opened }

  // Reachable as `omarchy-shell lunana.overview <fn>`.
  ShellIpc {
    target: "lunana.overview"
    function toggle(): void { root.toggle() }
    function open(): void { root.open("") }
    function close(): void { root.close() }
  }

  function focusWindow(address) {
    if (address) Quickshell.execDetached(["hyprctl", "dispatch", "focuswindow", "address:" + address])
    root.close()
  }
  function switchWorkspace(wsId) {
    Quickshell.execDetached(["hyprctl", "dispatch", "workspace", String(wsId)])
    root.close()
  }

  Variants {
    model: Quickshell.screens

    delegate: Component {
      PanelWindow {
        id: overlayWindow
        required property var modelData
        screen: modelData

        visible: root.opened
        color: Qt.rgba(0, 0, 0, 0.55)
        WlrLayershell.namespace: "lunana-overview"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: root.opened ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        anchors { top: true; bottom: true; left: true; right: true }

        // Background click closes.
        MouseArea {
          anchors.fill: parent
          onClicked: root.close()
        }

        // Escape closes.
        Item {
          anchors.fill: parent
          focus: root.opened
          Keys.onEscapePressed: root.close()
        }

        Column {
          anchors.centerIn: parent
          spacing: 18
          width: Math.min(overlayWindow.width - 120, 1100)

          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "✦ Overview"
            textFormat: Text.PlainText
            color: Commons.Color.foreground
            font.family: Style.font.family
            font.pixelSize: 18
            font.bold: true
          }

          Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 16

            Repeater {
              model: root.workspaceCount

              delegate: Rectangle {
                id: wsColumn
                required property int index
                readonly property int wsId: index + 1
                readonly property bool activeWs: overlayWindow.screen
                  && Hyprland.monitorFor(overlayWindow.screen)
                  && Hyprland.monitorFor(overlayWindow.screen).activeWorkspace
                  && Hyprland.monitorFor(overlayWindow.screen).activeWorkspace.id === wsId

                width: 200
                height: 300
                radius: 14
                color: Qt.rgba(Commons.Color.bar.background.r, Commons.Color.bar.background.g,
                               Commons.Color.bar.background.b, 0.92)
                border.width: activeWs ? 2 : 1
                border.color: activeWs ? Commons.Color.bar.active
                                       : Qt.rgba(Commons.Color.bar.text.r, Commons.Color.bar.text.g, Commons.Color.bar.text.b, 0.18)

                Column {
                  anchors { fill: parent; margins: 12 }
                  spacing: 8

                  // Header — click to switch to this workspace.
                  Rectangle {
                    width: parent.width
                    height: 30
                    radius: 8
                    color: wsColumn.activeWs ? Commons.Color.bar.active : "transparent"
                    Text {
                      anchors.centerIn: parent
                      text: "Workspace " + wsColumn.wsId
                      textFormat: Text.PlainText
                      color: wsColumn.activeWs ? Commons.Color.bar.background : Commons.Color.bar.text
                      font.family: Style.font.family
                      font.pixelSize: 13
                      font.bold: true
                    }
                    TapHandler { onTapped: root.switchWorkspace(wsColumn.wsId) }
                  }

                  // Windows on this workspace.
                  Column {
                    width: parent.width
                    spacing: 6

                    Repeater {
                      model: Hyprland.toplevels.values

                      delegate: Rectangle {
                        id: winRow
                        required property var modelData
                        readonly property var tl: modelData
                        readonly property bool onThisWs: tl && tl.workspace && tl.workspace.id === wsColumn.wsId
                        readonly property string label: tl && tl.wayland
                          ? (tl.wayland.title || tl.wayland.appId || "window") : "window"

                        visible: onThisWs
                        width: parent.width
                        height: onThisWs ? 30 : 0
                        radius: 7
                        color: Qt.rgba(Commons.Color.bar.text.r, Commons.Color.bar.text.g, Commons.Color.bar.text.b,
                                       wHover.hovered ? 0.18 : 0.08)

                        Text {
                          anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                          verticalAlignment: Text.AlignVCenter
                          text: winRow.label
                          textFormat: Text.PlainText
                          elide: Text.ElideRight
                          color: Commons.Color.bar.text
                          font.family: Style.font.family
                          font.pixelSize: 12
                        }

                        HoverHandler { id: wHover }
                        TapHandler { onTapped: if (winRow.tl) root.focusWindow(winRow.tl.address) }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
