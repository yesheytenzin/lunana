pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../../../../services"
import "../../../common/widgets"
import "../../style"
import "../../frame"
import "../../components"
import "../parts"

PreviewScene {
    id: lightRoot
    readonly property real naturalWidth: Math.round(620 * lightRoot.d)
    readonly property real naturalHeight: Math.round(290 * lightRoot.d)
    readonly property string aura: String(lightRoot.opt("atoll.appearance.aura", "subtle"))
    readonly property real reach: Number(lightRoot.opt("atoll.appearance.theme.lightReach", 100))
    readonly property real glow: Number(lightRoot.opt("atoll.appearance.theme.glow", 0))
    readonly property real bodyWidth: Math.round(236 * lightRoot.d)
    readonly property real bodyHeight: Math.round(176 * lightRoot.d)
    readonly property real gutter: Math.round((lightRoot.width - 2 * lightRoot.bodyWidth) / 3)
    property real t: 0
    Loop on t { running: lightRoot.playing }
    readonly property real grown: AtollFrame.islandBand + (lightRoot.bodyHeight - AtollFrame.islandBand) * lightRoot.t
    readonly property real wide: AtollFrame.islandBand * 2 + (lightRoot.bodyWidth - AtollFrame.islandBand * 2) * lightRoot.t

    LitBody {
        x: lightRoot.gutter + (lightRoot.bodyWidth - width) / 2
        y: Math.round(26 * lightRoot.d)
        width: lightRoot.wide
        height: lightRoot.grown
        restWidth: lightRoot.bodyWidth
        restHeight: lightRoot.bodyHeight
        progress: lightRoot.t
        light: AtollStyle.identity.sky
        ColumnLayout {
            anchors.fill: parent
            spacing: Math.round(2 * lightRoot.d)
            RowLayout {
                spacing: Math.round(6 * lightRoot.d)
                MaterialSymbol { text: "partly_cloudy_day"; fill: 1; iconSize: Math.round(18 * lightRoot.d); color: AtollStyle.identity.sky }
                AtollText { text: Translation.tr("Weather"); font.weight: AtollStyle.weight(Font.DemiBold) }
            }
            AtollText {
                text: "18°"
                font.family: AtollStyle.fontNumbers
                font.weight: AtollStyle.figureWeight
                font.pixelSize: 40 * AtollStyle.typeScale
            }
            AtollText { text: Translation.tr("Partly cloudy"); color: AtollStyle.muted; font.pixelSize: AtollStyle.typeMeta }
            Item { Layout.fillHeight: true }
        }
    }
    LitBody {
        x: 2 * lightRoot.gutter + lightRoot.bodyWidth + (lightRoot.bodyWidth - width) / 2
        y: Math.round(26 * lightRoot.d)
        width: lightRoot.wide
        height: lightRoot.grown
        restWidth: lightRoot.bodyWidth
        restHeight: lightRoot.bodyHeight
        progress: lightRoot.t
        light: AtollStyle.wallpaperLight
        ColumnLayout {
            anchors.fill: parent
            spacing: Math.round(10 * lightRoot.d)
            RowLayout {
                spacing: Math.round(6 * lightRoot.d)
                MaterialSymbol { text: "tune"; iconSize: Math.round(18 * lightRoot.d); color: AtollStyle.text }
                AtollText { text: Translation.tr("Control Center"); font.weight: AtollStyle.weight(Font.DemiBold) }
            }
            RowLayout {
                spacing: Math.round(8 * lightRoot.d)
                Repeater {
                    model: ["wifi", "bluetooth", "dark_mode"]
                    Rectangle {
                        required property string modelData
                        required property int index
                        implicitWidth: Math.round(38 * lightRoot.d)
                        implicitHeight: implicitWidth
                        radius: AtollStyle.pieceRadius(implicitWidth)
                        color: index === 0 ? AtollStyle.accent : AtollStyle.fill
                        MaterialSymbol { anchors.centerIn: parent; text: parent.modelData; fill: 1; iconSize: Math.round(18 * lightRoot.d); color: parent.index === 0 ? AtollStyle.inkOnAccent : AtollStyle.text }
                    }
                }
            }
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: Math.round(26 * lightRoot.d)
                radius: height / 2
                color: AtollStyle.fill
                Rectangle { width: parent.width * 0.62; height: parent.height; radius: height / 2; color: AtollStyle.fillActive }
            }
            Item { Layout.fillHeight: true }
        }
    }
    Caption {
        glyph: lightRoot.aura === "off" ? "light_off" : "light_mode"
        text: (lightRoot.aura === "off" ? Translation.tr("Light off")
            : (lightRoot.aura === "vivid" ? Translation.tr("Vivid") : Translation.tr("Subtle")) + " · " + Translation.tr("reach %1%").arg(Math.round(lightRoot.reach)))
            + " · " + (lightRoot.glow > 0 ? Translation.tr("shadows glow %1%").arg(Math.round(lightRoot.glow)) : Translation.tr("dark shadows"))
    }
}
