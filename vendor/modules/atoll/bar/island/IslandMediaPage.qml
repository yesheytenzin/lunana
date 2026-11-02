pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Dialogs
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import "../../../.."
import "../../../../services"
import "../../../../services/deferred"
import "../../../common"
import "../../../common/functions"
import "../../../common/widgets"
import "../../../mediaControls/components"
import "../../style"
import "../../components"
import "../../frame"
import "../../pieces"

GridLayout {
    id: page
    required property Item island
    readonly property bool current: page.island.effectivePage === "media"
    columns: 1
    rowSpacing: 14 * AtollStyle.density
    columnSpacing: 0
    readonly property var blocks: {
        const configured = Config.options?.atoll?.bar?.mediaBlocks
        return Array.isArray(configured) ? configured : ["player", "timeline", "transport", "players", "levels"]
    }
    function rowOf(kind: string): int { return page.blocks.indexOf(kind) }
    readonly property string firstExtra: page.blocks.find(kind => (kind === "players" && page.otherPlayers.length > 0) || (kind === "levels" && page.streams.length > 0)) ?? ""


    PlayerBase {
        id: media
        player: page.island.player
        positionUpdatesActive: page.current && page.island.visualExpanded
    }

    readonly property bool anime: AnimeWatch.ownsPlayer(page.island.player)
    readonly property var otherPlayers: (MprisController.displayPlayers ?? []).filter(p => p && p !== page.island.player)
    readonly property var streams: {
        const groups = []
        for (const node of (Audio.outputAppNodes ?? [])) {
            if (!node?.audio) continue
            const name = Audio.appNodeDisplayName(node)
            const group = groups.find(g => g.name === name)
            if (group) group.nodes.push(node)
            else groups.push({ name: name, nodes: [node] })
        }
        return groups
    }

    ColumnLayout {
        Layout.row: Math.max(0, page.rowOf("player"))
        Layout.fillWidth: true
        visible: page.rowOf("player") >= 0
        spacing: 10 * AtollStyle.density
        RowLayout {
            Layout.fillWidth: true
            spacing: 14 * AtollStyle.density
            AtollArtwork {
                id: pageCover
                opacity: page.island.coverFlightItem.hides(pageCover) ? 0 : 1
                Component.onCompleted: page.island.pageCover = pageCover
                Layout.preferredWidth: 68 * AtollStyle.density
                Layout.preferredHeight: 68 * AtollStyle.density
                source: MediaArtwork.displaySource
                circular: Config.options?.atoll?.player?.roundCover ?? false
                radius: circular ? width / 2 : 16 * AtollStyle.density
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2 * AtollStyle.density
                AtollText {
                    Layout.fillWidth: true
                    text: media.effectiveTitle
                    font.pixelSize: AtollStyle.typeHeadline
                    font.weight: AtollStyle.weight(Font.DemiBold)
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                }
                AtollText {
                    Layout.fillWidth: true
                    text: media.effectiveArtist
                    visible: text.length > 0
                    color: AtollStyle.textSecondary
                    font.pixelSize: AtollStyle.typeLabel
                    elide: Text.ElideRight
                }
            }
            AtollVisualizer {
                Layout.alignment: Qt.AlignVCenter
                running: media.effectiveIsPlaying && page.current && page.island.visualExpanded
                tint: AtollStyle.visualizerTint(page.island.artTint)
                barHeight: 20 * AtollStyle.density
            }
        }
    }

    ColumnLayout {
        Layout.row: Math.max(0, page.rowOf("timeline"))
        Layout.fillWidth: true
        visible: page.rowOf("timeline") >= 0 && media.effectiveLength > 0
        spacing: 10 * AtollStyle.density
        ColumnLayout {
            Layout.fillWidth: true
            visible: media.effectiveLength > 0
            spacing: 3 * AtollStyle.density
            AtollScrubber {
                Layout.fillWidth: true
                seekable: media.effectiveCanSeek
                value: media.effectiveLength > 0 ? media.effectivePosition / media.effectiveLength : 0
                fillColor: page.island.artTint
                trackColor: AtollStyle.tintFill(page.island.artTint)
                onSeekRequested: next => media.seek(next * media.effectiveLength)
            }
            RowLayout {
                Layout.fillWidth: true
                Tabular {
                    text: page.island.clockText(media.effectivePosition)
                    color: AtollStyle.textSecondary
                    font.pixelSize: AtollStyle.typeFootnote
                    font.weight: AtollStyle.weight(Font.Medium)
                }
                Item { Layout.fillWidth: true }
                Tabular {
                    text: "-" + page.island.clockText(media.effectiveLength - media.effectivePosition)
                    color: AtollStyle.textSecondary
                    font.pixelSize: AtollStyle.typeFootnote
                    font.weight: AtollStyle.weight(Font.Medium)
                }
            }
        }
    }

    ColumnLayout {
        Layout.row: Math.max(0, page.rowOf("transport"))
        Layout.fillWidth: true
        visible: page.rowOf("transport") >= 0
        spacing: 10 * AtollStyle.density
        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: -6 * AtollStyle.density
            Layout.bottomMargin: -4 * AtollStyle.density
            spacing: 0
            Item { Layout.fillWidth: true }
            AtollControlPlate {
                id: transport
                material: page.island.pagePlate
                controlHeight: 52 * AtollStyle.density
                RowLayout {
                spacing: transport.framed ? 6 * AtollStyle.density : 18 * AtollStyle.density
            GlyphButton {
                Layout.alignment: Qt.AlignVCenter
                buttonRadius: transport.framed ? AtollStyle.pieceRadius(height) : height / 2
                buttonRadiusPressed: buttonRadius
                glyph: "fast_rewind"
                glyphSize: 26 * AtollStyle.density
                implicitWidth: 44 * AtollStyle.density
                enabled: page.anime || media.effectiveCanGoPrevious
                Accessible.name: page.anime ? Translation.tr("Previous episode") : Translation.tr("Previous track")
                onClicked: page.anime ? AnimeWatch.skip("previous") : media.previous()
            }
            GlyphButton {
                glyph: media.effectiveIsPlaying ? "pause" : "play_arrow"
                glyphSize: 36 * AtollStyle.density
                implicitWidth: 52 * AtollStyle.density
                buttonRadius: transport.framed ? transport.controlRadius : height / 2
                buttonRadiusPressed: buttonRadius
                enabled: page.island.hasMedia
                Accessible.name: media.effectiveIsPlaying ? Translation.tr("Pause") : Translation.tr("Play")
                onClicked: media.togglePlaying()
            }
            GlyphButton {
                Layout.alignment: Qt.AlignVCenter
                buttonRadius: transport.framed ? AtollStyle.pieceRadius(height) : height / 2
                buttonRadiusPressed: buttonRadius
                glyph: "fast_forward"
                glyphSize: 26 * AtollStyle.density
                implicitWidth: 44 * AtollStyle.density
                enabled: page.anime || media.effectiveCanGoNext
                Accessible.name: page.anime ? Translation.tr("Next episode") : Translation.tr("Next track")
                onClicked: page.anime ? AnimeWatch.skip("next") : media.next()
            }
                }
            }
            Item { Layout.fillWidth: true }
        }
        ColumnLayout {
            Layout.fillWidth: true
            visible: page.anime
            spacing: 8 * AtollStyle.density
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 1
                color: AtollStyle.hairline
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 5 * AtollStyle.density
                AtollText {
                    text: Translation.tr("Subtitles")
                    color: AtollStyle.textSecondary
                    font.pixelSize: AtollStyle.typeMeta
                }
                Item { Layout.fillWidth: true }
                AnimeChip {
                    text: Translation.tr("Off")
                    active: AnimeWatch.subtitleId <= 0
                    onClicked: AnimeWatch.selectSubtitle(0)
                }
                Repeater {
                    model: AnimeWatch.subtitles
                    AnimeChip {
                        required property var modelData
                        required property int index
                        text: AnimeWatch.subtitleLabel(modelData, index)
                        active: AnimeWatch.subtitleId === Number(modelData.id)
                        onClicked: AnimeWatch.selectSubtitle(Number(modelData.id))
                    }
                }
                AnimeChip {
                    glyph: "add"
                    Accessible.name: Translation.tr("Load a subtitle file")
                    onClicked: subtitleDialog.open()
                }
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 12 * AtollStyle.density
                AnimeStepper {
                    label: Translation.tr("Size")
                    value: AnimeWatch.subtitleScale + "%"
                    onLess: AnimeWatch.setSubtitleScale(AnimeWatch.subtitleScale - 10)
                    onMore: AnimeWatch.setSubtitleScale(AnimeWatch.subtitleScale + 10)
                }
                AnimeStepper {
                    label: Translation.tr("Sync")
                    value: (AnimeWatch.subtitleDelay > 0 ? "+" : "") + AnimeWatch.subtitleDelay.toFixed(1) + " s"
                    onLess: AnimeWatch.nudgeSubtitleDelay(-0.1)
                    onMore: AnimeWatch.nudgeSubtitleDelay(0.1)
                    onReset: AnimeWatch.resetSubtitleDelay()
                }
                Item { Layout.fillWidth: true }
                AnimeChip {
                    glyph: "replay_10"
                    glyphSize: 17
                    Accessible.name: Translation.tr("Back 10 seconds")
                    onClicked: AnimeWatch.seekBy(-10)
                }
                AnimeChip {
                    glyph: "fast_forward"
                    text: Translation.tr("Skip OP")
                    Accessible.name: Translation.tr("Skip 85 seconds")
                    onClicked: AnimeWatch.seekBy(85)
                }
            }
        }
    }

    ColumnLayout {
        Layout.row: Math.max(0, page.rowOf("players"))
        Layout.fillWidth: true
        visible: page.rowOf("players") >= 0 && page.otherPlayers.length > 0
        spacing: 10 * AtollStyle.density
        Rectangle {
            Layout.fillWidth: true
            visible: page.firstExtra === "players"
            implicitHeight: 1
            color: AtollStyle.hairline
        }
        AtollPlayerChips {
            Layout.fillWidth: true
            player: page.island.player
            accent: page.island.artTint
        }
    }

    ColumnLayout {
        Layout.row: Math.max(0, page.rowOf("levels"))
        Layout.fillWidth: true
        visible: page.rowOf("levels") >= 0 && page.streams.length > 0
        spacing: 10 * AtollStyle.density
        Rectangle {
            Layout.fillWidth: true
            visible: page.firstExtra === "levels"
            implicitHeight: 1
            color: AtollStyle.hairline
        }
        Repeater {
            model: page.streams.slice(0, 4)
            RowLayout {
                id: appLevel
                required property var modelData
                readonly property var nodes: Array.from(appLevel.modelData?.nodes ?? [])
                readonly property bool muted: appLevel.nodes.every(node => node?.audio?.muted)
                // Teardown re-evaluates bindings in a dead context; `live` keeps them from applying.
                property bool live: true
                Component.onDestruction: appLevel.live = false
                Layout.fillWidth: true
                spacing: 10 * AtollStyle.density
                AtollImage {
                    Layout.preferredWidth: Math.round(22 * AtollStyle.density)
                    Layout.preferredHeight: Layout.preferredWidth
                    Binding on source {
                        when: appLevel.live
                        restoreMode: Binding.RestoreNone
                        value: appLevel.nodes.length > 0
                            ? Quickshell.iconPath(MprisController.streamIconName(appLevel.nodes[0]) ?? "", "audio-x-generic") ?? "" : ""
                    }
                    opacity: appLevel.muted ? 0.45 : 1
                }
                AtollText {
                    Layout.preferredWidth: Math.round(110 * AtollStyle.density)
                    text: appLevel.nodes.length > 1 ? appLevel.modelData.name + " · " + appLevel.nodes.length : appLevel.modelData.name
                    color: (appLevel.muted ? AtollStyle.textTertiary : AtollStyle.textStrong)
                    font.pixelSize: AtollStyle.typeMeta
                    font.weight: AtollStyle.weight(Font.Medium)
                    elide: Text.ElideRight
                }
                AtollScrubber {
                    Layout.fillWidth: true
                    fillColor: appLevel.muted ? AtollStyle.muted : AtollStyle.fillStrong
                    Binding on value {
                        when: appLevel.live
                        restoreMode: Binding.RestoreNone
                        value: Math.min(1, Math.max(0, ...appLevel.nodes.map(node => Number(node?.audio?.volume) || 0)))
                    }
                    onMoved: next => appLevel.nodes.forEach(node => { if (node?.audio) node.audio.volume = next })
                }
                GlyphButton {
                    glyph: appLevel.muted ? "volume_off" : "volume_up"
                    glyphSize: 17 * AtollStyle.density
                    implicitWidth: Math.round(30 * AtollStyle.density)
                    glyphColor: appLevel.muted ? AtollStyle.danger : AtollStyle.text
                    Accessible.name: appLevel.muted ? Translation.tr("Unmute") : Translation.tr("Mute")
                    onClicked: {
                        const mute = !appLevel.muted
                        appLevel.nodes.forEach(node => { if (node?.audio) node.audio.muted = mute })
                    }
                }
            }
        }
    }


    FileDialog {
        id: subtitleDialog
        title: Translation.tr("Load subtitles")
        fileMode: FileDialog.OpenFile
        currentFolder: "file://" + Directories.homePath
        nameFilters: [Translation.tr("Subtitles") + " (*.srt *.ass *.ssa *.vtt *.sub)", Translation.tr("All files") + " (*)"]
        onAccepted: AnimeWatch.addSubtitle(String(selectedFile))
    }

    component AnimeChip: MouseArea {
        id: chip
        property string text: ""
        property string glyph: ""
        property real glyphSize: 14
        property bool active: false
        implicitWidth: chipRow.implicitWidth + Math.round((chip.text.length > 0 ? 18 : 12) * AtollStyle.density)
        implicitHeight: Math.round(26 * AtollStyle.density)
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        Accessible.role: Accessible.Button
        Accessible.name: chip.text
        Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: chip.active ? AtollStyle.tintFill(page.island.artTint)
                : chip.pressed ? AtollStyle.fillActive : chip.containsMouse ? AtollStyle.fillHover : AtollStyle.fillQuiet
            Behavior on color { ColorAnimation { duration: AtollStyle.duration(110); easing.type: AtollStyle.feedbackEasing } }
        }
        Row {
            id: chipRow
            anchors.centerIn: parent
            spacing: Math.round(4 * AtollStyle.density)
            Glyph {
                visible: chip.glyph.length > 0
                anchors.verticalCenter: parent.verticalCenter
                text: chip.glyph
                iconSize: chip.glyphSize * AtollStyle.density
                color: chip.active ? page.island.artTint : AtollStyle.text
            }
            AtollText {
                visible: chip.text.length > 0
                anchors.verticalCenter: parent.verticalCenter
                text: chip.text
                color: chip.active ? page.island.artTint : AtollStyle.textSecondary
                font.pixelSize: AtollStyle.typeFootnote
                font.weight: AtollStyle.weight(Font.DemiBold)
            }
        }
    }

    component AnimeStepper: RowLayout {
        id: stepper
        property string label: ""
        property string value: ""
        signal less()
        signal more()
        signal reset()
        spacing: Math.round(2 * AtollStyle.density)
        AtollText {
            Layout.alignment: Qt.AlignBaseline
            text: stepper.label
            color: AtollStyle.textSecondary
            font.pixelSize: AtollStyle.typeMeta
            rightPadding: Math.round(4 * AtollStyle.density)
        }
        GlyphButton {
            glyph: "remove"
            glyphSize: 15 * AtollStyle.density
            implicitWidth: Math.round(24 * AtollStyle.density)
            Accessible.name: Translation.tr("Less %1").arg(stepper.label)
            onClicked: stepper.less()
        }
        Tabular {
            Layout.alignment: Qt.AlignBaseline
            text: stepper.value
            font.pixelSize: AtollStyle.typeMeta
            font.weight: AtollStyle.weight(Font.DemiBold)
            horizontalAlignment: Text.AlignHCenter
            Layout.minimumWidth: Math.round(40 * AtollStyle.density)
            TapHandler { onTapped: stepper.reset() }
        }
        GlyphButton {
            glyph: "add"
            glyphSize: 15 * AtollStyle.density
            implicitWidth: Math.round(24 * AtollStyle.density)
            Accessible.name: Translation.tr("More %1").arg(stepper.label)
            onClicked: stepper.more()
        }
    }
}
