pragma ComponentBehavior: Bound

import QtQuick
import "../../.."
import "../../common"
import "../../common/widgets"
import "../../atoll/style"

// A widget's mark at the head of its quick controls. Atoll: the category-tint squircle with a white
// glyph (its identity grammar); the drift family: the Global Style's tonal container.
Rectangle {
    id: root

    property string glyph: "widgets"
    property color tint: AtollStyle.accent

    readonly property bool atoll: (Config.options?.panelFamily ?? "drift") === "atoll"
    readonly property real d: root.atoll ? AtollStyle.density : 1

    implicitWidth: Math.round(28 * root.d)
    implicitHeight: implicitWidth
    radius: root.atoll ? AtollStyle.iconRadius(width) : Appearance.rounding.small
    color: root.atoll ? root.tint : Appearance.colors.colSecondaryContainer
    gradient: root.atoll ? tintGradient : null

    Gradient {
        id: tintGradient
        GradientStop { position: 0; color: Qt.lighter(root.tint, 1.18) }
        GradientStop { position: 1; color: root.tint }
    }

    MaterialSymbol {
        anchors.centerIn: parent
        text: root.glyph
        fill: 1
        iconSize: Math.round(17 * root.d)
        color: root.atoll ? AtollStyle.onTint : Appearance.colors.colOnSecondaryContainer
    }
}
