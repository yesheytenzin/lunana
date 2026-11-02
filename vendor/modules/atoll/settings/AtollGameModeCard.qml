pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../../../services"
import "../../common"
import "../../common/widgets"
import "../components"
import "../style"

Rectangle {
    id: card

    readonly property real d: AtollStyle.density
    readonly property bool on: GameMode.active
    readonly property var held: {
        Config.revision
        const game = Config.options?.gameMode ?? {}
        return [
            game.disableAnimations ?? true ? Translation.tr("animations") : "",
            game.disableEffects ?? true ? Translation.tr("blur") : "",
            game.suppressNotifications ?? true ? Translation.tr("banners") : "",
            game.disableNiriAnimations ?? true ? Translation.tr("Niri's motion") : "",
            game.disableVisualizers ?? true ? Translation.tr("visualizers") : ""
        ].filter(part => part.length > 0)
    }
    readonly property string state: GameMode.manuallyActivated ? Translation.tr("On until you turn it off")
        : GameMode.autoActivated ? Translation.tr("On while a window is fullscreen")
        : (Config.options?.gameMode?.autoDetect ?? true) ? Translation.tr("Off; it turns on by itself for fullscreen apps")
        : Translation.tr("Off")

    Layout.fillWidth: true
    implicitHeight: Math.round(96 * card.d)
    radius: AtollStyle.radiusTile
    color: card.on ? AtollStyle.tintFill(AtollStyle.identity.green) : AtollStyle.readingCard
    Behavior on color { ColorAnimation { duration: AtollStyle.duration(220); easing.type: AtollStyle.feedbackEasing } }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 18 * card.d
        anchors.rightMargin: 18 * card.d
        spacing: 16 * card.d

        AtollSquircle {
            implicitWidth: Math.round(52 * card.d)
            implicitHeight: implicitWidth
            tint: card.on ? AtollStyle.identity.green : AtollStyle.identity.purple
            glyph: "sports_esports"
            glyphShare: 0.6
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 3 * card.d
            AtollText {
                Layout.fillWidth: true
                text: Translation.tr("Game mode")
                font.family: AtollStyle.fontTitle
                font.pixelSize: AtollStyle.typeTitle
                font.weight: AtollStyle.weight(Font.DemiBold)
            }
            AtollText {
                Layout.fillWidth: true
                text: card.state
                color: AtollStyle.subtext
                font.pixelSize: AtollStyle.typeLabel
                elide: Text.ElideRight
            }
            AtollText {
                Layout.fillWidth: true
                visible: card.held.length > 0
                text: (card.on ? Translation.tr("Holding back %1") : Translation.tr("Holds back %1")).arg(card.held.join(", "))
                color: AtollStyle.muted
                font.pixelSize: AtollStyle.typeMeta
                elide: Text.ElideRight
            }
        }
        AtollButton {
            text: GameMode.manuallyActivated ? Translation.tr("Turn off") : GameMode.autoActivated ? Translation.tr("Keep it on") : Translation.tr("Turn on")
            emphasized: !GameMode.manuallyActivated
            quiet: GameMode.manuallyActivated
            buttonRadius: height / 2
            onClicked: GameMode.manuallyActivated ? GameMode.deactivate() : GameMode.activate()
        }
    }
}
