pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import "../../.."
import "../../../services"
import "../../common"
import "../../common/functions"
import "../../common/widgets"
import "../style"
import "../components"

ColumnLayout {
    id: root
    readonly property real d: AtollStyle.density
    signal activityRequested()
    spacing: 12 * root.d

    property var presets: {
        const saved = Persistent.states?.timer?.countdown?.presets ?? []
        return [0, 1, 2].map(i => Math.max(1, Math.min(180, Number(saved[i] ?? [5, 15, 30][i]))))
    }
    function adjustPreset(index: int, steps: int): void {
        const next = root.presets.slice()
        let value = next[index]
        for (let i = 0; i < Math.abs(steps); i++) {
            if (steps > 0) value = value < 10 ? value + 1 : value + 5 - value % 5
            else value = value <= 10 ? value - 1 : value - (value % 5 || 5)
        }
        next[index] = Math.max(1, Math.min(180, value))
        root.presets = next
    }
    function savePresets(): void {
        if (Persistent.states?.timer?.countdown) Persistent.states.timer.countdown.presets = root.presets.slice()
    }

    component Dial: Item {
        id: dial
        property string figure: ""
        property string glyph: ""
        property string caption: ""
        property bool running: false
        property real share: 0
        property bool adjustable: false
        signal clicked()
        signal adjusted(int steps)
        signal adjustFinished()
        Layout.fillWidth: true
        Layout.preferredWidth: 1
        implicitHeight: face.height + label.implicitHeight + 6 * root.d
        opacity: dial.enabled ? 1 : 0.45
        Accessible.role: Accessible.Button
        Accessible.name: dial.caption

        AtollButton {
            id: face
            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.round(56 * root.d)
            height: width
            buttonRadius: width / 2
            buttonRadiusPressed: width / 2
            colBackground: dial.running ? AtollStyle.tintFill(AtollStyle.secondaryAccent) : AtollStyle.fillQuiet
            colBackgroundHover: dial.running ? AtollStyle.tintFillHover(AtollStyle.secondaryAccent) : AtollStyle.fillHover
            onClicked: dial.clicked()
            scale: presetPointer.pressed && !presetPointer.dragging ? AtollStyle.pressScale(0.94) : 1
            Behavior on scale { NumberAnimation { duration: AtollStyle.duration(110); easing.type: AtollStyle.feedbackEasing } }

            Shape {
                id: arc
                anchors.fill: parent
                anchors.margins: 3 * root.d
                preferredRendererType: Shape.CurveRenderer
                readonly property real stroke: Math.max(2, 2.5 * root.d)
                ShapePath {
                    strokeColor: AtollStyle.tintFill(AtollStyle.secondaryAccent)
                    strokeWidth: arc.stroke
                    fillColor: "transparent"
                    PathAngleArc {
                        centerX: arc.width / 2; centerY: arc.height / 2
                        radiusX: arc.width / 2 - arc.stroke / 2; radiusY: arc.width / 2 - arc.stroke / 2
                        startAngle: 0; sweepAngle: 360
                    }
                }
                ShapePath {
                    strokeColor: AtollStyle.secondaryAccent
                    strokeWidth: arc.stroke
                    fillColor: "transparent"
                    capStyle: ShapePath.RoundCap
                    PathAngleArc {
                        centerX: arc.width / 2; centerY: arc.height / 2
                        radiusX: arc.width / 2 - arc.stroke / 2; radiusY: arc.width / 2 - arc.stroke / 2
                        startAngle: -90
                        sweepAngle: 360 * (dial.running ? 1 : dial.share)
                    }
                }
            }
            AtollText {
                anchors.centerIn: parent
                visible: dial.figure.length > 0
                text: dial.figure
                color: AtollStyle.secondaryAccent
                font.family: AtollStyle.fontNumbers
                font.pixelSize: 19 * AtollStyle.typeScale
                font.weight: AtollStyle.weight(Font.Bold)
                font.features: ({ "tnum": 1 })
            }
            MaterialSymbol {
                anchors.centerIn: parent
                visible: dial.glyph.length > 0
                text: dial.glyph
                fill: dial.running ? 1 : 0
                iconSize: 22 * root.d
                color: AtollStyle.secondaryAccent
            }
        }
        MouseArea {
            id: presetPointer
            anchors.fill: face
            enabled: dial.adjustable && dial.enabled
            cursorShape: Qt.PointingHandCursor
            preventStealing: true
            hoverEnabled: true
            property real anchorY: 0
            property bool dragging: false
            onPressed: mouse => { anchorY = mouse.y; dragging = false }
            onPositionChanged: mouse => {
                wheelIntent.track(mouse.x, mouse.y)
                if (!pressed) return
                const step = 8 * root.d
                if (!dragging && Math.abs(anchorY - mouse.y) < step) return
                dragging = true
                const steps = Math.trunc((anchorY - mouse.y) / step)
                if (steps === 0) return
                anchorY -= steps * step
                dial.adjusted(steps)
            }
            onReleased: {
                if (dragging) dial.adjustFinished()
                else dial.clicked()
                dragging = false
            }
            onCanceled: { if (dragging) dial.adjustFinished(); dragging = false }
            property real wheelAccumulator: 0
            AtollWheelIntent { id: wheelIntent; hovered: presetPointer.containsMouse }
            onWheel: wheel => {
                if (!wheelIntent.take(wheel)) return
                wheelAccumulator += wheel.angleDelta.y || wheel.pixelDelta.y * 4
                const steps = Math.trunc(wheelAccumulator / 120)
                if (steps === 0) return
                wheelAccumulator -= steps * 120
                dial.adjusted(steps)
                dial.adjustFinished()
            }
        }
        AtollText {
            id: label
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            text: dial.caption
            color: AtollStyle.textSecondary
            font.pixelSize: AtollStyle.typeFootnote
            font.weight: AtollStyle.weight(Font.Medium)
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 6 * root.d
        Repeater {
            model: 3
            Dial {
                id: preset
                required property int index
                readonly property int minutes: root.presets[preset.index] ?? 5
                figure: String(preset.minutes)
                caption: Translation.tr("min")
                share: Math.min(1, preset.minutes / 60)
                adjustable: true
                enabled: !TimerService.countdownRunning
                onAdjusted: steps => root.adjustPreset(preset.index, steps)
                onAdjustFinished: root.savePresets()
                onClicked: {
                    TimerService.setCountdownDuration(preset.minutes * 60)
                    TimerService.toggleCountdown()
                    root.activityRequested()
                }
            }
        }
        Dial {
            glyph: "self_improvement"
            caption: Translation.tr("Focus")
            running: TimerService.pomodoroRunning
            onClicked: {
                if (!TimerService.pomodoroRunning) TimerService.togglePomodoro()
                root.activityRequested()
            }
        }
        Dial {
            glyph: "timer"
            caption: Translation.tr("Stopwatch")
            running: TimerService.stopwatchRunning
            onClicked: {
                if (!TimerService.stopwatchRunning) TimerService.toggleStopwatch()
                root.activityRequested()
            }
        }
    }

    ColumnLayout {
        id: custom
        property bool open: false
        property int hours: 0
        property int minutes: 5
        property int seconds: 0
        readonly property int total: custom.hours * 3600 + custom.minutes * 60 + custom.seconds * 5
        Layout.fillWidth: true
        spacing: 10 * root.d
        onOpenChanged: {
            if (!custom.open) return
            const duration = TimerService.countdownDuration
            custom.hours = Math.floor(duration / 3600) % 24
            custom.minutes = Math.floor(duration / 60) % 60
            custom.seconds = Math.floor((duration % 60) / 5)
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 8 * root.d
            AtollButton {
                quiet: !custom.open
                enabled: !TimerService.countdownRunning
                text: custom.open ? Translation.tr("Cancel") : Translation.tr("Set a time")
                implicitHeight: Math.round(30 * root.d)
                buttonRadius: height / 2
                buttonRadiusPressed: height / 2
                onClicked: custom.open = !custom.open
            }
            AtollButton {
                visible: custom.open
                emphasized: true
                enabled: custom.total >= 5
                text: Translation.tr("Start")
                implicitHeight: Math.round(30 * root.d)
                buttonRadius: height / 2
                buttonRadiusPressed: height / 2
                onClicked: {
                    TimerService.setCountdownDuration(custom.total)
                    TimerService.toggleCountdown()
                    custom.open = false
                    root.activityRequested()
                }
            }
        }

        Item {
            Layout.fillWidth: true
            implicitHeight: custom.open ? picker.implicitHeight : 0
            clip: true
            opacity: custom.open ? 1 : 0
            Behavior on implicitHeight { NumberAnimation { duration: AtollStyle.morphDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: AtollStyle.morphCurve } }
            Behavior on opacity { NumberAnimation { duration: AtollStyle.duration(140); easing.type: AtollStyle.feedbackEasing } }
            AtollWheelPicker {
                id: picker
                anchors.horizontalCenter: parent.horizontalCenter
                separator: ""
                columns: [{ count: 24, unit: Translation.tr("h") }, { count: 60, unit: Translation.tr("min") }, { count: 12, step: 5, unit: Translation.tr("s") }]
                values: [custom.hours, custom.minutes, custom.seconds]
                onMoved: (column, index) => column === 0 ? custom.hours = index : column === 1 ? custom.minutes = index : custom.seconds = index
            }
        }
    }
}
