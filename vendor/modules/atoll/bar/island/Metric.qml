pragma ComponentBehavior: Bound

import QtQuick
import "../../../../services"
import "../../../common"
import "../../../common/widgets"
import "../../style"
import "../../components"

Row {
    id: metric
    property string value: ""
    property string unit: ""
    property real pixelSize: AtollStyle.typeHeadline
    property int weight: Font.DemiBold
    property color color: AtollStyle.text
    AtollText {
        id: metricValue
        text: metric.value
        color: metric.color
        font.pixelSize: metric.pixelSize
        font.family: AtollStyle.fontNumbers
        font.weight: metric.weight
        font.features: ({ "tnum": 1 })
        font.letterSpacing: Math.round(-metric.pixelSize * 0.015)
    }
    AtollText {
        visible: metric.unit.length > 0
        anchors.baseline: metricValue.baseline
        leftPadding: metric.pixelSize * 0.06
        text: metric.unit
        color: AtollStyle.secondaryOf(metric.color)
        font.pixelSize: Math.max(9, metric.pixelSize * 0.6)
        font.weight: AtollStyle.weight(Font.DemiBold)
    }
}
