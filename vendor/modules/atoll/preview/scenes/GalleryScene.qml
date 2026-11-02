pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Widgets
import "../../../../services"
import "../../style"
import "../../components"
import "../parts"

PreviewScene {
    id: galleryRoot
    readonly property real galleryWidth: Math.max(640, Math.min(1400, Number(galleryRoot.opt("atoll.wallpaper.width", 960)))) * galleryRoot.d
    readonly property real thumb: Math.max(160, Math.min(320, Number(galleryRoot.opt("atoll.wallpaper.thumbnailSize", 228)))) * galleryRoot.d
    readonly property bool live: galleryRoot.opt("atoll.wallpaper.livePreview", true)
    readonly property int perRow: Math.max(1, Math.floor((galleryRoot.galleryWidth - 30 * galleryRoot.d) / (galleryRoot.thumb + 10 * galleryRoot.d)))
    readonly property var sources: {
        const list = Array.from(Wallpapers.wallpapers ?? []).map(path => Wallpapers.stillUrlFor(path)).filter(url => url.length > 0)
        const pool = list.length > 0 ? list : [galleryRoot.wallpaper]
        return Array.from({ length: galleryRoot.perRow * 2 }, (_, i) => pool[i % pool.length])
    }
    readonly property real naturalWidth: galleryRoot.galleryWidth + Math.round(80 * galleryRoot.d)
    readonly property real naturalHeight: galleryRoot.thumb * 0.62 * 2 + Math.round(170 * galleryRoot.d)
    property int focusIndex: 1
    Timer {
        running: galleryRoot.playing
        interval: 1600
        repeat: true
        onTriggered: galleryRoot.focusIndex = (galleryRoot.focusIndex + 1) % Math.max(1, galleryRoot.sources.length)
    }
    AtollImage {
        anchors.fill: parent
        visible: galleryRoot.live
        source: galleryRoot.sources[galleryRoot.focusIndex] ?? ""
    }
    Plate {
        id: galleryPlate
        surface: "gallery"
        own: AtollStyle.wallpaperLight
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Math.round(26 * galleryRoot.d)
        width: galleryRoot.galleryWidth
        height: galleryFlow.implicitHeight + Math.round(64 * galleryRoot.d)
        AtollText {
            x: Math.round(20 * galleryRoot.d); y: Math.round(16 * galleryRoot.d)
            text: Translation.tr("Wallpapers")
            font.family: AtollStyle.fontTitle; font.weight: AtollStyle.weight(Font.Bold); font.pixelSize: AtollStyle.typeTitle
        }
        Flow {
            id: galleryFlow
            x: Math.round(20 * galleryRoot.d); y: Math.round(48 * galleryRoot.d)
            width: parent.width - 2 * x
            spacing: Math.round(10 * galleryRoot.d)
            Repeater {
                model: galleryRoot.sources
                ClippingRectangle {
                    id: shot
                    required property string modelData
                    required property int index
                    width: galleryRoot.thumb
                    height: Math.round(galleryRoot.thumb * 0.62)
                    radius: AtollStyle.radiusTile
                    border.width: shot.index === galleryRoot.focusIndex ? 2 : 0
                    border.color: AtollStyle.accent
                    AtollImage { anchors.fill: parent; source: shot.modelData }
                }
            }
        }
    }
    Caption {
        anchors.bottom: undefined
        anchors.top: parent.top
        glyph: galleryRoot.live ? "preview" : "preview_off"
        text: galleryRoot.live ? Translation.tr("The desktop previews the chosen wallpaper") : Translation.tr("Wallpapers apply only when chosen")
    }
}
