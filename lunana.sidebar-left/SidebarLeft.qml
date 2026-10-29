import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import qs.Commons
import qs.Commons as Commons

// lunana.sidebar-left — M3 left sidebar (kind: overlay).
//
// A left-side panel with a large clock, live system stats, and quick launchers.
// inir's left sidebar also hosts AI chat, YT Music, Wallhaven, and an anime
// tracker; those are large external integrations deliberately left for later —
// this M3 slice is the panel shell plus the widgets that stand on their own.
// Toggled via `omarchy-shell lunana.sidebar-left toggle`.
Item {
  id: root

  property string omarchyPath: Quickshell.env("OMARCHY_PATH")
  property var shell: null
  property var manifest: null

  property bool opened: false
  property string clockText: ""
  property string dateText: ""
  property string cpuText: "—"
  property string memText: "—"

  function open(payloadJson) { root.opened = true }
  function close() { root.opened = false }
  function toggle() { root.opened = !root.opened }

  function refreshTime() {
    var now = new Date()
    root.clockText = Qt.formatDateTime(now, "HH:mm")
    root.dateText = Qt.formatDateTime(now, "dddd, d MMMM")
  }
  Component.onCompleted: root.refreshTime()
  Timer { interval: 1000; running: true; repeat: true; onTriggered: root.refreshTime() }

  onOpenedChanged: if (opened) statsProbe.running = true
  // While open, refresh stats a few times a minute.
  Timer { interval: 3000; running: root.opened; repeat: true; onTriggered: statsProbe.running = true }

  Process {
    id: statsProbe
    running: false
    command: ["sh", "-c",
      "load=$(awk '{print $1}' /proc/loadavg); " +
      "mem=$(free -m | awk '/^Mem:/{printf \"%d / %d MB\", $3, $2}'); " +
      "echo \"$load|$mem\""]
    stdout: StdioCollector {
      onStreamFinished: {
        var parts = String(text).trim().split("|")
        if (parts.length === 2) { root.cpuText = parts[0]; root.memText = parts[1] }
      }
    }
  }

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

        Rectangle {
          id: panel
          width: 330
          anchors { top: parent.top; bottom: parent.bottom; left: parent.left }
          color: Qt.rgba(Commons.Color.bar.background.r, Commons.Color.bar.background.g,
                         Commons.Color.bar.background.b, 0.97)

          MouseArea { anchors.fill: parent }

          Rectangle {
            width: 1; height: parent.height
            anchors.right: parent.right
            color: Qt.rgba(Commons.Color.bar.text.r, Commons.Color.bar.text.g, Commons.Color.bar.text.b, 0.12)
          }

          Column {
            anchors { fill: parent; margins: 24; topMargin: 30 }
            spacing: 22

            // Clock block
            Column {
              spacing: 2
              Text {
                text: root.clockText
                textFormat: Text.PlainText
                color: Commons.Color.foreground
                font.family: Style.font.family
                font.pixelSize: 46
                font.bold: true
              }
              Text {
                text: root.dateText
                textFormat: Text.PlainText
                color: Commons.Color.bar.text
                opacity: 0.75
                font.family: Style.font.family
                font.pixelSize: 14
              }
            }

            // Stats card
            Rectangle {
              width: parent.width
              height: statsCol.implicitHeight + 28
              radius: 12
              color: Qt.rgba(Commons.Color.bar.text.r, Commons.Color.bar.text.g, Commons.Color.bar.text.b, 0.07)
              Column {
                id: statsCol
                anchors { fill: parent; margins: 14 }
                spacing: 10
                Text {
                  text: "System"
                  textFormat: Text.PlainText
                  color: Commons.Color.bar.text
                  opacity: 0.6
                  font.family: Style.font.family
                  font.pixelSize: 12
                  font.bold: true
                }
                Row {
                  spacing: 8
                  Text { text: "CPU load"; color: Commons.Color.bar.text; opacity: 0.8; font.family: Style.font.family; font.pixelSize: 13; textFormat: Text.PlainText }
                  Text { text: root.cpuText; color: Commons.Color.bar.active; font.family: Style.font.family; font.pixelSize: 13; font.bold: true; textFormat: Text.PlainText }
                }
                Row {
                  spacing: 8
                  Text { text: "Memory"; color: Commons.Color.bar.text; opacity: 0.8; font.family: Style.font.family; font.pixelSize: 13; textFormat: Text.PlainText }
                  Text { text: root.memText; color: Commons.Color.bar.active; font.family: Style.font.family; font.pixelSize: 13; font.bold: true; textFormat: Text.PlainText }
                }
              }
            }

            // Quick launchers
            Column {
              width: parent.width
              spacing: 8
              Text {
                text: "Launch"
                textFormat: Text.PlainText
                color: Commons.Color.bar.text
                opacity: 0.6
                font.family: Style.font.family
                font.pixelSize: 12
                font.bold: true
              }
              LaunchButton { label: "Terminal";  exec: ["alacritty"] }
              LaunchButton { label: "Browser";   exec: ["xdg-open", "https://"] }
              LaunchButton { label: "Files";     exec: ["xdg-open", root.home()] }
            }
          }
        }
      }
    }
  }

  function home() { return Quickshell.env("HOME") }

  component LaunchButton: Rectangle {
    id: lb
    property string label: ""
    property var exec: []
    width: parent ? parent.width : 280
    height: 38
    radius: 9
    color: Qt.rgba(Commons.Color.bar.text.r, Commons.Color.bar.text.g, Commons.Color.bar.text.b,
                   lbHover.hovered ? 0.18 : 0.08)
    Behavior on color { ColorAnimation { duration: Style.duration(120) } }
    Text {
      anchors { fill: parent; leftMargin: 14 }
      verticalAlignment: Text.AlignVCenter
      text: lb.label
      textFormat: Text.PlainText
      color: Commons.Color.bar.text
      font.family: Style.font.family
      font.pixelSize: 13
    }
    HoverHandler { id: lbHover }
    TapHandler { onTapped: { Quickshell.execDetached(lb.exec); root.close() } }
  }
}
