pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell.Widgets
import "../../../../services"
import "../../../common/widgets"
import "../../style"
import "../../components"
import "../parts"

PreviewScene {
    id: playerRoot
    readonly property var player: MprisController.activePlayer
    readonly property string art: String(MprisController.artUrlOf(playerRoot.player) ?? "")
    readonly property string cover: playerRoot.art.length > 0 ? playerRoot.art : playerRoot.wallpaper
    readonly property bool roundCover: playerRoot.opt("atoll.player.roundCover", false)
    readonly property bool artBackground: playerRoot.opt("atoll.player.artworkBackground", true)
    readonly property bool opensIsland: String(playerRoot.opt("atoll.player.bubbleOpens", "card")) === "island"
    readonly property bool pinned: playerRoot.opt("atoll.player.cardPinned", false)
    readonly property real naturalWidth: Math.round(560 * playerRoot.d)
    readonly property real naturalHeight: Math.round(290 * playerRoot.d)
    ClippingRectangle {
        id: playerCard
        anchors.centerIn: parent
        width: Math.round(380 * playerRoot.d)
        height: Math.round(210 * playerRoot.d)
        radius: playerRoot.opensIsland ? AtollStyle.radius : AtollStyle.radiusSheet
        color: AtollStyle.bodySurface
        border.width: AtollStyle.rim.a > 0 ? 1 : 0
        border.color: AtollStyle.rim
        // A ClippingRectangle's children sit in its content item, which has no radius: name the card.
        AtollGlassEdge { anchors.fill: parent; z: 10; visible: AtollStyle.edgeLit && shown; radius: playerCard.radius }
        Image {
            id: artSource
            anchors.fill: parent
            anchors.margins: -40
            source: playerRoot.cover
            fillMode: Image.PreserveAspectCrop
            sourceSize.width: 240
            visible: false
        }
        MultiEffect {
            anchors.fill: artSource
            source: artSource
            visible: playerRoot.artBackground
            blurEnabled: true; blur: 1; blurMax: 48
            brightness: -0.25
        }
        Rectangle { anchors.fill: parent; visible: playerRoot.artBackground; color: AtollStyle.mediaScrim }
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Math.round(18 * playerRoot.d)
            spacing: Math.round(10 * playerRoot.d)
            RowLayout {
                spacing: Math.round(14 * playerRoot.d)
                ClippingRectangle {
                    implicitWidth: Math.round(84 * playerRoot.d); implicitHeight: implicitWidth
                    radius: playerRoot.roundCover ? width / 2 : AtollStyle.radiusTile
                    Behavior on radius { NumberAnimation { duration: AtollStyle.morphDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: AtollStyle.morphCurve } }
                    AtollImage { anchors.fill: parent; source: playerRoot.cover }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Math.round(2 * playerRoot.d)
                    AtollText { Layout.fillWidth: true; text: MprisController.titleOf(playerRoot.player) || Translation.tr("Song title"); color: playerRoot.artBackground ? AtollStyle.onMedia : AtollStyle.text; font.weight: AtollStyle.weight(Font.DemiBold); font.pixelSize: AtollStyle.typeHeadline; elide: Text.ElideRight }
                    AtollText { Layout.fillWidth: true; text: MprisController.artistOf(playerRoot.player) || Translation.tr("Artist"); color: playerRoot.artBackground ? AtollStyle.onMediaSecondary : AtollStyle.subtext; elide: Text.ElideRight }
                }
                MaterialSymbol { visible: playerRoot.pinned; Layout.alignment: Qt.AlignTop; text: "keep"; fill: 1; iconSize: Math.round(18 * playerRoot.d); color: playerRoot.artBackground ? AtollStyle.onMedia : AtollStyle.accent }
            }
            Item { Layout.fillHeight: true }
            Level { value: 0.38; tint: playerRoot.artBackground ? AtollStyle.onMedia : AtollStyle.text; color: playerRoot.artBackground ? AtollStyle.onMediaFill : AtollStyle.fill }
            AtollControlPlate {
                id: previewTransport
                Layout.alignment: Qt.AlignHCenter
                controlHeight: Math.round(32 * playerRoot.d)
                Row {
                    spacing: previewTransport.framed ? Math.round(4 * playerRoot.d) : Math.round(26 * playerRoot.d)
                    Repeater {
                        model: ["skip_previous", "pause", "skip_next"]
                        Item {
                            required property string modelData
                            width: Math.round(32 * playerRoot.d); height: width
                            MaterialSymbol { anchors.centerIn: parent; text: parent.modelData; fill: 1; iconSize: Math.round(24 * playerRoot.d); color: playerRoot.artBackground ? AtollStyle.onMedia : AtollStyle.text }
                        }
                    }
                }
            }
        }
    }
    Caption {
        glyph: playerRoot.opensIsland ? "pill" : "web_asset"
        text: (playerRoot.opensIsland ? Translation.tr("The media bubble opens the Island") : Translation.tr("The media bubble opens a card"))
            + (playerRoot.pinned ? " · " + Translation.tr("kept open") : "")
    }
}
