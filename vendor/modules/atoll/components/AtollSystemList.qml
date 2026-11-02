pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower
import "../../.."
import "../../../services"
import "../../common"
import "../../common/models/quickToggles"
import "../../common/widgets"
import "../style"

// The Control Center's System expansion: quiet, play, stay awake and how hard the machine runs.
ColumnLayout {
    id: root

    readonly property real d: AtollStyle.density
    spacing: 2 * root.d

    NotificationToggle { id: focus }
    GameModeToggle { id: game }
    IdleInhibitorToggle { id: awake }

    AtollControlRow {
        glyph: "do_not_disturb_on"
        label: Translation.tr("Do Not Disturb")
        detail: focus.toggled ? Translation.tr("Banners wait in Today") : Translation.tr("Banners come in")
        on: focus.toggled
        tint: AtollStyle.identity.indigo
        onToggled: focus.mainAction()
    }
    AtollControlRow {
        glyph: "sports_esports"
        label: Translation.tr("Game mode")
        detail: Translation.tr("The shell steps back while you play")
        on: game.toggled
        available: game.available
        tint: AtollStyle.identity.green
        onToggled: game.mainAction()
    }
    AtollControlRow {
        glyph: "coffee"
        label: Translation.tr("Stay awake")
        detail: Translation.tr("The screen never sleeps on its own")
        on: awake.toggled
        tint: AtollStyle.identity.orange
        onToggled: awake.mainAction()
    }
    RowLayout {
        visible: PowerProfiles.profile !== undefined
        Layout.fillWidth: true
        Layout.leftMargin: 10 * root.d
        Layout.rightMargin: 6 * root.d
        Layout.topMargin: 4 * root.d
        implicitHeight: Math.round(44 * root.d)
        spacing: 10 * root.d
        MaterialSymbol {
            Layout.preferredWidth: Math.round(28 * root.d)
            horizontalAlignment: Text.AlignHCenter
            text: "bolt"
            iconSize: Math.round(18 * root.d)
            color: AtollStyle.subtext
        }
        AtollSegmented {
            Layout.fillWidth: true
            accessibleName: Translation.tr("Power profile")
            options: [{ value: PowerProfile.PowerSaver, label: Translation.tr("Saver") },
                { value: PowerProfile.Balanced, label: Translation.tr("Balanced") }]
                .concat(PowerProfiles.hasPerformanceProfile ? [{ value: PowerProfile.Performance, label: Translation.tr("Performance") }] : [])
            current: PowerProfiles.profile
            onPicked: value => PowerProfiles.profile = value
        }
    }
}
