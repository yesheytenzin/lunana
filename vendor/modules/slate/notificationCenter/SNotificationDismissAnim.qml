import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../common"
import "../../common/widgets"
import "../../common/functions"
import "../looks"

SequentialAnimation {
    id: root

    required property var target

    PropertyAction {
        target: root.target
        property: "ListView.delayRemove"
        value: true
    }
    NumberAnimation {
        target: root.target
        property: "x"
        to: root.target.width
        duration: Looks.transition.enabled ? Looks.transition.duration.panel : 0
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Looks.transition.easing.bezierCurve.easeIn
    }
    PropertyAction {
        target: root.target
        property: "ListView.delayRemove"
        value: false
    }
}
