pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import "../../../services"
import "../../common"
import "../../common/widgets"
import "../style"

Flow {
    id: root
    property var player: MprisController.activePlayer
    readonly property var players: (MprisController.displayPlayers ?? []).filter(p => p && p !== root.player)
    property color accent: AtollStyle.accent
    property bool overMedia: false
    visible: root.players.length > 0
    spacing: 6 * AtollStyle.density

    Repeater {
        model: root.players
        AtollButton {
            id: chip
            required property var modelData
            implicitHeight: Math.round(32 * AtollStyle.density)
            implicitWidth: chipRow.implicitWidth + Math.round(20 * AtollStyle.density)
            buttonRadius: height / 2
            buttonRadiusPressed: height / 2
            colBackground: root.overMedia ? AtollStyle.onMediaFill : AtollStyle.fillQuiet
            colBackgroundHover: root.overMedia ? AtollStyle.onMediaFillHover : AtollStyle.fillHover
            Accessible.name: Translation.tr("Control %1").arg(chip.modelData?.identity ?? "")
            onClicked: MprisController.setActivePlayer(chip.modelData)
            RowLayout {
                id: chipRow
                anchors.centerIn: parent
                spacing: 6 * AtollStyle.density
                AtollArtwork {
                    circular: true
                    Layout.preferredWidth: Math.round(20 * AtollStyle.density)
                    Layout.preferredHeight: Layout.preferredWidth
                    source: String(MprisController.artUrlOf(chip.modelData) ?? "")
                }
                AtollText {
                    text: String(MprisController.titleOf(chip.modelData) || chip.modelData?.identity || "")
                    color: root.overMedia ? AtollStyle.onMedia : AtollStyle.text
                    font.pixelSize: AtollStyle.typeMeta
                    font.weight: AtollStyle.weight(Font.Medium)
                    elide: Text.ElideRight
                    Layout.maximumWidth: Math.round(150 * AtollStyle.density)
                }
                MaterialSymbol {
                    fill: 1
                    text: chip.modelData?.isPlaying ? "graphic_eq" : "pause"
                    iconSize: 14 * AtollStyle.density
                    color: chip.modelData?.isPlaying ? root.accent : (root.overMedia ? AtollStyle.onMediaTertiary : AtollStyle.muted)
                }
            }
        }
    }
}
