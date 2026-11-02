pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../../../../services"
import "../../../common/widgets"
import "../../style"
import "../../frame"
import "../../components"
import "../parts"

// Colour, end to end: the shell's paper, ink, identities, accent and highlight on the left, and on the right a window
// painted with the roles the solver hands the apps, so a choice shows in both at once.
PreviewScene {
    id: pal
    readonly property real naturalWidth: Math.round(620 * pal.d)
    readonly property real naturalHeight: Math.round(300 * pal.d)
    readonly property var apps: { pal.rev; return AtollStyle.washi?.apps ?? ({}) }
    readonly property bool appsFollow: { pal.rev; return Boolean(pal.opt("appearance.wallpaperTheming.enableAppsAndShell", true)) }
    function app(key: string, fallback: color): color {
        const hex = pal.apps[key]
        return hex ? Qt.color(String(hex)) : fallback
    }
    IslandPill {
        id: palIsland
        anchors.horizontalCenter: palPlate.horizontalCenter
        y: AtollFrame.band
    }
    Plate {
        id: palPlate
        surface: "controlCenter"
        fallbackRadius: AtollStyle.radiusPlate
        x: Math.round(24 * pal.d)
        y: palIsland.y + palIsland.height + AtollFrame.bodyAir
        width: Math.round(300 * pal.d)
        height: palColumn.implicitHeight + Math.round(28 * pal.d)
        ColumnLayout {
            id: palColumn
            x: Math.round(14 * pal.d); y: Math.round(14 * pal.d)
            width: parent.width - 2 * x
            spacing: Math.round(8 * pal.d)
            AtollText { text: Translation.tr("Your shell"); font.weight: AtollStyle.weight(Font.DemiBold); font.pixelSize: AtollStyle.typeBody }
            AtollText { Layout.fillWidth: true; text: Translation.tr("Ink on its paper, colours that keep their meaning"); color: AtollStyle.subtext; elide: Text.ElideRight; font.pixelSize: AtollStyle.typeMeta }
            Row {
                spacing: Math.round(8 * pal.d)
                Repeater {
                    model: [["blue", "wifi"], ["green", "battery_full"], ["orange", "light_mode"], ["pink", "volume_up"], ["purple", "dark_mode"], ["teal", "bluetooth"]]
                    Rectangle {
                        id: palTile
                        required property var modelData
                        readonly property color tint: AtollStyle.identityColor(modelData[0])
                        width: Math.round(28 * pal.d); height: width
                        radius: AtollStyle.iconRadius(width)
                        // A Gradient is not an Item: its stops have no `parent` to read the tile from.
                        gradient: Gradient {
                            GradientStop { position: 0; color: AtollStyle.tileTop(palTile.tint) }
                            GradientStop { position: 1; color: palTile.tint }
                        }
                        MaterialSymbol { anchors.centerIn: parent; text: palTile.modelData[1]; fill: 1; iconSize: Math.round(16 * pal.d); color: AtollStyle.onTint }
                    }
                }
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: Math.round(10 * pal.d)
                AtollSwitch { on: true; enabled: false }
                Rectangle {
                    implicitWidth: palButton.implicitWidth + Math.round(24 * pal.d)
                    implicitHeight: Math.round(28 * pal.d)
                    radius: height / 2
                    color: AtollStyle.accent
                    AtollText { id: palButton; anchors.centerIn: parent; text: Translation.tr("Accent"); color: AtollStyle.inkOnAccent; font.weight: AtollStyle.weight(Font.DemiBold); font.pixelSize: AtollStyle.typeMeta }
                }
                Item { Layout.fillWidth: true }
                AtollText { text: "42"; color: AtollStyle.secondaryAccent; font.family: AtollStyle.fontNumbers; font.weight: AtollStyle.weight(Font.DemiBold); font.pixelSize: AtollStyle.typeHeadline }
            }
        }
    }
    MaterialSymbol {
        anchors.verticalCenter: palPlate.verticalCenter
        x: palPlate.x + palPlate.width + Math.round(10 * pal.d)
        text: pal.appsFollow ? "arrow_forward" : "link_off"
        iconSize: Math.round(20 * pal.d)
        color: AtollStyle.onMedia
    }
    // An app window in the roles the apps wear: title bar, a selected row, text and its primary button.
    Rectangle {
        id: palApp
        x: palPlate.x + palPlate.width + Math.round(40 * pal.d)
        anchors.verticalCenter: palPlate.verticalCenter
        width: Math.round(230 * pal.d)
        height: Math.round(160 * pal.d)
        radius: AtollStyle.radiusTile
        color: pal.app("surface", AtollStyle.surfaceOpaque)
        border.width: 1
        border.color: pal.app("outlineVariant", AtollStyle.border)
        opacity: pal.appsFollow ? 1 : 0.45
        clip: true
        Rectangle {
            width: parent.width
            height: Math.round(26 * pal.d)
            color: pal.app("surfaceContainer", AtollStyle.surfaceHighOpaque)
            Row {
                anchors.verticalCenter: parent.verticalCenter
                x: Math.round(10 * pal.d)
                spacing: Math.round(6 * pal.d)
                Repeater {
                    model: 3
                    Rectangle { width: Math.round(8 * pal.d); height: width; radius: width / 2; color: pal.app("outline", AtollStyle.muted) }
                }
            }
        }
        Column {
            x: Math.round(12 * pal.d)
            y: Math.round(36 * pal.d)
            width: parent.width - 2 * x
            spacing: Math.round(6 * pal.d)
            AtollText { text: Translation.tr("An app"); color: pal.app("onSurface", AtollStyle.text); font.weight: AtollStyle.weight(Font.DemiBold); font.pixelSize: AtollStyle.typeBody }
            Rectangle {
                width: parent.width
                height: Math.round(24 * pal.d)
                radius: AtollStyle.radiusRow
                color: pal.app("primaryContainer", AtollStyle.accentContainer)
                AtollText { anchors.verticalCenter: parent.verticalCenter; x: Math.round(8 * pal.d); text: Translation.tr("Selected"); color: pal.app("onPrimaryContainer", AtollStyle.text); font.pixelSize: AtollStyle.typeMeta }
            }
            AtollText { width: parent.width; text: Translation.tr("Its text and its quieter lines"); color: pal.app("onSurfaceVariant", AtollStyle.subtext); elide: Text.ElideRight; font.pixelSize: AtollStyle.typeMeta }
            Rectangle {
                width: palAppButton.implicitWidth + Math.round(22 * pal.d)
                height: Math.round(26 * pal.d)
                radius: height / 2
                color: pal.app("primary", AtollStyle.accent)
                AtollText { id: palAppButton; anchors.centerIn: parent; text: Translation.tr("OK"); color: pal.app("onPrimary", AtollStyle.inkOnAccent); font.weight: AtollStyle.weight(Font.DemiBold); font.pixelSize: AtollStyle.typeMeta }
            }
        }
    }
    Caption {
        glyph: "palette"
        text: pal.appsFollow ? Translation.tr("The shell and your apps, one palette") : Translation.tr("Your apps keep their own colours")
    }
}
