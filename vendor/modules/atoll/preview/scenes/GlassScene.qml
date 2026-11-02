pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import "../../../../services"
import "../../../common/widgets"
import "../../style"
import "../../components"
import "../parts"

PreviewScene {
    id: glassRoot
    readonly property real naturalWidth: Math.round(620 * glassRoot.d)
    readonly property real naturalHeight: Math.round(280 * glassRoot.d)
    readonly property string mode: String(glassRoot.opt("atoll.appearance.glass.mode", "off"))
    // Blur (beta): Niri blurs what is behind the glass, windows included. The values are the Niri rows' own
    // (AtollCompositorBlur); with Niri blur off the pane keeps the window sharp behind its tint.
    readonly property bool viaNiri: AtollStyle.glassy && glassRoot.mode === "compositor" && AtollCompositorBlur.available
    readonly property bool niriBlur: glassRoot.viaNiri && AtollCompositorBlur.enabled
    // Niri's passes × offset (light 2×2, balanced 3×3, strong 4×4.5) as a share of the preview blur's reach.
    readonly property real niriAmount: ({ light: 0.25, balanced: 0.55, strong: 0.95 })[AtollCompositorBlur.strength] ?? 0.55
    readonly property real niriSaturation: Math.max(-1, Math.min(1, (AtollCompositorBlur.saturation - 1) / 1.5))
    property real t: 0
    Loop on t { running: glassRoot.playing; rest: 600 }
    // What is behind the pane under Niri: the wallpaper and a window, sharp. The pane samples it.
    Item {
        id: behind
        anchors.fill: parent
        z: -1
        visible: glassRoot.viaNiri
        ShaderEffectSource {
            anchors.fill: parent
            sourceItem: glassRoot.viaNiri ? glassRoot.wallpaperView.textureItem : null
            live: true
        }
        Rectangle {
            id: appWindow
            x: Math.round(glassRoot.width * 0.34); y: Math.round(78 * glassRoot.d)
            width: Math.round(250 * glassRoot.d); height: Math.round(136 * glassRoot.d)
            radius: AtollStyle.radiusTile
            color: AtollStyle.surfaceHighOpaque
            Rectangle { x: 0; y: 0; width: Math.round(64 * glassRoot.d); height: parent.height; topLeftRadius: parent.radius; bottomLeftRadius: parent.radius; color: AtollStyle.surfaceOpaque }
            Column {
                x: Math.round(78 * glassRoot.d); y: Math.round(14 * glassRoot.d)
                spacing: Math.round(8 * glassRoot.d)
                Rectangle { width: Math.round(90 * glassRoot.d); height: Math.round(8 * glassRoot.d); radius: AtollStyle.radiusMicro; color: AtollStyle.text }
                Rectangle { width: Math.round(150 * glassRoot.d); height: Math.round(6 * glassRoot.d); radius: AtollStyle.radiusMicro; color: AtollStyle.muted }
                Rectangle { width: Math.round(120 * glassRoot.d); height: Math.round(6 * glassRoot.d); radius: AtollStyle.radiusMicro; color: AtollStyle.muted }
                Rectangle { width: Math.round(158 * glassRoot.d); height: Math.round(34 * glassRoot.d); radius: AtollStyle.radiusRow; color: AtollStyle.accent }
            }
        }
    }
    ClippingRectangle {
        id: pane
        width: Math.round(300 * glassRoot.d)
        height: Math.round(170 * glassRoot.d)
        x: Math.round(24 * glassRoot.d + (glassRoot.width - width - 48 * glassRoot.d) * glassRoot.t)
        y: Math.round(28 * glassRoot.d)
        radius: AtollStyle.radiusSheet
        color: AtollStyle.glassy ? "transparent" : AtollStyle.bodySurface
        // Edges › Style Line: the rim a real body wears, in the same colour and width.
        border.width: AtollStyle.rim.a > 0 ? AtollStyle.rimWidth : 0
        border.color: AtollStyle.rim
        ShaderEffectSource {
            id: paneSource
            x: -pane.x; y: -pane.y
            width: glassRoot.width; height: glassRoot.height
            visible: false
            sourceItem: !AtollStyle.glassy ? null : glassRoot.viaNiri ? behind : glassRoot.wallpaperView.textureItem
            live: true
        }
        MultiEffect {
            anchors.fill: paneSource
            visible: AtollStyle.glassy
            source: paneSource
            blurEnabled: glassRoot.viaNiri ? glassRoot.niriBlur : true
            blur: glassRoot.viaNiri ? glassRoot.niriAmount : AtollStyle.glassBlurAmount
            blurMax: AtollStyle.glassBlurMax
            saturation: glassRoot.viaNiri ? (glassRoot.niriBlur ? glassRoot.niriSaturation : 0) : AtollStyle.glassSaturation
        }
        // Niri's grain: one noise cell, tiled.
        Image {
            anchors.fill: parent
            visible: glassRoot.niriBlur && AtollCompositorBlur.noise > 0
            opacity: Math.min(1, AtollCompositorBlur.noise * 5)
            source: visible ? ((Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")) + "/omarchy/lunana-vendor/" + ("assets/textures/grain.png")) : ""
            fillMode: Image.Tile
            smooth: false
        }
        Rectangle { anchors.fill: parent; visible: AtollStyle.glassy; color: AtollStyle.bodyTint }
        Column {
            x: AtollStyle.concentricPad(pane.radius, 14 * glassRoot.d)
            y: x
            width: pane.width - 2 * x
            spacing: Math.round(4 * glassRoot.d)
            AtollText { text: Translation.tr("Now playing"); font.weight: AtollStyle.weight(Font.DemiBold); font.pixelSize: AtollStyle.typeBody }
            AtollText { width: parent.width; text: Translation.tr("Secondary text stays readable over the wallpaper"); color: AtollStyle.muted; wrapMode: Text.WordWrap; font.pixelSize: AtollStyle.typeMeta }
            AtollText { text: Translation.tr("Tertiary detail"); color: AtollStyle.textTertiary; font.pixelSize: AtollStyle.typeMeta }
        }
        AtollControlPlate {
            id: glassControls
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: AtollStyle.concentricPad(pane.radius, 12 * glassRoot.d)
            controlHeight: Math.round(30 * glassRoot.d)
            Row {
                spacing: glassControls.framed ? Math.round(4 * glassRoot.d) : Math.round(18 * glassRoot.d)
                Repeater {
                    model: ["skip_previous", "pause", "skip_next"]
                    Item {
                        required property string modelData
                        width: Math.round(30 * glassRoot.d); height: width
                        MaterialSymbol { anchors.centerIn: parent; text: parent.modelData; fill: 1; iconSize: Math.round(20 * glassRoot.d); color: AtollStyle.text }
                    }
                }
            }
        }
        AtollGlassEdge { anchors.fill: parent; visible: (AtollStyle.glassy || AtollStyle.edgeLit) && shown; radius: pane.radius }
    }
    Caption {
        glyph: glassRoot.viaNiri ? "blur_on" : AtollStyle.glassy ? "wallpaper" : "crop_square"
        // On the Edges page the head names the edge; on Glass, what the glass lies over.
        text: glassRoot.group === "Edges"
            ? (AtollStyle.edgeLit ? Translation.tr("Lit edges, like glass catching the light")
                : AtollStyle.rim.a > 0 ? Translation.tr("A %1 px line round every surface").arg(AtollStyle.rimWidth)
                : AtollStyle.edgeStyle === "line" ? Translation.tr("No line: Lines is at 0 %")
                : Translation.tr("No edge line"))
            : glassRoot.viaNiri ? Translation.tr("Blur over your windows")
            : AtollStyle.glassy ? Translation.tr("Glass over your wallpaper") : Translation.tr("Solid")
    }
}
