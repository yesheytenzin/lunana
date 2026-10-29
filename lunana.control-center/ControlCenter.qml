import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import qs.Commons
import qs.Commons as Commons

// lunana.control-center — M3 control center (kind: overlay).
//
// A right-side panel with live volume and brightness sliders and quick actions.
// Reads current levels through wpctl / brightnessctl on open and writes back on
// drag. Toggled via `omarchy-shell lunana.control-center toggle`.
Item {
  id: root

  property string omarchyPath: Quickshell.env("OMARCHY_PATH")
  property var shell: null
  property var manifest: null

  property bool opened: false
  property int volume: 0
  property int brightness: 0

  function open(payloadJson) { root.opened = true }
  function close() { root.opened = false }
  function toggle() { root.opened = !root.opened }

  onOpenedChanged: if (opened) { volumeProbe.running = true; brightnessProbe.running = true }

  ShellIpc {
    target: "lunana.control-center"
    function toggle(): void { root.toggle() }
    function open(): void { root.open("") }
    function close(): void { root.close() }
  }

  // --- level probes ---
  Process {
    id: volumeProbe
    running: false
    command: ["sh", "-c", "wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null | awk '{print $2}'"]
    stdout: StdioCollector {
      onStreamFinished: {
        var v = parseFloat(String(text).trim())
        if (!isNaN(v)) root.volume = Math.round(v * 100)
      }
    }
  }
  Process {
    id: brightnessProbe
    running: false
    command: ["sh", "-c", "brightnessctl -m 2>/dev/null | awk -F, '{print $4}' | tr -d '%'"]
    stdout: StdioCollector {
      onStreamFinished: {
        var v = parseInt(String(text).trim())
        if (!isNaN(v)) root.brightness = v
      }
    }
  }

  function setVolume(v) {
    root.volume = v
    Quickshell.execDetached(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", v + "%"])
  }
  function setBrightness(v) {
    root.brightness = v
    Quickshell.execDetached(["brightnessctl", "-q", "s", Math.max(1, v) + "%"])
  }
  function toggleMute() {
    Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"])
  }

  Variants {
    model: Quickshell.screens

    delegate: Component {
      PanelWindow {
        id: ccWindow
        required property var modelData
        screen: modelData

        visible: root.opened
        color: "transparent"
        WlrLayershell.namespace: "lunana-control-center"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: root.opened ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        anchors { top: true; bottom: true; left: true; right: true }

        // Click outside the panel closes.
        MouseArea { anchors.fill: parent; onClicked: root.close() }
        Item { anchors.fill: parent; focus: root.opened; Keys.onEscapePressed: root.close() }

        // The right-docked panel.
        Rectangle {
          id: panel
          width: 360
          anchors { top: parent.top; bottom: parent.bottom; right: parent.right }
          color: Qt.rgba(Commons.Color.bar.background.r, Commons.Color.bar.background.g,
                         Commons.Color.bar.background.b, 0.97)

          // swallow clicks so they don't fall through to the close MouseArea
          MouseArea { anchors.fill: parent }

          Rectangle {
            width: 1; height: parent.height
            anchors.left: parent.left
            color: Qt.rgba(Commons.Color.bar.text.r, Commons.Color.bar.text.g, Commons.Color.bar.text.b, 0.12)
          }

          Column {
            anchors { fill: parent; margins: 22; topMargin: 28 }
            spacing: 22

            Text {
              text: "✦ Control Center"
              textFormat: Text.PlainText
              color: Commons.Color.foreground
              font.family: Style.font.family
              font.pixelSize: 17
              font.bold: true
            }

            // Volume
            Column {
              width: parent.width
              spacing: 8
              Text {
                text: "Volume   " + root.volume + "%"
                textFormat: Text.PlainText
                color: Commons.Color.bar.text
                font.family: Style.font.family
                font.pixelSize: 13
              }
              LunaSlider { width: parent.width; value: root.volume; onMovedTo: (v) => root.setVolume(v) }
            }

            // Brightness
            Column {
              width: parent.width
              spacing: 8
              Text {
                text: "Brightness   " + root.brightness + "%"
                textFormat: Text.PlainText
                color: Commons.Color.bar.text
                font.family: Style.font.family
                font.pixelSize: 13
              }
              LunaSlider { width: parent.width; value: root.brightness; onMovedTo: (v) => root.setBrightness(v) }
            }

            // Quick actions
            Row {
              spacing: 10
              LunaButton { label: "Mute";     onActivated: root.toggleMute() }
              LunaButton { label: "Settings"; onActivated: { Quickshell.execDetached(["omarchy-menu"]); root.close() } }
              LunaButton { label: "Lock";     onActivated: { Quickshell.execDetached(["omarchy-lock-screen"]); root.close() } }
            }
          }
        }
      }
    }
  }

  // --- small reusable controls ---
  component LunaSlider: Item {
    id: slider
    property int value: 0
    signal movedTo(int v)
    height: 18

    Rectangle {
      id: track
      anchors.verticalCenter: parent.verticalCenter
      width: parent.width
      height: 8
      radius: 4
      color: Qt.rgba(Commons.Color.bar.text.r, Commons.Color.bar.text.g, Commons.Color.bar.text.b, 0.15)

      Rectangle {
        width: parent.width * Math.max(0, Math.min(1, slider.value / 100))
        height: parent.height
        radius: 4
        color: Commons.Color.bar.active
      }
    }
    MouseArea {
      anchors.fill: parent
      function apply(x) {
        var frac = Math.max(0, Math.min(1, x / slider.width))
        slider.movedTo(Math.round(frac * 100))
      }
      onPressed: (m) => apply(m.x)
      onPositionChanged: (m) => { if (pressed) apply(m.x) }
    }
  }

  component LunaButton: Rectangle {
    id: btn
    property string label: ""
    signal activated()
    width: Math.max(72, btnText.implicitWidth + 24)
    height: 34
    radius: 9
    color: Qt.rgba(Commons.Color.bar.text.r, Commons.Color.bar.text.g, Commons.Color.bar.text.b,
                   btnHover.hovered ? 0.18 : 0.08)
    Behavior on color { ColorAnimation { duration: Style.duration(120) } }
    Text {
      id: btnText
      anchors.centerIn: parent
      text: btn.label
      textFormat: Text.PlainText
      color: Commons.Color.bar.text
      font.family: Style.font.family
      font.pixelSize: 13
    }
    HoverHandler { id: btnHover }
    TapHandler { onTapped: btn.activated() }
  }
}
