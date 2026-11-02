pragma ComponentBehavior: Bound

import QtQuick
import "../../common/widgets"
import "../style"

AtollButton {
    id: chip
    property string glyph: ""
    property string label: ""
    property int order: -1
    property string artwork: ""
    readonly property real d: AtollStyle.density
    readonly property real inset: Math.round(12 * chip.d)
    property real labelCap: Math.round(200 * chip.d)
    property string labelFamily: ""

    implicitHeight: Math.max(Math.round(30 * chip.d), Math.round(chipLabel.implicitHeight + 10 * chip.d))
    implicitWidth: chipLabel.lead + Math.min(chipLabel.implicitWidth, chip.labelCap) + chip.inset * 2
    buttonRadius: AtollStyle.controlPlated ? AtollStyle.pieceRadius(height) : height / 2
    buttonRadiusPressed: buttonRadius
    Accessible.name: chip.label

    Row {
        id: chipRow
        anchors.centerIn: parent
        spacing: Math.round(5 * chip.d)
        AtollText {
            id: chipOrder
            visible: chip.order >= 0
            anchors.verticalCenter: parent.verticalCenter
            text: chip.order + 1
            color: chip.foreground
            font.family: AtollStyle.fontNumbers
            font.pixelSize: AtollStyle.typeLabel
            font.weight: AtollStyle.weight(Font.Bold)
            font.features: { "tnum": 1 }
        }
        AtollArtwork {
            id: chipArt
            visible: chip.artwork.length > 0
            anchors.verticalCenter: parent.verticalCenter
            width: Math.round(20 * chip.d)
            height: width
            radius: AtollStyle.iconRadius(width)
            source: chip.artwork
            decodeSize: width * 2
        }
        MaterialSymbol {
            id: chipGlyph
            visible: chip.glyph.length > 0
            anchors.verticalCenter: parent.verticalCenter
            text: chip.glyph
            fill: 1
            iconSize: 16 * chip.d
            color: chip.foreground
        }
        AtollText {
            id: chipLabel
            anchors.verticalCenter: parent.verticalCenter
            readonly property real lead: (chipOrder.visible ? chipOrder.implicitWidth + chipRow.spacing : 0)
                + (chipArt.visible ? chipArt.width + chipRow.spacing : 0)
                + (chipGlyph.visible ? chipGlyph.implicitWidth + chipRow.spacing : 0)
            width: Math.max(0, Math.min(implicitWidth, chip.labelCap, chip.width - chip.inset * 2 - lead))
            elide: Text.ElideRight
            text: chip.label
            color: chip.foreground
            font.family: chip.labelFamily.length > 0 ? chip.labelFamily : AtollStyle.fontMain
            font.pixelSize: AtollStyle.typeLabel
            font.weight: chip.selected || chip.emphasized ? AtollStyle.weight(Font.DemiBold) : AtollStyle.weight(Font.Medium)
        }
    }
}
