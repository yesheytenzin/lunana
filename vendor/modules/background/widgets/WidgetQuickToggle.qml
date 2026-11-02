pragma ComponentBehavior: Bound

import QtQuick
import "../../.."
import "../../common"
import "../../common/functions"
import "../../common/widgets"
import "../../atoll/style"
import "../../atoll/components"

// An on/off option in a widget's quick controls: a row with its glyph, its name and a switch. The
// whole row toggles. A choice between values is WidgetQuickChoices, never a lit capsule.
Rectangle {
    id: root

    property string iconName: ""
    property string label: ""
    property bool checked: false
    signal toggled()

    readonly property bool atoll: (Config.options?.panelFamily ?? "drift") === "atoll"
    readonly property real d: root.atoll ? AtollStyle.density : 1

    opacity: root.enabled ? 1 : 0.45
    implicitWidth: Math.round(200 * root.d)
    implicitHeight: Math.round(38 * root.d)
    radius: root.atoll ? AtollStyle.radiusRow
        : Appearance.zzzEverywhere ? Appearance.zzz.controlRadius
        : Appearance.regaliaEverywhere ? Appearance.regalia.controlRadius
        : Appearance.rounding.small
    color: root.atoll ? (hover.hovered ? AtollStyle.fillHover : AtollStyle.fillQuiet)
        : ColorUtils.applyAlpha(Appearance.colors.colOnLayer2, hover.hovered ? 0.09 : 0.045)
    Behavior on color {
        enabled: root.atoll ? AtollStyle.motionEnabled : Appearance.animationsEnabled
        ColorAnimation { duration: root.atoll ? AtollStyle.feedbackDuration : Appearance.animation.elementMoveFast.duration }
    }

    MaterialSymbol {
        id: glyph
        visible: root.iconName.length > 0
        anchors.left: parent.left
        anchors.leftMargin: Math.round(11 * root.d)
        anchors.verticalCenter: parent.verticalCenter
        text: root.iconName
        fill: root.checked ? 1 : 0
        iconSize: Math.round(17 * root.d)
        color: root.atoll ? (root.checked ? AtollStyle.text : AtollStyle.textSecondary)
            : root.checked ? Appearance.colors.colOnLayer2 : Appearance.colors.colSubtext
    }
    StyledText {
        anchors.left: glyph.visible ? glyph.right : parent.left
        anchors.leftMargin: Math.round((glyph.visible ? 9 : 12) * root.d)
        anchors.right: switchSlot.left
        anchors.rightMargin: Math.round(8 * root.d)
        anchors.verticalCenter: parent.verticalCenter
        text: root.label
        elide: Text.ElideRight
        color: root.atoll ? AtollStyle.text : Appearance.colors.colOnLayer2
        font.family: root.atoll ? AtollStyle.fontMain : Appearance.font.family.main
        font.pixelSize: root.atoll ? AtollStyle.typeLabel : Appearance.font.pixelSize.smaller
    }

    HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
    Item {
        anchors.left: parent.left
        anchors.right: switchSlot.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        TapHandler { gesturePolicy: TapHandler.WithinBounds; onTapped: answer.restart() }
    }

    Item {
        id: switchSlot
        anchors.right: parent.right
        anchors.rightMargin: Math.round(9 * root.d)
        anchors.verticalCenter: parent.verticalCenter
        width: root.atoll ? atollSwitch.width : materialSwitch.width
        height: root.atoll ? atollSwitch.height : materialSwitch.height

        AtollSwitch {
            id: atollSwitch
            visible: root.atoll
            anchors.centerIn: parent
            on: root.checked
            name: root.label
            onToggled: answer.restart()
        }
        StyledSwitch {
            id: materialSwitch
            visible: !root.atoll
            anchors.centerIn: parent
            checked: root.checked
            onClicked: {
                answer.restart()
                materialSwitch.checked = Qt.binding(() => root.checked)
            }
        }
    }

    // Answered after the tap returns, so a row rebuilt by its own change never dies inside the click.
    Timer { id: answer; interval: 0; onTriggered: root.toggled() }

    Accessible.role: Accessible.CheckBox
    Accessible.name: root.label
    Accessible.checked: root.checked
}
