pragma ComponentBehavior: Bound

import QtQuick
import "../../../../services"
import "../../style"
import "../../components"

Column {
    id: root

    property real pixelSize: AtollStyle.typeBody
    property color color: AtollStyle.text
    property color accent: AtollStyle.secondaryAccent
    property bool showDay: false

    readonly property var parts: {
        const raw = String(DateTime.timeDisplay ?? "").trim()
        const period = raw.match(/\s*([^\d:.\s]+)$/)
        const pieces = (period ? raw.slice(0, period.index) : raw).split(/[:.]/)
        const hours = String(pieces[0] ?? "")
        return { hours: hours.length === 1 ? "0" + hours : hours, minutes: String(pieces[1] ?? "") }
    }

    spacing: Math.round(-root.pixelSize * 0.12)

    AtollText {
        visible: root.showDay
        anchors.horizontalCenter: parent.horizontalCenter
        bottomPadding: Math.round(root.pixelSize * 0.3)
        text: Translation.locale.toString(DateTime.clock.date, "d")
        color: root.accent
        font.pixelSize: Math.round(root.pixelSize * 0.8)
        font.family: AtollStyle.fontNumbers
        font.weight: AtollStyle.weight(Font.Bold)
        font.features: ({ "tnum": 1 })
    }
    AtollNumber {
        anchors.horizontalCenter: parent.horizontalCenter
        text: root.parts.hours
        family: AtollStyle.fontNumbers
        pixelSize: root.pixelSize
        weight: AtollStyle.figureWeight
        color: root.color
    }
    AtollNumber {
        anchors.horizontalCenter: parent.horizontalCenter
        text: root.parts.minutes
        family: AtollStyle.fontNumbers
        pixelSize: root.pixelSize
        weight: AtollStyle.figureWeight
        color: root.color
    }
}
