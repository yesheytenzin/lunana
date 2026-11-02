pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Quickshell.Widgets
import "../../../../services"
import "../../../common/functions"
import "../../../common/widgets"
import "../../style"
import "../../components"
import "../parts"

// One small body per surface, each with its own corners and its own glass or solid, resolved the way the real surface
// resolves them (AtollStyle.surfaceRadius with that surface's usual fallback, AtollStyle.surfaceGlass), over the wallpaper.
PreviewScene {
    id: surfaces
    // Laid tight, so the labels read at the head's size.
    readonly property real naturalWidth: Math.round(460 * surfaces.d)
    readonly property real naturalHeight: Math.round(270 * surfaces.d)
    readonly property int columns: 4
    readonly property real margin: Math.round(16 * surfaces.d)
    readonly property real gap: Math.round(10 * surfaces.d)
    readonly property real cellWidth: (surfaces.width - 2 * surfaces.margin - (surfaces.columns - 1) * surfaces.gap) / surfaces.columns
    // The caption keeps the bottom strip.
    readonly property real cellHeight: (surfaces.height - surfaces.margin - Math.round(52 * surfaces.d) - 2 * surfaces.gap) / 3
    // The island's open corners and the menus' density change what these tiles resolve: re-read them here.
    readonly property string menusDensity: String(surfaces.opt("atoll.appearance.surfaces.menus.density", "compact"))
    readonly property var tiles: [
        { id: "island", label: Translation.tr("Island") },
        { id: "cards", label: Translation.tr("Cards") },
        { id: "controlCenter", label: Translation.tr("Control Center") },
        { id: "panels", label: Translation.tr("Side panels") },
        { id: "spotlight", label: Translation.tr("Spotlight") },
        { id: "orbit", label: Translation.tr("Orbit") },
        { id: "settings", label: Translation.tr("Settings") },
        { id: "menus", label: Translation.tr("Menus") },
        { id: "gallery", label: Translation.tr("Wallpaper gallery") },
        { id: "osd", label: Translation.tr("Volume and song pill") }
    ]

    // The radius each real surface passes as its fallback (see where it calls AtollStyle.surfaceRadius).
    function fallbackRadius(id: string, height: real): real {
        switch (id) {
        case "island": return AtollStyle.openedRadius(AtollStyle.barShape, Math.max(AtollStyle.radius, Math.round(30 * surfaces.d)))
        case "cards": return AtollStyle.radiusSheet
        case "panels": return AtollStyle.radius
        case "menus": return surfaces.menusDensity === "regular" ? AtollStyle.radiusCard : AtollStyle.radiusTile
        case "osd": return AtollStyle.pieceRadius(height)
        default: return AtollStyle.radiusPanel
        }
    }

    // One body: wallpaper frost with the tint over it, or the solid paper, and the shadow a floating body casts.
    component Tile: Item {
        id: tile
        required property PreviewScene scene
        required property string surface
        required property string label
        // What the real surface passes as its corners fallback.
        required property real fallback
        // Re-read when the rows of this surface change.
        readonly property string materialRow: String(tile.scene.opt("atoll.appearance.surfaces." + tile.surface + ".material", ""))
        readonly property real radiusRow: Number(tile.scene.opt("atoll.appearance.surfaces." + tile.surface + ".radius", 0))
        readonly property string resolved: { tile.materialRow; return AtollStyle.surfaceGlass(tile.surface) }
        readonly property bool glass: tile.resolved === "solid" ? false : tile.resolved === "inherit" ? AtollStyle.glassy : true
        // A body never rounds past its own half height.
        readonly property real radius: {
            tile.radiusRow
            return Math.min(AtollStyle.surfaceRadius(tile.surface, tile.fallback), Math.min(tile.width, tile.height) / 2)
        }
        RectangularShadow {
            anchors.fill: plate
            radius: plate.radius
            offset.y: Math.round(3 * tile.scene.d)
            blur: Math.round(12 * tile.scene.d)
            color: AtollStyle.shadow
        }
        ClippingRectangle {
            id: plate
            anchors.fill: parent
            radius: tile.radius
            color: tile.glass ? "transparent" : AtollStyle.bodySurface
            border.width: !tile.glass && AtollStyle.rim.a > 0 ? 1 : 0
            border.color: AtollStyle.rim
            // Only the picture under this tile, with the blur's reach around it: ten tiles never blur ten scenes.
            ShaderEffectSource {
                id: frostSource
                readonly property real reach: AtollStyle.glassBlurMax
                x: -frostSource.reach; y: -frostSource.reach
                width: tile.width + 2 * frostSource.reach; height: tile.height + 2 * frostSource.reach
                visible: false
                sourceItem: tile.glass ? tile.scene.wallpaperView.textureItem : null
                sourceRect: Qt.rect(tile.x - frostSource.reach, tile.y - frostSource.reach, frostSource.width, frostSource.height)
                live: true
            }
            MultiEffect {
                anchors.fill: frostSource
                visible: tile.glass
                source: frostSource
                blurEnabled: true
                blur: AtollStyle.glassBlurAmount
                blurMax: AtollStyle.glassBlurMax
                saturation: AtollStyle.glassSaturation
            }
            Rectangle { anchors.fill: parent; visible: tile.glass; color: ColorUtils.applyAlpha(AtollStyle.surfaceOpaque, AtollStyle.glassTint) }
            AtollGlassEdge { anchors.fill: parent; visible: (tile.glass || AtollStyle.edgeLit) && shown; radius: plate.radius }
            AtollText {
                anchors.centerIn: parent
                width: parent.width - 2 * Math.round(8 * tile.scene.d)
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                maximumLineCount: 2
                elide: Text.ElideRight
                text: tile.label
                font.weight: AtollStyle.weight(Font.DemiBold)
                font.pixelSize: AtollStyle.typeMeta
            }
        }
    }

    Repeater {
        model: surfaces.tiles
        Tile {
            id: cell
            required property var modelData
            required property int index
            // The last row holds two tiles: centred under the others.
            readonly property int row: Math.floor(cell.index / surfaces.columns)
            readonly property int column: cell.index % surfaces.columns
            readonly property real rowShift: cell.row === 2 ? (surfaces.columns - (surfaces.tiles.length - 2 * surfaces.columns)) * (surfaces.cellWidth + surfaces.gap) / 2 : 0
            scene: surfaces
            surface: cell.modelData.id
            label: cell.modelData.label
            fallback: surfaces.fallbackRadius(cell.modelData.id, cell.height)
            x: Math.round(surfaces.margin + cell.column * (surfaces.cellWidth + surfaces.gap) + cell.rowShift)
            y: Math.round(surfaces.margin + cell.row * (surfaces.cellHeight + surfaces.gap))
            width: Math.round(surfaces.cellWidth)
            height: Math.round(surfaces.cellHeight)
        }
    }

    Caption {
        glyph: "dashboard"
        text: Translation.tr("Each surface, its own corners and glass")
    }
}
