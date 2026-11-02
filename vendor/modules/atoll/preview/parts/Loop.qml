pragma ComponentBehavior: Bound

import QtQuick
import "../../style"

SequentialAnimation {
    id: loop
    property real rest: 1400
    loops: Animation.Infinite
    NumberAnimation { to: 1; duration: AtollStyle.duration(AtollStyle.settleDuration * 2); easing.type: Easing.BezierSpline; easing.bezierCurve: AtollStyle.emergeCurve }
    PauseAnimation { duration: loop.rest }
    NumberAnimation { to: 0; duration: AtollStyle.duration(AtollStyle.recedeDuration * 2); easing.type: Easing.BezierSpline; easing.bezierCurve: AtollStyle.recedeCurve }
    PauseAnimation { duration: loop.rest / 3 }
}
