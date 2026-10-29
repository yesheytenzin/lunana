import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import "../../.."
import "../../../services"
import "../../../services/network"
import "../../common"
import "../../common/functions"
import "../../common/widgets"
import "../looks"
import "."

WChoiceButton {
    id: root

    property bool expanded: false
    checked: expanded
    clip: true

    horizontalPadding: 12
    verticalPadding: 6
    animateChoiceHighlight: false

    Behavior on implicitHeight {
        animation: NumberAnimation { duration: Looks.transition.enabled ? Looks.transition.duration.medium : 0; easing.type: Easing.BezierSpline; easing.bezierCurve: Looks.transition.easing.bezierCurve.standard }
    }
    onClicked: expanded = !expanded
}
