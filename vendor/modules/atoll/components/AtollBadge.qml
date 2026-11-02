pragma ComponentBehavior: Bound

import QtQuick
import "../style"

Rectangle {
    id: root

    property int count: 0
    property real size: Math.round(17 * AtollStyle.density)

    visible: root.count > 0
    height: root.size
    width: Math.max(root.size, label.implicitWidth + root.size * 0.7)
    radius: height / 2
    color: AtollStyle.badge
    border.width: Math.max(1, root.size * 0.07)
    border.color: AtollStyle.bodySurface

    AtollText {
        id: label
        anchors.centerIn: parent
        anchors.verticalCenterOffset: Math.round(root.size * 0.03)
        text: root.count > 99 ? "99+" : root.count
        color: AtollStyle.inkOnBadge
        font.family: AtollStyle.fontNumbers
        font.features: ({ "tnum": 1 })
        font.pixelSize: root.size * 0.62
        font.weight: AtollStyle.weight(Font.Bold)
    }
}
