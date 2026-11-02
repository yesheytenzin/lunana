pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../../style"

Rectangle {
    property real value: 0.6
    property color tint: AtollStyle.fillStrong
    Layout.fillWidth: true
    implicitHeight: Math.round(6 * AtollStyle.density)
    radius: height / 2
    color: AtollStyle.fill
    Rectangle { width: parent.width * parent.value; height: parent.height; radius: height / 2; color: parent.tint }
}
