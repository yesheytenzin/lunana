pragma ComponentBehavior: Bound

import QtQuick
import "../../../../services"
import "../../../common"
import "../../../common/widgets"
import "../../style"
import "../../components"

Row {
    id: dateMark
    property real pixelSize: AtollStyle.typeMeta
    property color dayColor: AtollStyle.secondaryAccent
    property color inkColor: AtollStyle.muted
    spacing: Math.round(dateMark.pixelSize * 0.3)
    AtollText {
        id: weekdayText
        text: Translation.locale.toString(DateTime.clock.date, "ddd").replace(/\.$/, "")
        color: dateMark.inkColor
        font.pixelSize: dateMark.pixelSize * 0.92
        font.weight: AtollStyle.weight(Font.Medium)
    }
    AtollText {
        anchors.baseline: weekdayText.baseline
        text: Translation.locale.toString(DateTime.clock.date, "d")
        color: dateMark.dayColor
        font.pixelSize: dateMark.pixelSize
        font.family: AtollStyle.fontNumbers
        font.weight: AtollStyle.weight(Font.Bold)
        font.features: ({ "tnum": 1 })
    }
}
