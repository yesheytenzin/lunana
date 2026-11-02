pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../../.."
import "../../common"
import "../../common/functions"
import "../../common/widgets"
import "../../atoll/style"

IconToolbarButton {
    id: root
    property string iconName: ""
    property string label: ""
    property string tooltip: label
    property string tooltipPosition: "bottom"
    property bool compact: false
    property bool primary: false
    // In Atoll: a button with a quiet plate of its own (Add widgets), or one that sits inside a quiet pill (the tools).
    property bool plate: false
    property bool inPill: false
    // The +/- that appears over a tile on hover; search results act on the widget instead.
    property bool badge: true
    readonly property bool showLabel: !compact && label.length > 0
    // Atoll draws edit controls in the Island's material: quiet translucent
    // states on black, the accent reserved for the one committing action.
    readonly property bool atoll: (Config.options?.panelFamily ?? "drift") === "atoll"
    // Atoll widget rail: each widget is an app-icon-shaped tile in its category
    // tint, lit when the widget is on; the fill carries the state, nothing else does.
    property color tileTint: "transparent"
    readonly property bool atollTile: root.atoll && root.tileTint.a > 0
    readonly property real d: root.atoll ? AtollStyle.density : 1
    // Buttons keep their own height in Atoll: the base fills the row, which made "Done" as tall as the bar.
    Layout.fillHeight: !root.atoll
    Layout.alignment: Qt.AlignVCenter
    implicitWidth: root.atollTile ? Math.round(30 * root.d) : showLabel ? Math.ceil(labelMetrics.width) + iconSize + 34 : implicitHeight
    implicitHeight: root.atollTile ? Math.round(38 * root.d) : Math.round((root.inPill ? 30 : 38) * root.d)
    iconSize: Math.round(18 * root.d)
    width: implicitWidth
    height: implicitHeight
    toggled: primary
    opacity: enabled ? 1 : 0.38

    // Do not bind a property to itself for the non-Atoll branch. These temporary
    // overrides preserve the inherited Material/Slate bindings and restore them
    // if the family changes without rebuilding the component.
    Binding { target: root; property: "buttonRadius"; value: root.height / 2; when: root.atoll; restoreMode: Binding.RestoreBinding }
    Binding {
        target: root; property: "colBackground"; when: root.atoll; restoreMode: Binding.RestoreBinding
        value: root.plate ? AtollStyle.fillQuiet : "transparent"
    }
    Binding {
        target: root; property: "colBackgroundHover"; when: root.atoll; restoreMode: Binding.RestoreBinding
        value: root.atollTile ? "transparent" : AtollStyle.fillHover
    }
    Binding {
        target: root; property: "colBackgroundToggled"; when: root.atoll; restoreMode: Binding.RestoreBinding
        value: root.atollTile ? "transparent" : root.primary ? AtollStyle.accent : AtollStyle.fillActive
    }
    Binding {
        target: root; property: "colBackgroundToggledHover"; when: root.atoll; restoreMode: Binding.RestoreBinding
        value: root.atollTile ? "transparent" : root.primary ? Qt.lighter(AtollStyle.accent, 1.08) : AtollStyle.fillActive
    }
    Binding {
        target: root; property: "colText"; when: root.atoll; restoreMode: Binding.RestoreBinding
        value: root.primary ? AtollStyle.inkOnAccent : root.toggled ? AtollStyle.text : AtollStyle.subtext
    }

    TextMetrics {
        id: labelMetrics
        text: root.label
        font.family: root.atoll ? AtollStyle.fontMain : Appearance.font.family.main
        font.pixelSize: Appearance.font.pixelSize.smaller
        font.weight: Appearance.editorialEverywhere ? Appearance.editorial.labelWeight : Font.Medium
    }
    contentItem: Item {
        clip: !root.atollTile

        Rectangle {
            id: tile
            visible: root.atollTile
            anchors.centerIn: parent
            width: Math.round(30 * root.d)
            height: width
            radius: Math.round(width * 0.26)
            scale: root.down ? 0.92 : root.buttonHovered ? 1.06 : 1
            Behavior on scale { NumberAnimation { duration: AtollStyle.duration(120); easing.type: AtollStyle.feedbackEasing } }
            color: root.toggled ? AtollStyle.containerOf(root.tileTint) : root.buttonHovered ? AtollStyle.fillHover : AtollStyle.fill
            Behavior on color { ColorAnimation { duration: AtollStyle.duration(140) } }
            MaterialSymbol {
                anchors.centerIn: parent
                text: root.iconName
                fill: root.toggled ? 1 : 0
                iconSize: Math.round(17 * root.d)
                color: root.toggled ? AtollStyle.onContainerOf(root.tileTint) : ColorUtils.applyAlpha(root.tileTint, root.buttonHovered ? 1 : 0.78)
            }
            Rectangle {
                x: parent.width - width * 0.7
                y: -height * 0.3
                width: 13
                height: 13
                radius: width / 2
                color: root.toggled ? AtollStyle.danger : AtollStyle.accent
                border.width: 1.5
                border.color: AtollStyle.surface
                opacity: root.badge && root.buttonHovered ? 1 : 0
                scale: opacity > 0 ? 1 : 0.6
                Behavior on opacity { NumberAnimation { duration: AtollStyle.duration(120) } }
                Behavior on scale { NumberAnimation { duration: AtollStyle.duration(120); easing.type: AtollStyle.feedbackEasing } }
                MaterialSymbol {
                    anchors.centerIn: parent
                    text: root.toggled ? "remove" : "add"
                    iconSize: 11
                    color: AtollStyle.onTint
                }
            }
        }
        Row {
            visible: !root.atollTile
            anchors.centerIn: parent
            spacing: root.showLabel ? 6 : 0
            MaterialSymbol {
                width: root.iconSize
                height: root.iconSize
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: root.iconName
                iconSize: root.iconSize
                color: root.colText
            }
            StyledText {
                visible: root.showLabel
                width: Math.ceil(labelMetrics.width)
                horizontalAlignment: Text.AlignHCenter
                text: root.label
                font.family: root.atoll ? AtollStyle.fontMain : Appearance.font.family.main
                font.pixelSize: Appearance.font.pixelSize.smaller
                font.weight: Appearance.editorialEverywhere ? Appearance.editorial.labelWeight : Font.Medium
                color: root.colText
            }
        }
    }
    StyledToolTip { text: root.tooltip; position: root.tooltipPosition }
}
