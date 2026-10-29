import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.Commons
import qs.Commons as Commons

// lunana.dock — M2 running-apps dock (kind: service).
//
// A bottom dock reserving its own strip, showing every live Hyprland window as
// a pill (focused one highlighted in the theme accent). Clicking focuses that
// window. Decoupled from Omarchy's own dock; coloured from Omarchy theme
// tokens. Icons and pinned apps are a later polish — M2 proves live window
// tracking and focus.
Item {
  id: root

  property string omarchyPath: Quickshell.env("OMARCHY_PATH")
  property var shell: null
  property var manifest: null

  readonly property int dockHeight: 40

  Variants {
    model: Quickshell.screens

    delegate: Component {
      PanelWindow {
        id: dockWindow
        required property var modelData
        screen: modelData

        color: "transparent"
        WlrLayershell.namespace: "lunana-dock"
        WlrLayershell.layer: WlrLayer.Top

        anchors { bottom: true; left: true; right: true }
        implicitHeight: root.dockHeight + 10
        // Reserve the strip so the dock never overlaps tiled windows.
        exclusiveZone: root.dockHeight + 6

        // Centred floating capsule holding the window pills.
        Rectangle {
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.bottom: parent.bottom
          anchors.bottomMargin: 6
          height: root.dockHeight
          width: Math.min(dockWindow.width - 24, dockRow.implicitWidth + 20)
          radius: 14
          color: Commons.Color.bar.background
          border.width: 1
          border.color: Qt.rgba(Commons.Color.bar.text.r, Commons.Color.bar.text.g, Commons.Color.bar.text.b, 0.15)
          visible: Hyprland.toplevels.values.length > 0

          Row {
            id: dockRow
            anchors.centerIn: parent
            spacing: 6

            Repeater {
              model: Hyprland.toplevels.values

              delegate: Rectangle {
                id: appPill
                required property var modelData
                readonly property var tl: modelData
                readonly property string label: tl && tl.wayland
                  ? (tl.wayland.appId || tl.wayland.title || "window") : "window"
                readonly property bool active: tl && tl.wayland && tl.wayland.activated

                height: 28
                width: Math.min(170, pillText.implicitWidth + 20)
                radius: 9
                color: active ? Commons.Color.bar.active
                              : Qt.rgba(Commons.Color.bar.text.r, Commons.Color.bar.text.g, Commons.Color.bar.text.b,
                                        hover.hovered ? 0.16 : 0.07)

                Behavior on color { ColorAnimation { duration: Style.duration(150); easing.type: Easing.OutCubic } }

                Text {
                  id: pillText
                  anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                  verticalAlignment: Text.AlignVCenter
                  text: appPill.label
                  textFormat: Text.PlainText
                  elide: Text.ElideRight
                  color: appPill.active ? Commons.Color.bar.background : Commons.Color.bar.text
                  opacity: appPill.active ? 1 : 0.85
                  font.family: Style.font.family
                  font.pixelSize: 12
                }

                HoverHandler { id: hover }
                TapHandler {
                  onTapped: if (appPill.tl)
                    Quickshell.execDetached(["hyprctl", "dispatch", "focuswindow", "address:" + appPill.tl.address])
                }
              }
            }
          }
        }
      }
    }
  }
}
