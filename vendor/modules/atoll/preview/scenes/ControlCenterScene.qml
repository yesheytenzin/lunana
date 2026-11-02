pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../../../../services"
import "../../../common/widgets"
import "../../style"
import "../../frame"
import "../../components"
import "../../control"
import "../parts"

PreviewScene {
    id: ccRoot
    readonly property bool on: ccRoot.opt("atoll.modules.controlCenter", true)
    readonly property bool fromIsland: String(ccRoot.opt("atoll.controlCenter.opens", "island")) === "island"
    readonly property bool round: String(ccRoot.opt("atoll.controlCenter.controls", "tiles")) === "round"
    readonly property real plateWidth: Math.max(320, Math.min(540, Number(ccRoot.opt("atoll.controlCenter.width", 360)))) * ccRoot.d
    readonly property int columns: { ccRoot.rev; return AtollControlOptions.columns }
    readonly property var ids: { ccRoot.rev; return AtollControlOptions.gridModules }
    readonly property bool listed: { ccRoot.rev; return AtollControlOptions.modules.includes("notifications") }
    readonly property var packed: {
        ccRoot.rev
        const shapes = ({})
        for (const id of ccRoot.ids) shapes[id] = AtollControlOptions.shapeOf(id)
        return AtollControlOptions.pack(ccRoot.ids, shapes, ccRoot.columns)
    }
    readonly property real naturalWidth: ccRoot.plateWidth + Math.round(120 * ccRoot.d)
    readonly property real naturalHeight: ccPlate.y + ccPlate.height + Math.round(24 * ccRoot.d)
    readonly property bool cropBottom: true
    IslandPill {
        id: ccIsland
        anchors.horizontalCenter: parent.horizontalCenter
        y: AtollFrame.band
        opacity: ccRoot.fromIsland ? 0 : 1
    }
    Plate {
        id: ccPlate
        surface: "controlCenter"
        fallbackRadius: AtollStyle.radiusPanel
        opacity: ccRoot.on ? 1 : 0.35
        anchors.horizontalCenter: parent.horizontalCenter
        y: ccRoot.fromIsland ? AtollFrame.band : ccIsland.y + ccIsland.height + AtollFrame.bodyAir
        width: ccRoot.plateWidth
        height: ccColumn.implicitHeight + Math.round(28 * ccRoot.d)
        ColumnLayout {
            id: ccColumn
            x: Math.round(14 * ccRoot.d); y: Math.round(14 * ccRoot.d)
            width: parent.width - 2 * x
            spacing: Math.round(10 * ccRoot.d)
            AtollText { text: Translation.tr("Control Center"); font.weight: AtollStyle.weight(Font.DemiBold); font.pixelSize: AtollStyle.typeHeadline }
            Item {
                id: ccGrid
                readonly property real gap: Math.round(8 * ccRoot.d)
                readonly property real cell: (width - (ccRoot.columns - 1) * gap) / ccRoot.columns
                readonly property real unit: Math.round((ccRoot.opt("atoll.controlCenter.labels", false) ? 70 : 64) * ccRoot.d)
                Layout.fillWidth: true
                implicitHeight: ccRoot.packed.rows * unit + Math.max(0, ccRoot.packed.rows - 1) * gap
                Repeater {
                    model: ccRoot.ids
                    Rectangle {
                        id: block
                        required property string modelData
                        required property int index
                        readonly property var spot: ccRoot.packed.placed[block.modelData]
                        readonly property string kind: AtollControlOptions.kindOf(block.modelData)
                        readonly property bool wide: !["media", "level", "levels", "platter"].includes(block.kind) && block.spot.w > 1
                        readonly property bool grouped: block.kind === "levels" || block.kind === "platter"
                        readonly property bool upright: block.spot.h > block.spot.w
                        x: Math.round(block.spot.col * (ccGrid.cell + ccGrid.gap))
                        y: Math.round(block.spot.row * (ccGrid.unit + ccGrid.gap))
                        width: Math.round(block.spot.w * ccGrid.cell + (block.spot.w - 1) * ccGrid.gap)
                        height: Math.round(block.spot.h * ccGrid.unit + (block.spot.h - 1) * ccGrid.gap)
                        radius: block.kind === "platter" || block.kind === "media" ? AtollStyle.radiusPlate
                            : !ccRoot.round ? AtollStyle.radiusTile : Math.min(width, height) / 2
                        color: block.kind === "levels" ? "transparent"
                            : block.index === 0 && block.kind === "toggle" && !block.wide ? AtollStyle.accent : AtollStyle.fillQuiet
                        clip: true
                        Grid {
                            visible: block.kind === "platter"
                            anchors.centerIn: parent
                            columns: block.spot.w > 2 ? 4 : 2
                            spacing: Math.round(10 * ccRoot.d)
                            Repeater {
                                model: AtollControlOptions.platterIds
                                Rectangle {
                                    required property string modelData
                                    required property int index
                                    width: Math.round(38 * ccRoot.d)
                                    height: width
                                    radius: width / 2
                                    color: index === 0 ? AtollStyle.accent : AtollStyle.fill
                                    MaterialSymbol { anchors.centerIn: parent; text: AtollControlOptions.glyphOf(parent.modelData); iconSize: Math.round(17 * ccRoot.d); color: parent.index === 0 ? AtollStyle.inkOnAccent : AtollStyle.text }
                                }
                            }
                        }
                        Row {
                            visible: block.kind === "levels"
                            anchors.centerIn: parent
                            spacing: Math.round(10 * ccRoot.d)
                            Repeater {
                                model: AtollControlOptions.levelIds
                                Rectangle {
                                    required property string modelData
                                    width: Math.round(Math.min(46 * ccRoot.d, (block.width - 20 * ccRoot.d) / 3))
                                    height: block.height
                                    radius: width / 2
                                    color: AtollStyle.fill
                                    Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: parent.height * 0.6; radius: parent.radius; color: AtollStyle.fillStrong }
                                    MaterialSymbol { anchors.horizontalCenter: parent.horizontalCenter; anchors.bottom: parent.bottom; anchors.bottomMargin: Math.round(10 * ccRoot.d); text: AtollControlOptions.glyphOf(parent.modelData); iconSize: Math.round(15 * ccRoot.d); color: AtollStyle.surface }
                                }
                            }
                        }
                        Rectangle {
                            visible: block.kind === "level"
                            y: block.upright ? parent.height * 0.4 : 0
                            width: block.upright ? parent.width : parent.width * 0.6
                            height: block.upright ? parent.height * 0.6 : parent.height
                            radius: parent.radius
                            color: AtollStyle.fillStrong
                        }
                        MaterialSymbol {
                            visible: !block.wide && !block.grouped && block.kind !== "media"
                            x: block.kind === "level" && !block.upright ? Math.round(14 * ccRoot.d) : Math.round((parent.width - width) / 2)
                            y: block.kind === "level" && block.upright ? parent.height - height - Math.round(14 * ccRoot.d) : Math.round((parent.height - height) / 2)
                            text: AtollControlOptions.glyphOf(block.modelData)
                            iconSize: Math.round(18 * ccRoot.d)
                            color: block.kind === "level" ? AtollStyle.surface : block.index === 0 ? AtollStyle.inkOnAccent : AtollStyle.text
                        }
                        RowLayout {
                            visible: block.wide || block.kind === "media"
                            anchors.fill: parent
                            anchors.margins: Math.round(10 * ccRoot.d)
                            spacing: Math.round(8 * ccRoot.d)
                            Rectangle {
                                Layout.alignment: block.kind === "media" && block.spot.h > 1 && !(block.spot.w > 2) ? Qt.AlignTop : Qt.AlignVCenter
                                implicitWidth: Math.round(30 * ccRoot.d)
                                implicitHeight: implicitWidth
                                radius: width / 2
                                color: block.kind === "media" ? AtollStyle.fillActive : AtollStyle.accent
                                MaterialSymbol {
                                    anchors.centerIn: parent
                                    text: block.kind === "media" ? "music_note" : AtollControlOptions.glyphOf(block.modelData)
                                    iconSize: Math.round(16 * ccRoot.d)
                                    color: block.kind === "media" ? AtollStyle.subtext : AtollStyle.inkOnAccent
                                }
                            }
                            AtollText {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                text: block.kind === "media" ? (MprisController.titleOf(MprisController.activePlayer) || Translation.tr("Not playing"))
                                    : Translation.tr(AtollControlOptions.labelOf(block.modelData))
                                font.weight: AtollStyle.weight(Font.DemiBold)
                                font.pixelSize: AtollStyle.typeMeta
                                elide: Text.ElideRight
                            }
                        }
                    }
                }
            }
            Rectangle {
                Layout.fillWidth: true
                visible: ccRoot.listed
                implicitHeight: Math.round(52 * ccRoot.d)
                radius: AtollStyle.radiusPlate
                color: AtollStyle.fillQuiet
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: Math.round(12 * ccRoot.d)
                    MaterialSymbol { text: "notifications"; iconSize: Math.round(17 * ccRoot.d); color: AtollStyle.subtext }
                    AtollText { Layout.fillWidth: true; text: Translation.tr("You're all caught up"); color: AtollStyle.subtext }
                }
            }
        }
    }
    OffState { visible: !ccRoot.on; text: Translation.tr("Control Center off") }
    Caption {
        glyph: ccRoot.fromIsland ? "pill" : "web_asset"
        text: (ccRoot.fromIsland ? Translation.tr("Becomes the Island's controls page") : Translation.tr("Hangs from the Island as a panel")) + " · " + (ccRoot.round ? Translation.tr("round") : Translation.tr("tiles"))
    }
}
