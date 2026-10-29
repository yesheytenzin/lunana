pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import Quickshell
import "../../../services"
import "../../common"
import "../../common/functions"
import "."

Rectangle {
    id: root

    required property var target
    z: 0

    anchors {
        fill: target
        margins: -border.width
    }

    border.color: Looks.colors.ambientShadow
    border.width: 1
    color: "transparent"
    radius: target.radius + border.width
}
