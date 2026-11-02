pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import "../../../services"
import "../../common"
import "../../common/functions"
import "../../common/widgets"
import "../../mediaControls/components"
import "../pieces"
import "../style"

Item {
    id: root
    property var player: MprisController.activePlayer
    property bool compact: false
    property bool active: visible
    property bool showBackground: true
    property real headerReserve: 0
    property bool showPlayers: true
    // On a veil over imagery (the lock), which stays dark in every scheme: media ink instead of the scheme's.
    property bool overMedia: false
    readonly property color ink: root.overMedia ? AtollStyle.onMedia : AtollStyle.text
    readonly property color inkMeta: root.overMedia ? AtollStyle.onMediaSecondary : AtollStyle.subtext
    readonly property color inkSecondary: root.overMedia ? AtollStyle.onMediaSecondary : AtollStyle.textSecondary
    readonly property color inkTertiary: root.overMedia ? AtollStyle.onMediaTertiary : AtollStyle.textTertiary
    property color tint: root.ink
    readonly property bool hasPlayer: root.player !== null && root.player !== undefined
    // A stream is live when it has no length, cannot seek while playing, or its end keeps running
    // away from a playhead that sits at it. Every sign is re-read, never latched: a browser that
    // sends a track's title before its length, or a seek that republishes metadata, must not leave
    // a normal video reading "Live" for the rest of the track.
    readonly property string trackKey: (root.player?.dbusName ?? "") + "\n" + media.effectiveTitle
    property real seenLength: 0
    property int grewSamples: 0
    property int atEndSamples: 0
    onTrackKeyChanged: { root.seenLength = 0; root.grewSamples = 0; root.atEndSamples = 0 }
    Timer {
        interval: 2000
        repeat: true
        running: root.active && root.hasPlayer && media.effectiveIsPlaying
        onTriggered: {
            const len = media.effectiveLength
            const pos = media.effectivePosition
            const atEdge = len > 0 && pos >= len - 1
            root.atEndSamples = atEdge ? root.atEndSamples + 1 : 0
            const grew = root.seenLength > 0 && len > root.seenLength + 1 && pos >= root.seenLength - 3
            root.grewSamples = grew ? root.grewSamples + 1 : 0
            if (len > 0) root.seenLength = len
        }
    }
    readonly property bool liveStream: root.hasPlayer
        && (media.effectiveLength <= 0
            || (media.effectiveIsPlaying && !media.effectiveCanSeek)
            || root.grewSamples >= 2
            || root.atEndSamples >= 2)
    readonly property bool hasTimeline: root.hasPlayer && !root.liveStream && media.effectiveLength > 0
    // Nothing playing: the card offers the music app you use most and opens it. Not on the lock, where nothing opens.
    property bool offersOpen: true
    readonly property bool offersMusic: root.offersOpen && !root.hasPlayer && AtollPieces.musicAppName.length > 0
    readonly property string emptyDetail: root.offersOpen ? AtollPieces.musicDetail : Translation.tr("Your music appears here")
    readonly property string emptyIcon: root.offersMusic ? AtollPieces.musicAppIcon : ""
    MouseArea {
        anchors.fill: parent
        visible: root.offersMusic
        cursorShape: AtollPieces.musicLaunch === "opening" ? Qt.BusyCursor : Qt.PointingHandCursor
        onClicked: AtollPieces.openMusic()
    }
    implicitHeight: (root.compact ? compactBody.implicitHeight : body.implicitHeight) + 28 * AtollStyle.density
    implicitWidth: 360 * AtollStyle.density
    PlayerBase { id: media; player: root.player; positionUpdatesActive: root.active }

    Item {
        anchors.fill: parent
        visible: root.showBackground
        Rectangle { anchors.fill: parent; radius: AtollStyle.radiusSmall; color: AtollStyle.surfaceHigh }
        Loader {
            anchors.fill: parent
            active: root.active && root.showBackground && (Config.options?.atoll?.player?.artworkBackground ?? true)
                && media.displayedArtFilePath.length > 0
            sourceComponent: AtollMediaBackdrop { source: media.displayedArtFilePath; radius: AtollStyle.radiusSmall; strength: 0.5 }
        }
    }
    ColumnLayout {
        id: body
        visible: !root.compact
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 14 * AtollStyle.density
        spacing: 12 * AtollStyle.density
        RowLayout {
            Layout.fillWidth: true
            Layout.rightMargin: root.headerReserve
            spacing: 14 * AtollStyle.density
            AtollArtwork {
                source: media.displayedArtFilePath
                appIcon: root.emptyIcon
                circular: Config.options?.atoll?.player?.roundCover ?? false
                Layout.preferredWidth: 68 * AtollStyle.density
                Layout.preferredHeight: 68 * AtollStyle.density
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: Math.round(4 * AtollStyle.density)
                AtollText { Layout.fillWidth: true; text: root.hasPlayer ? media.effectiveTitle : Translation.tr("Nothing playing"); color: root.ink; font.weight: AtollStyle.weight(Font.DemiBold); elide: Text.ElideRight }
                AtollText { Layout.fillWidth: true; text: root.hasPlayer ? media.effectiveArtist : root.emptyDetail; role: AtollText.Meta; color: !root.hasPlayer && AtollPieces.musicLaunch === "failed" && root.offersOpen ? (root.overMedia ? AtollStyle.dangerOnMedia : AtollStyle.danger) : root.inkMeta; elide: Text.ElideRight }
            }
        }
        AtollScrubber {
            id: timeline
            Layout.fillWidth: true
            Layout.bottomMargin: -8 * AtollStyle.density
            visible: root.hasTimeline
            seekable: media.effectiveCanSeek
            fillColor: root.tint
            trackColor: AtollStyle.tintFill(root.tint)
            value: media.effectiveLength > 0 ? Math.min(1, media.effectivePosition / media.effectiveLength) : 0
            onSeekRequested: next => media.seek(next * media.effectiveLength)
        }
        RowLayout {
            Layout.fillWidth: true
            visible: root.hasTimeline
            AtollText {
                text: StringUtils.friendlyTimeForSeconds(media.effectivePosition)
                color: root.inkTertiary
                font.pixelSize: AtollStyle.typeFootnote
                font.family: AtollStyle.fontNumbers
                font.features: ({ "tnum": 1 })
            }
            Item { Layout.fillWidth: true }
            AtollText {
                text: StringUtils.friendlyTimeForSeconds(media.effectiveLength)
                color: root.inkTertiary
                font.pixelSize: AtollStyle.typeFootnote
                font.family: AtollStyle.fontNumbers
                font.features: ({ "tnum": 1 })
            }
        }
        RowLayout {
            Layout.fillWidth: true
            visible: root.hasPlayer && root.liveStream
            spacing: 6 * AtollStyle.density
            Rectangle {
                implicitWidth: Math.round(7 * AtollStyle.density)
                implicitHeight: implicitWidth
                radius: width / 2
                color: root.overMedia ? AtollStyle.dangerOnMedia : AtollStyle.danger
                // Still: a pulse held its whole window at the display rate for as long as a stream played.
                opacity: media.effectiveIsPlaying ? 1 : 0.5
            }
            AtollText {
                text: Translation.tr("Live")
                color: root.inkSecondary
                font.pixelSize: AtollStyle.typeMeta
                font.weight: AtollStyle.weight(Font.DemiBold)
            }
            Item { Layout.fillWidth: true }
            AtollText {
                visible: media.effectivePosition > 0
                text: StringUtils.friendlyTimeForSeconds(media.effectivePosition)
                color: root.inkTertiary
                font.pixelSize: AtollStyle.typeFootnote
                font.family: AtollStyle.fontNumbers
                font.features: ({ "tnum": 1 })
            }
        }
        RowLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            spacing: 0
            Item { Layout.fillWidth: true }
            AtollControlPlate {
                id: transport
                controlHeight: Math.round(34 * AtollStyle.density)
                RowLayout {
                    spacing: Math.round(4 * AtollStyle.density)
                    // On the plate each takes its concentric radius, bare the row radius.
                    Repeater {
                        model: ["previous", "toggle", "next"]
                        AtollIconButton {
                            required property string modelData
                            readonly property bool toggle: modelData === "toggle"
                            buttonRadius: transport.framed ? transport.controlRadius : AtollStyle.radiusSmall
                            buttonRadiusPressed: transport.framed ? transport.controlRadius : Math.max(AtollStyle.radiusMicro, AtollStyle.radiusSmall - Math.round(2 * AtollStyle.density))
                            foreground: root.ink
                            materialIcon: toggle ? (media.effectiveIsPlaying ? "pause" : "play_arrow") : modelData === "previous" ? "skip_previous" : "skip_next"
                            iconSize: toggle ? Math.round(28 * AtollStyle.density) : Math.round(18 * AtollStyle.density)
                            Accessible.name: toggle ? (media.effectiveIsPlaying ? Translation.tr("Pause") : Translation.tr("Play"))
                                : modelData === "previous" ? Translation.tr("Previous track") : Translation.tr("Next track")
                            enabled: toggle ? root.hasPlayer : modelData === "previous" ? media.effectiveCanGoPrevious : media.effectiveCanGoNext
                            onClicked: toggle ? media.togglePlaying() : modelData === "previous" ? media.previous() : media.next()
                        }
                    }
                }
            }
            Item { Layout.fillWidth: true }
        }
        AtollPlayerChips {
            id: playerChips
            Layout.fillWidth: true
            visible: root.showPlayers && playerChips.players.length > 0
            player: root.player
            accent: root.tint
            overMedia: root.overMedia
        }
    }

    RowLayout {
        id: compactBody
        visible: root.compact
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.margins: 14 * AtollStyle.density
        spacing: 12 * AtollStyle.density
        AtollArtwork {
            source: media.displayedArtFilePath
            appIcon: root.emptyIcon
            circular: Config.options?.atoll?.player?.roundCover ?? false
            Layout.preferredWidth: 46 * AtollStyle.density
            Layout.preferredHeight: 46 * AtollStyle.density
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Math.round(2 * AtollStyle.density)
            AtollText { Layout.fillWidth: true; text: root.hasPlayer ? media.effectiveTitle : Translation.tr("Nothing playing"); color: root.ink; font.weight: AtollStyle.weight(Font.DemiBold); elide: Text.ElideRight }
            AtollText { Layout.fillWidth: true; text: root.hasPlayer ? media.effectiveArtist : root.emptyDetail; role: AtollText.Meta; color: !root.hasPlayer && AtollPieces.musicLaunch === "failed" && root.offersOpen ? (root.overMedia ? AtollStyle.dangerOnMedia : AtollStyle.danger) : root.inkMeta; elide: Text.ElideRight }
            Rectangle {
                Layout.fillWidth: true
                Layout.topMargin: 5 * AtollStyle.density
                visible: root.hasTimeline
                implicitHeight: Math.max(2, Math.round(3 * AtollStyle.density))
                radius: height / 2
                color: root.overMedia ? AtollStyle.onMediaFill : AtollStyle.fill
                Rectangle {
                    height: parent.height
                    radius: parent.radius
                    color: root.tint
                    width: parent.width * (media.effectiveLength > 0 ? Math.min(1, media.effectivePosition / media.effectiveLength) : 0)
                }
            }
        }
        // With no player the row is its empty state: three dead buttons only cut its words short.
        AtollIconButton { visible: root.hasPlayer; foreground: root.ink; materialIcon: "skip_previous"; Accessible.name: Translation.tr("Previous track"); enabled: media.effectiveCanGoPrevious; onClicked: media.previous() }
        AtollIconButton { visible: root.hasPlayer; foreground: root.ink; materialIcon: media.effectiveIsPlaying ? "pause" : "play_arrow"; Accessible.name: media.effectiveIsPlaying ? Translation.tr("Pause") : Translation.tr("Play"); onClicked: media.togglePlaying(); iconSize: Math.round(24 * AtollStyle.density) }
        AtollIconButton { visible: root.hasPlayer; foreground: root.ink; materialIcon: "skip_next"; Accessible.name: Translation.tr("Next track"); enabled: media.effectiveCanGoNext; onClicked: media.next() }
    }
}
