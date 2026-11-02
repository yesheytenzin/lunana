pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell.Widgets
import "../../../../services"
import "../../../common/functions"
import "../../../common/widgets"
import "../../style"
import "../../frame"
import "../../components"
import "../parts"

// The material is what every surface is made of: the Island, a card and a side panel at once, each glass or solid the way
// the real surface resolves it (AtollStyle.surfaceGlass, so a per-surface override shows here too).
PreviewScene {
    id: mat
    // Laid tight, so the bodies read at the head's size.
    readonly property real naturalWidth: Math.round(460 * mat.d)
    readonly property real naturalHeight: Math.round(230 * mat.d)
    // Re-reads when a per-surface row changes.
    readonly property string cardsMaterial: String(mat.opt("atoll.appearance.surfaces.cards.material", ""))
    readonly property string panelsMaterial: String(mat.opt("atoll.appearance.surfaces.panels.material", ""))

    // One body: frost over the wallpaper (the host's decoded texture) or the solid paper, as its surface resolves, and the
    // shadow a floating body really casts (Shadows moves it).
    component Body: Item {
        id: body
        required property PreviewScene scene
        required property string surface
        property string override: ""
        property int fallbackRadius: AtollStyle.radiusSheet
        default property alias content: host.data
        readonly property string resolved: { body.override; return AtollStyle.surfaceGlass(body.surface) }
        readonly property bool glass: body.resolved === "solid" ? false : body.resolved === "inherit" ? AtollStyle.glassy : true
        readonly property real radius: AtollStyle.surfaceRadius(body.surface, body.fallbackRadius)
        RectangularShadow {
            anchors.fill: plate
            radius: plate.radius
            offset.y: Math.round(3 * body.scene.d)
            blur: Math.round(16 * body.scene.d)
            color: AtollStyle.shadow
        }
        ClippingRectangle {
            id: plate
            anchors.fill: parent
            radius: body.radius
            color: body.glass ? "transparent" : AtollStyle.bodySurface
            border.width: !body.glass && AtollStyle.rim.a > 0 ? 1 : 0
            border.color: AtollStyle.rim
            ShaderEffectSource {
                id: frostSource
                x: -body.x; y: -body.y
                width: body.scene.width; height: body.scene.height
                visible: false
                sourceItem: body.glass ? body.scene.wallpaperView.textureItem : null
                live: true
            }
            MultiEffect {
                anchors.fill: frostSource
                visible: body.glass
                source: frostSource
                blurEnabled: true
                blur: AtollStyle.glassBlurAmount
                blurMax: AtollStyle.glassBlurMax
                saturation: AtollStyle.glassSaturation
            }
            Rectangle { anchors.fill: parent; visible: body.glass; color: ColorUtils.applyAlpha(AtollStyle.surfaceOpaque, AtollStyle.glassTint) }
            Item { id: host; anchors.fill: parent }
            AtollGlassEdge { anchors.fill: parent; visible: (body.glass || AtollStyle.edgeLit) && shown; radius: plate.radius }
        }
    }

    IslandPill {
        id: matIsland
        anchors.horizontalCenter: parent.horizontalCenter
        y: AtollFrame.band
    }

    Body {
        id: matCard
        scene: mat
        surface: "cards"
        override: mat.cardsMaterial
        fallbackRadius: AtollStyle.radiusPlate
        x: Math.round(24 * mat.d)
        y: matIsland.y + matIsland.height + Math.round(16 * mat.d)
        width: Math.round(216 * mat.d)
        height: cardColumn.implicitHeight + 2 * cardColumn.pad
        ColumnLayout {
            id: cardColumn
            readonly property int pad: AtollStyle.concentricPad(matCard.radius, 14 * mat.d)
            x: cardColumn.pad; y: cardColumn.pad
            width: parent.width - 2 * cardColumn.pad
            spacing: Math.round(10 * mat.d)
            RowLayout {
                spacing: Math.round(10 * mat.d)
                Rectangle {
                    implicitWidth: Math.round(36 * mat.d); implicitHeight: implicitWidth
                    radius: AtollStyle.iconRadius(width); color: AtollStyle.fill
                    MaterialSymbol { anchors.centerIn: parent; text: "music_note"; fill: 1; iconSize: Math.round(18 * mat.d); color: AtollStyle.textSecondary }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    AtollText { Layout.fillWidth: true; elide: Text.ElideRight; text: Translation.tr("Now playing"); font.weight: AtollStyle.weight(Font.DemiBold); font.pixelSize: AtollStyle.typeLabel }
                    AtollText { Layout.fillWidth: true; elide: Text.ElideRight; text: Translation.tr("Artist"); color: AtollStyle.muted; font.pixelSize: AtollStyle.typeMeta }
                }
            }
            Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: AtollStyle.hairline }
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: Math.max(2, Math.round(4 * mat.d))
                radius: height / 2
                color: AtollStyle.fill
                Rectangle { width: parent.width * 0.42; height: parent.height; radius: parent.radius; color: AtollStyle.accent }
            }
            AtollControlPlate {
                id: matControls
                Layout.alignment: Qt.AlignHCenter
                controlHeight: Math.round(30 * mat.d)
                Row {
                    spacing: matControls.framed ? Math.round(4 * mat.d) : Math.round(18 * mat.d)
                    Repeater {
                        model: ["skip_previous", "pause", "skip_next"]
                        Item {
                            required property string modelData
                            width: Math.round(30 * mat.d); height: width
                            MaterialSymbol { anchors.centerIn: parent; text: parent.modelData; fill: 1; iconSize: Math.round(20 * mat.d); color: AtollStyle.text }
                        }
                    }
                }
            }
        }
    }

    Body {
        id: matPanel
        scene: mat
        surface: "panels"
        override: mat.panelsMaterial
        fallbackRadius: AtollStyle.radiusPanel
        anchors.right: parent.right
        anchors.rightMargin: AtollFrame.band + AtollFrame.bodyAir + Math.round(12 * mat.d)
        // Level with the card: in a miniature the Island would otherwise reach over the panel's shoulder.
        y: matCard.y
        width: Math.round(140 * mat.d)
        height: parent.height - y - AtollFrame.band - AtollFrame.bodyAir
        ColumnLayout {
            readonly property int pad: AtollStyle.concentricPad(matPanel.radius, 12 * mat.d)
            x: pad; y: pad
            width: parent.width - 2 * pad
            height: parent.height - 2 * pad
            spacing: Math.round(8 * mat.d)
            Repeater {
                model: [["calendar_month", Translation.tr("Calendar"), AtollStyle.identity.red], ["partly_cloudy_day", Translation.tr("Weather"), AtollStyle.identity.sky], ["timer", Translation.tr("Timer"), AtollStyle.identity.orange]]
                Rectangle {
                    id: panelRow
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: AtollStyle.radiusCard
                    color: AtollStyle.fillQuiet
                    Rectangle {
                        id: panelMark
                        x: Math.round(8 * mat.d)
                        anchors.verticalCenter: parent.verticalCenter
                        width: Math.round(22 * mat.d); height: width
                        radius: AtollStyle.iconRadius(width); color: panelRow.modelData[2]
                        MaterialSymbol { anchors.centerIn: parent; text: panelRow.modelData[0]; fill: 1; iconSize: Math.round(13 * mat.d); color: AtollStyle.onTint }
                    }
                    AtollText {
                        anchors.left: panelMark.right; anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin: Math.round(8 * mat.d); anchors.rightMargin: Math.round(6 * mat.d)
                        elide: Text.ElideRight
                        text: panelRow.modelData[1]
                        font.weight: AtollStyle.weight(Font.DemiBold)
                        font.pixelSize: AtollStyle.typeMeta
                    }
                }
            }
        }
    }

    Caption {
        glyph: "layers"
        text: Translation.tr("%1 on every surface").arg(Translation.tr(AtollStyle.materialLabel(AtollStyle.materialName)))
    }
}
