pragma ComponentBehavior: Bound

import QtQuick
import "../../common"
import "../../common/widgets"
import "../style"

Rectangle {
    id: root

    property color tint: AtollStyle.identity.gray
    property string glyph: "settings"
    property real glyphShare: 0.64

    // The icon pack: "atoll" is the family's tinted squircle. "tile" is the app-icon look,
    // a plate the user can colour, with the glyph in a gradient of its own colour.
    readonly property bool tiled: String(Config.options?.atoll?.appearance?.icons?.style ?? "atoll") === "tile"
    readonly property string plate: String(Config.options?.atoll?.appearance?.icons?.plate ?? "black")
    readonly property color tileTop: root.plate === "white" ? AtollStyle.plateWhiteTop
        : root.plate === "tint" ? AtollStyle.tileTop(root.tint)
        : root.plate === "surface" ? Qt.lighter(AtollStyle.surfaceHighestOpaque, 1.7)
        : AtollStyle.plateBlackTop
    readonly property color tileBase: root.plate === "white" ? AtollStyle.plateWhiteBase
        : root.plate === "tint" ? root.tint
        : root.plate === "surface" ? AtollStyle.surfaceHighestOpaque
        : AtollStyle.plateBlackBase

    radius: AtollStyle.iconRadius(width)
    gradient: Gradient {
        GradientStop { position: 0; color: root.tiled ? root.tileTop : AtollStyle.tileTop(root.tint) }
        GradientStop { position: 1; color: root.tiled ? root.tileBase : root.tint }
    }
    MaterialSymbol {
        anchors.centerIn: parent
        text: root.glyph
        fill: 1
        iconSize: Math.round(root.width * root.glyphShare)
        color: root.tiled && root.plate !== "tint" ? root.tint : AtollStyle.onTint
        glyphGradient: root.tiled
    }
}
