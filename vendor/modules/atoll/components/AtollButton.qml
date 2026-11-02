pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../../common/functions"
import "../../common/widgets"
import "../style"

RippleButton {
    id: root

    default property alias contentData: customContent.data
    property bool selected: false
    property bool quiet: false
    property bool emphasized: false
    property bool danger: false
    property color foreground: root.danger && root.emphasized ? AtollStyle.inkOnDanger
        : root.emphasized ? AtollStyle.inkOnAccent
        : root.danger ? AtollStyle.danger
        : root.selected ? AtollStyle.accent : AtollStyle.text

    implicitWidth: Math.max(34 * AtollStyle.density,
        root.text.length > 0 ? label.implicitWidth + 22 * AtollStyle.density : 34 * AtollStyle.density)
    implicitHeight: Math.max(34 * AtollStyle.density,
        root.text.length > 0 ? label.implicitHeight + 12 * AtollStyle.density : 34 * AtollStyle.density)
    Layout.minimumHeight: root.text.length > 0 ? label.implicitHeight + 10 * AtollStyle.density : 0

    toggled: root.selected
    buttonRadius: AtollStyle.radiusSmall
    buttonRadiusPressed: Math.max(3, AtollStyle.radiusSmall - 2)
    rippleEnabled: false
    rippleDuration: AtollStyle.duration(420)
    stateTransitionsEnabled: AtollStyle.motionEnabled
    pressScaleEnabled: true
    cookieMorphing: false

    colBackground: root.danger && root.emphasized ? AtollStyle.danger
        : root.emphasized ? AtollStyle.accent
        : root.quiet ? ColorUtils.applyAlpha(AtollStyle.surfaceHigh, 0)
        : AtollStyle.controlPlated ? AtollStyle.plateFillFor(AtollStyle.controlPlate)
        : AtollStyle.surfaceHigh
    colBackgroundHover: root.danger && root.emphasized
        ? ColorUtils.mix(AtollStyle.danger, AtollStyle.inkOnDanger, 0.90)
        : root.danger
            ? AtollStyle.tintFill(AtollStyle.danger)
        : root.emphasized
            ? AtollStyle.accentHover
            : root.quiet
                ? AtollStyle.fillHover
            : AtollStyle.surfaceHighest
    colBackgroundToggled: AtollStyle.tintFill(AtollStyle.accent)
    colBackgroundToggledHover: AtollStyle.tintFillHover(AtollStyle.accent)
    colRipple: AtollStyle.tintFill((root.danger ? AtollStyle.danger : AtollStyle.accent))
    colRippleToggled: AtollStyle.tintFill(AtollStyle.accent)

    Accessible.name: root.text
    Accessible.role: Accessible.Button
    Accessible.checked: root.selected

    Rectangle {
        anchors.fill: parent
        z: 2
        radius: root.buttonEffectiveRadius
        color: "transparent"
        border.width: root.visualFocus ? 2 : 0
        border.color: AtollStyle.accent
        visible: border.width > 0
        Behavior on border.color {
            enabled: AtollStyle.motionEnabled
            ColorAnimation { duration: AtollStyle.duration(140) }
        }
    }

    contentItem: Item {
        id: contentHost

        AtollText {
            id: label
            anchors.centerIn: parent
            width: Math.min(implicitWidth, Math.max(0, contentHost.width - 16 * AtollStyle.density))
            elide: Text.ElideRight
            visible: root.text.length > 0
            text: root.text
            color: root.foreground
            font.pixelSize: AtollStyle.typeLabel
            font.weight: root.emphasized || root.selected ? Font.DemiBold : Font.Medium
            horizontalAlignment: Text.AlignHCenter
        }

        Item {
            id: customContent
            anchors.fill: parent
        }
    }
}
