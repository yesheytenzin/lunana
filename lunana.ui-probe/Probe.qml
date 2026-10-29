import QtQuick
import Quickshell
import Quickshell.Wayland
import "vendor/modules/common" as LnCommon
import "vendor/modules/common/widgets" as LnWidgets

// Wave-0 foundation probe (kind: service, dev-only).
//
// Renders one vendored inir PanelSurface inside Omarchy's shell process. If this
// maps and paints, the whole foundation works: inir's token system (Appearance),
// the Config/ThemePresets/MaterialThemeLoader shims, and the widget library all
// load under relative-path imports in Omarchy's `qs`-claimed engine.
Item {
    id: root
    property var shell: null
    property var manifest: null

    Variants {
        model: Quickshell.screens
        delegate: Component {
            PanelWindow {
                required property var modelData
                screen: modelData
                color: "transparent"
                WlrLayershell.namespace: "lunana-ui-probe"
                WlrLayershell.layer: WlrLayer.Overlay
                anchors { top: true; right: true }
                margins { top: 90; right: 40 }
                implicitWidth: 440
                implicitHeight: 190

                LnWidgets.PanelSurface {
                    anchors.fill: parent
                    anchors.margins: 14
                    elevation: 2

                    Column {
                        anchors.centerIn: parent
                        spacing: 6
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            horizontalAlignment: Text.AlignHCenter
                            text: "lunana × inir\nvendored PanelSurface\nstyle: " + LnCommon.Appearance.globalStyle
                            color: LnCommon.Appearance.m3colors.m3onSurface
                            font.pixelSize: 16
                            font.bold: true
                        }
                        // Wave-A seam proof: these must equal Omarchy's live palette.
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            horizontalAlignment: Text.AlignHCenter
                            text: "primary " + LnCommon.Appearance.m3colors.m3primary
                                + "  bg " + LnCommon.Appearance.m3colors.m3background
                                + "  dark:" + LnCommon.Appearance.m3colors.darkmode
                            color: LnCommon.Appearance.m3colors.m3primary
                            font.pixelSize: 12
                            font.family: "monospace"
                        }
                    }
                }
            }
        }
    }
}
