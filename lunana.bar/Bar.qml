import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.Commons
import qs.Commons as Commons

// lunana.bar — bar host (M1 content + M4 styles).
//
// A kind:"bar" plugin selected via ~/.config/omarchy/shell.json -> bar.id.
// If this entry point fails to load, the host (shell.qml) falls back to
// omarchy.bar on its own, so a broken bar cannot brick the session.
//
// Content: live Hyprland workspace pills (clickable), focused-window title,
// centred clock, and date — all coloured from the live Omarchy theme tokens.
//
// Style (M4): two looks, chosen by shell.json -> bar.lunana.floating:
//   false (default) a full-width solid strip;
//   true            an inir-style floating rounded island with margins.
Item {
  id: root

  // --- Host-injected properties (see configureBar() in shell.qml). ---
  property string omarchyPath: Quickshell.env("OMARCHY_PATH")
  property var barWidgetRegistry: null
  property var pluginRegistry: null
  property var barConfig: ({})
  property var shell: null
  property var manifest: null

  // --- Derived layout ---
  readonly property string position: (barConfig && barConfig.position) ? barConfig.position : "top"
  readonly property bool vertical: position === "left" || position === "right"
  readonly property bool floating: !!(barConfig && barConfig.lunana && barConfig.lunana.floating === true)
  readonly property int thickness: 38
  readonly property int floatMargin: 8
  readonly property int workspaceCount: 5

  // Live clock + date, refreshed each second.
  property string clockText: ""
  property string dateText: ""
  function refreshTime() {
    var now = new Date()
    root.clockText = Qt.formatDateTime(now, "HH:mm")
    root.dateText = Qt.formatDateTime(now, "ddd d MMM")
  }
  Component.onCompleted: root.refreshTime()
  Timer { interval: 1000; running: true; repeat: true; onTriggered: root.refreshTime() }

  // Focused window (globally focused toplevel), shown beside the workspaces.
  readonly property var activeToplevel: ToplevelManager.activeToplevel
  readonly property string activeTitle: activeToplevel ? (activeToplevel.title || activeToplevel.appId || "") : ""

  // One bar surface per connected screen.
  Variants {
    model: Quickshell.screens

    delegate: Component {
      PanelWindow {
        id: barWindow
        required property var modelData
        screen: modelData

        // This surface's Hyprland monitor and its active workspace id.
        readonly property var monitor: screen ? Hyprland.monitorFor(screen) : Hyprland.focusedMonitor
        readonly property int activeWorkspaceId: monitor && monitor.activeWorkspace ? monitor.activeWorkspace.id : 1

        // Floating leaves margins (transparent window, island capsule); solid
        // fills the strip.
        color: root.floating ? "transparent" : Commons.Color.bar.background
        WlrLayershell.namespace: "lunana-bar"
        WlrLayershell.layer: WlrLayer.Top

        exclusiveZone: root.thickness + (root.floating ? root.floatMargin * 2 : 0)
        anchors {
          top: root.position === "top" || root.vertical
          bottom: root.position === "bottom" || root.vertical
          left: root.position === "left" || !root.vertical
          right: root.position === "right" || !root.vertical
        }
        implicitHeight: root.vertical ? 0 : root.thickness + (root.floating ? root.floatMargin * 2 : 0)
        implicitWidth: root.vertical ? root.thickness : 0

        // The bar body: full-bleed strip, or a margined rounded island.
        Rectangle {
          id: barSurface
          anchors.fill: parent
          anchors.margins: root.floating ? root.floatMargin : 0
          radius: root.floating ? 13 : 0
          color: Commons.Color.bar.background
          border.width: root.floating ? 1 : 0
          border.color: Qt.rgba(Commons.Color.bar.text.r, Commons.Color.bar.text.g, Commons.Color.bar.text.b, 0.15)

          Behavior on color { ColorAnimation { duration: Style.duration(250); easing.type: Easing.OutCubic } }

          // --- Left zone: brand mark + workspace pills + window title ---
          Row {
            id: leftZone
            anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter }
            spacing: 12

            Text {
              anchors.verticalCenter: parent.verticalCenter
              text: "✦ lunana"
              textFormat: Text.PlainText
              color: Commons.Color.bar.text
              font.family: Style.font.family
              font.pixelSize: 13
              font.bold: true
              opacity: 0.9
            }

            Row {
              anchors.verticalCenter: parent.verticalCenter
              spacing: 6

              Repeater {
                model: root.workspaceCount

                delegate: Rectangle {
                  id: pill
                  required property int index
                  readonly property int wsId: index + 1
                  readonly property bool active: wsId === barWindow.activeWorkspaceId

                  width: Math.max(22, pillLabel.implicitWidth + 14)
                  height: 22
                  radius: height / 2
                  color: active ? Commons.Color.bar.active : "transparent"
                  border.width: active ? 0 : 1
                  border.color: Qt.rgba(Commons.Color.bar.text.r, Commons.Color.bar.text.g,
                                        Commons.Color.bar.text.b, hover.hovered ? 0.5 : 0.22)

                  Behavior on color { ColorAnimation { duration: Style.duration(150); easing.type: Easing.OutCubic } }

                  Text {
                    id: pillLabel
                    anchors.centerIn: parent
                    text: String(pill.wsId)
                    textFormat: Text.PlainText
                    color: pill.active ? Commons.Color.bar.background : Commons.Color.bar.text
                    opacity: pill.active ? 1 : (hover.hovered ? 0.95 : 0.6)
                    font.family: Style.font.family
                    font.pixelSize: 12
                    font.bold: pill.active
                  }

                  HoverHandler { id: hover }
                  TapHandler {
                    onTapped: Quickshell.execDetached(["hyprctl", "dispatch", "workspace", String(pill.wsId)])
                  }
                }
              }
            }

            // Focused window title, eliding so it never crowds the centre clock.
            Text {
              anchors.verticalCenter: parent.verticalCenter
              visible: root.activeTitle !== ""
              text: root.activeTitle
              textFormat: Text.PlainText
              color: Commons.Color.bar.text
              opacity: 0.7
              font.family: Style.font.family
              font.pixelSize: 12
              elide: Text.ElideRight
              width: Math.min(implicitWidth, 340)
            }
          }

          // --- Centre zone: clock ---
          Text {
            anchors.centerIn: parent
            text: root.clockText
            textFormat: Text.PlainText
            color: Commons.Color.bar.text
            font.family: Style.font.family
            font.pixelSize: 14
            font.bold: true
          }

          // --- Right zone: date ---
          Text {
            anchors { right: parent.right; rightMargin: 16; verticalCenter: parent.verticalCenter }
            text: root.dateText
            textFormat: Text.PlainText
            color: Commons.Color.bar.text
            opacity: 0.75
            font.family: Style.font.family
            font.pixelSize: 13
          }

          // Accent hairline (solid strip only; the island uses its border).
          Rectangle {
            visible: !root.floating
            height: 1
            color: Commons.Color.bar.active
            opacity: 0.8
            anchors {
              left: parent.left
              right: parent.right
              bottom: root.position === "bottom" ? undefined : parent.bottom
              top: root.position === "bottom" ? parent.top : undefined
            }
          }
        }
      }
    }
  }
}
