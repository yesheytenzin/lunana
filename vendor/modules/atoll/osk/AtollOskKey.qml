pragma ComponentBehavior: Bound

import QtQuick
import "../../common/functions"
import "../../onScreenKeyboard"
import "../style"

// The shared keycap (`OskKey` keeps the behaviour: ydotool, shift, caps), spoken in Atoll's fills.
OskKey {
    id: root

    readonly property real d: AtollStyle.density

    baseWidth: Math.round(44 * root.d)
    baseHeight: Math.round(44 * root.d)

    buttonRadius: AtollStyle.radiusTile
    buttonRadiusPressed: Math.max(3, AtollStyle.radiusTile - 4)
    rippleEnabled: false
    rippleDuration: AtollStyle.duration(420)
    stateTransitionsEnabled: AtollStyle.motionEnabled
    pressScaleEnabled: true
    cookieMorphing: false

    colBackground: root.shape === "empty" ? "transparent" : AtollStyle.fill
    colBackgroundHover: AtollStyle.fillHover
    colBackgroundToggled: AtollStyle.tintFill(AtollStyle.accent)
    colBackgroundToggledHover: AtollStyle.tintFillHover(AtollStyle.accent)
    colRipple: AtollStyle.fillActive
    colRippleToggled: AtollStyle.tintFillHover(AtollStyle.accent)

    colKeyText: AtollStyle.text
    colKeyTextToggled: AtollStyle.accent
    keyFontFamily: AtollStyle.fontMain
    keyFontSize: AtollStyle.typeHeadline
    fnFontSize: AtollStyle.typeMeta
    glyphFontSize: Math.round(20 * root.d)

    // A lit key (shift, caps) is a tint and a hairline of the same tint.
    Rectangle {
        anchors.fill: parent
        z: 2
        radius: root.buttonEffectiveRadius
        color: "transparent"
        border.width: root.toggled ? 1 : 0
        border.color: AtollStyle.tintBorder(AtollStyle.accent)
        visible: border.width > 0
    }
}
