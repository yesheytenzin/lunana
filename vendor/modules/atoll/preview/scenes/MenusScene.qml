pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import "../../../../services"
import "../../../common/functions"
import "../../../common/widgets"
import "../../style"
import "../../components"
import "../parts"

PreviewScene {
    id: menuRoot
    readonly property real naturalWidth: Math.round(480 * menuRoot.d)
    readonly property real naturalHeight: Math.round(300 * menuRoot.d)
    // The real menu's numbers (AtollDesktopMenu): Menus › Size moves every one of them.
    readonly property bool compact: AtollStyle.menuCompact
    readonly property int pad: Math.round((menuRoot.compact ? 4 : 6) * menuRoot.d)
    readonly property real rowHeight: Math.round((menuRoot.compact ? 28 : 34) * menuRoot.d)
    readonly property real sepHeight: Math.round((menuRoot.compact ? 9 : 13) * menuRoot.d)
    readonly property real markSize: Math.round((menuRoot.compact ? 18 : 20) * menuRoot.d)
    readonly property real glyphSize: Math.round((menuRoot.compact ? 15 : 17) * menuRoot.d)
    readonly property int textSize: menuRoot.compact ? AtollStyle.typeLabel : AtollStyle.typeBody
    Plate {
        id: menuPlate
        surface: "menus"
        // AtollDesktopMenu's own fallback: tile corners when compact, card corners when regular.
        fallbackRadius: menuRoot.compact ? AtollStyle.radiusTile : AtollStyle.radiusCard
        anchors.centerIn: parent
        width: Math.round(224 * menuRoot.d)
        height: menuColumn.implicitHeight + 2 * menuRoot.pad
        ColumnLayout {
            id: menuColumn
            x: menuRoot.pad; y: menuRoot.pad
            width: parent.width - 2 * x
            spacing: 0
            ClippingRectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: Math.round(width * 0.48)
                radius: Math.max(AtollStyle.radiusMicro, menuPlate.radius - menuRoot.pad)
                color: AtollStyle.fillQuiet
                ShaderEffectSource {
                    anchors.fill: parent
                    sourceItem: menuRoot.wallpaperView
                    sourceRect: {
                        const w = menuRoot.wallpaperView.width, h = Math.min(menuRoot.wallpaperView.height, w * 9 / 16)
                        return Qt.rect(0, (menuRoot.wallpaperView.height - h) / 2, w, h)
                    }
                }
                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: Math.round(parent.height * 0.55)
                    gradient: Gradient {
                        GradientStop { position: 0; color: ColorUtils.applyAlpha(AtollStyle.mediaScrim, 0) }
                        GradientStop { position: 1; color: AtollStyle.veilStrong }
                    }
                }
                RowLayout {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.margins: Math.round(10 * menuRoot.d)
                    AtollText { Layout.fillWidth: true; text: Translation.tr("Wallpaper"); color: AtollStyle.onMedia; font.pixelSize: AtollStyle.typeLabel; font.weight: AtollStyle.weight(Font.DemiBold) }
                    MaterialSymbol { text: "chevron_right"; iconSize: Math.round(16 * menuRoot.d); color: AtollStyle.onMedia }
                }
            }
            Repeater {
                model: [
                    { sep: true },
                    { glyph: "widgets", text: Translation.tr("Edit widgets"), tint: "teal", lit: true },
                    { glyph: "palette", text: Translation.tr("Customize Atoll"), tint: "purple" },
                    { sep: true },
                    { glyph: "settings", text: Translation.tr("Settings"), tint: "gray" },
                    { glyph: "restart_alt", text: Translation.tr("Restart shell"), tint: "gray" }
                ]
                Item {
                    id: menuRow
                    required property var modelData
                    readonly property color tint: AtollStyle.identityColor(String(menuRow.modelData.tint ?? "gray"))
                    Layout.fillWidth: true
                    implicitHeight: menuRow.modelData.sep ? menuRoot.sepHeight : menuRoot.rowHeight
                    Rectangle {
                        visible: menuRow.modelData.sep === true
                        anchors.verticalCenter: parent.verticalCenter
                        x: Math.round(8 * menuRoot.d); width: parent.width - 2 * x; height: 1
                        color: AtollStyle.hairline
                    }
                    Rectangle {
                        visible: menuRow.modelData.sep !== true
                        anchors.fill: parent
                        radius: AtollStyle.radiusRow
                        color: menuRow.modelData.lit ? AtollStyle.fillHover : "transparent"
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Math.round((menuRoot.compact ? 8 : 10) * menuRoot.d)
                            anchors.rightMargin: Math.round((menuRoot.compact ? 10 : 12) * menuRoot.d)
                            spacing: Math.round((menuRoot.compact ? 8 : 10) * menuRoot.d)
                            Rectangle {
                                Layout.preferredWidth: menuRoot.markSize
                                Layout.preferredHeight: Layout.preferredWidth
                                radius: AtollStyle.iconRadius(width)
                                gradient: Gradient {
                                    GradientStop { position: 0; color: AtollStyle.tileTop(menuRow.tint) }
                                    GradientStop { position: 1; color: menuRow.tint }
                                }
                                MaterialSymbol { anchors.centerIn: parent; text: String(menuRow.modelData.glyph ?? ""); fill: 1; iconSize: Math.round(menuRoot.glyphSize * 0.82); color: AtollStyle.onTint }
                            }
                            AtollText { Layout.fillWidth: true; text: String(menuRow.modelData.text ?? ""); font.pixelSize: menuRoot.textSize; font.weight: AtollStyle.weight(Font.Medium) }
                        }
                    }
                }
            }
        }
    }
    Caption {
        glyph: "menu_open"
        text: menuRoot.compact ? Translation.tr("Compact menus") : Translation.tr("Regular menus")
    }
}
