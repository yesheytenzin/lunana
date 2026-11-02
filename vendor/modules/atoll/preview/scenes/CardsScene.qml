pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../../../../services"
import "../../../common/widgets"
import "../../style"
import "../../frame"
import "../../components"
import "../../pieces"
import "../parts"

PreviewScene {
    id: cardRoot
    readonly property real cardWidth: Number(cardRoot.opt("atoll.appearance.surfaces.cards.width", 0)) > 0
        ? Number(cardRoot.opt("atoll.appearance.surfaces.cards.width", 0)) * cardRoot.d : Math.round(340 * cardRoot.d)
    readonly property bool header: cardRoot.opt("atoll.appearance.surfaces.cards.header", true)
    readonly property bool devices: cardRoot.opt("atoll.appearance.surfaces.cards.devices", true)
    readonly property bool mixer: cardRoot.opt("atoll.appearance.surfaces.cards.mixer", true)
    readonly property real naturalWidth: cardRoot.cardWidth + Math.round(120 * cardRoot.d)
    readonly property real naturalHeight: cardPlate.y + cardPlate.height + Math.round(24 * cardRoot.d)
    Rectangle {
        id: origin
        anchors.horizontalCenter: parent.horizontalCenter
        y: AtollFrame.band
        width: AtollFrame.islandBand; height: width
        radius: AtollStyle.pieceRadius(width)
        color: AtollStyle.bodySurface
        MaterialSymbol { anchors.centerIn: parent; text: "volume_up"; fill: 1; iconSize: Math.round(18 * cardRoot.d); color: AtollStyle.text }
    }
    Plate {
        id: cardPlate
        surface: "cards"
        own: AtollStyle.identity.sky
        anchors.horizontalCenter: parent.horizontalCenter
        y: origin.y + origin.height + AtollStyle.weld
        width: cardRoot.cardWidth
        height: cardColumn.implicitHeight + Math.round(32 * cardRoot.d)
        ColumnLayout {
            id: cardColumn
            x: Math.round(16 * cardRoot.d); y: Math.round(16 * cardRoot.d)
            width: parent.width - 2 * x
            spacing: Math.round(12 * cardRoot.d)
            RowLayout {
                visible: cardRoot.header
                spacing: Math.round(10 * cardRoot.d)
                Rectangle {
                    implicitWidth: Math.round(30 * cardRoot.d); implicitHeight: implicitWidth
                    radius: AtollStyle.iconRadius(width); color: AtollStyle.identity.sky
                    MaterialSymbol { anchors.centerIn: parent; text: "volume_up"; fill: 1; iconSize: Math.round(16 * cardRoot.d); color: AtollStyle.onTint }
                }
                ColumnLayout {
                    spacing: 0
                    AtollText { text: Translation.tr("Sound"); font.weight: AtollStyle.weight(Font.DemiBold) }
                    AtollText { text: Audio.sink?.description ?? Translation.tr("Speakers"); color: AtollStyle.subtext; font.pixelSize: AtollStyle.typeMeta }
                }
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: Math.round(10 * cardRoot.d)
                MaterialSymbol { text: "volume_up"; iconSize: Math.round(18 * cardRoot.d); color: AtollStyle.text }
                Level { value: Math.min(1, Audio.value ?? 0.6); tint: AtollStyle.text }
                AtollText { text: Math.round(Math.min(1, Audio.value ?? 0.6) * 100); font.family: AtollStyle.fontNumbers; font.weight: AtollStyle.weight(Font.DemiBold) }
            }
            Row {
                visible: cardRoot.devices
                spacing: Math.round(6 * cardRoot.d)
                Repeater {
                    model: [Translation.tr("Speakers"), Translation.tr("Headphones")]
                    Rectangle {
                        required property string modelData
                        required property int index
                        width: devLabel.implicitWidth + Math.round(20 * cardRoot.d); height: Math.round(26 * cardRoot.d)
                        radius: height / 2
                        color: index === 0 ? AtollStyle.tintFill(AtollStyle.accent) : AtollStyle.fillQuiet
                        AtollText { id: devLabel; anchors.centerIn: parent; text: parent.modelData; color: parent.index === 0 ? AtollStyle.accent : AtollStyle.subtext; font.pixelSize: AtollStyle.typeMeta }
                    }
                }
            }
            Repeater {
                model: cardRoot.mixer ? (TaskbarApps.apps ?? []).filter(app => app && !app.separator && String(app.appId ?? "").length > 0 && app.appId !== "SEPARATOR").slice(0, 2) : []
                RowLayout {
                    required property var modelData
                    required property int index
                    Layout.fillWidth: true
                    spacing: Math.round(10 * cardRoot.d)
                    SmartAppIcon { implicitSize: Math.round(20 * cardRoot.d); icon: AtollPieces.appIcon(parent.modelData.appId); fallback: "application-x-executable" }
                    Level { value: parent.index === 0 ? 0.8 : 0.45 }
                }
            }
        }
    }
}
