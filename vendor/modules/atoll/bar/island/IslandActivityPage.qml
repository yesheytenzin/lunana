pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Dialogs
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import "../../../.."
import "../../../../services"
import "../../../common"
import "../../../common/functions"
import "../../../common/widgets"
import "../../../mediaControls/components"
import "../../style"
import "../../components"
import "../../frame"
import "../../pieces"

ColumnLayout {
    id: page
    required property Item island
    spacing: 12 * AtollStyle.density

    RowLayout {
        Layout.fillWidth: true
        visible: page.island.recording
        spacing: 12 * AtollStyle.density
        Item {
            Layout.preferredWidth: 40 * AtollStyle.density
            Layout.preferredHeight: 40 * AtollStyle.density
            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: AtollStyle.tintFill(AtollStyle.danger)
            }
            RecordDot { anchors.centerIn: parent; width: 14 * AtollStyle.density; height: width }
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1
            AtollText {
                Layout.fillWidth: true
                elide: Text.ElideRight
                text: Translation.tr("Screen recording")
                font.pixelSize: AtollStyle.typeBody
                font.weight: AtollStyle.weight(Font.DemiBold)
            }
            AtollText {
                Layout.fillWidth: true
                elide: Text.ElideRight
                text: RecorderStatus.effectiveAudioMode === "none" ? Translation.tr("No audio")
                    : RecorderStatus.effectiveAudioMode === "microphone" ? Translation.tr("Microphone")
                    : RecorderStatus.effectiveAudioMode === "both" ? Translation.tr("System and microphone")
                    : Translation.tr("System audio")
                role: AtollText.Meta
            }
        }
        AtollNumber {
            text: page.island.clockText(RecorderStatus.elapsedSeconds)
            color: AtollStyle.danger
            pixelSize: 28 * AtollStyle.typeScale
            weight: Font.Bold
            letterSpacing: -1
        }
        GlyphButton {
            glyph: "stop"
            emphasized: true
            danger: true
            Accessible.name: Translation.tr("Stop recording")
            onClicked: {
                Quickshell.execDetached([Directories.recordScriptPath, "--stop"])
                RecorderStatus.scheduleQuickCheck()
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        visible: page.island.recording && page.island.timerKind.length > 0
        implicitHeight: 1
        color: AtollStyle.fill
    }

    RowLayout {
        Layout.fillWidth: true
        visible: page.island.timerKind.length > 0
        spacing: 12 * AtollStyle.density
        Item {
            Layout.preferredWidth: 40 * AtollStyle.density
            Layout.preferredHeight: 40 * AtollStyle.density
            ProgressRing {
                anchors.fill: parent
                visible: page.island.timerKind !== "stopwatch"
                tint: AtollStyle.secondaryAccent
                stroke: 3 * AtollStyle.density
                progress: page.island.timerProgress
            }
            Glyph {
                anchors.centerIn: parent
                text: page.island.timerGlyph
                iconSize: 18 * AtollStyle.density
                color: AtollStyle.secondaryAccent
            }
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1
            AtollText {
                Layout.fillWidth: true
                elide: Text.ElideRight
                text: page.island.timerLabel
                font.pixelSize: AtollStyle.typeBody
                font.weight: AtollStyle.weight(Font.DemiBold)
            }
            AtollText {
                Layout.fillWidth: true
                elide: Text.ElideRight
                text: page.island.timerPaused ? Translation.tr("Paused")
                    : page.island.timerKind === "pomodoro"
                        ? Translation.tr("Cycle %1 of %2").arg(TimerService.pomodoroCycle + 1).arg(TimerService.cyclesBeforeLongBreak)
                    : Translation.tr("Running")
                role: AtollText.Meta
            }
        }
        AtollNumber {
            text: page.island.clockText(page.island.timerSeconds)
            countDown: page.island.timerKind !== "stopwatch"
            color: page.island.timerPaused ? AtollStyle.subtext : AtollStyle.secondaryAccent
            pixelSize: 28 * AtollStyle.typeScale
            weight: Font.Bold
            letterSpacing: -1
        }
        GlyphButton {
            glyph: page.island.timerPaused ? "play_arrow" : "pause"
            colBackground: AtollStyle.tintFill(AtollStyle.secondaryAccent)
            colBackgroundHover: AtollStyle.tintFillHover(AtollStyle.secondaryAccent)
            glyphColor: AtollStyle.secondaryAccent
            Accessible.name: page.island.timerPaused ? Translation.tr("Resume") : Translation.tr("Pause")
            onClicked: {
                if (page.island.timerKind === "pomodoro") TimerService.togglePomodoro()
                else if (page.island.timerKind === "countdown") TimerService.toggleCountdown()
                else TimerService.toggleStopwatch()
            }
        }
        GlyphButton {
            glyph: "close"
            colBackground: AtollStyle.fill
            colBackgroundHover: AtollStyle.fillHover
            glyphSize: 18 * AtollStyle.density
            Accessible.name: Translation.tr("Stop timer")
            onClicked: {
                if (page.island.timerKind === "pomodoro") TimerService.stopPomodoro()
                else if (page.island.timerKind === "countdown") TimerService.stopCountdown()
                else TimerService.stopStopwatch()
            }
        }
    }

    Repeater {
        model: LiveActivities.active
        ColumnLayout {
            id: taskEntry
            required property var modelData
            required property int index
            readonly property color tint: AtollStyle.identityColor(String(taskEntry.modelData.tint ?? "lavender"))
            readonly property real progress: Number(taskEntry.modelData.progress ?? -1)
            Layout.fillWidth: true
            spacing: 12 * AtollStyle.density
            Rectangle {
                Layout.fillWidth: true
                visible: taskEntry.index > 0 || page.island.recording || page.island.timerKind.length > 0
                implicitHeight: 1
                color: AtollStyle.fill
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 12 * AtollStyle.density
                Item {
                    Layout.preferredWidth: 40 * AtollStyle.density
                    Layout.preferredHeight: 40 * AtollStyle.density
                    Rectangle {
                        anchors.fill: parent
                        radius: width / 2
                        color: AtollStyle.tintFill(taskEntry.tint)
                        visible: taskEntry.progress < 0
                    }
                    ProgressRing {
                        anchors.fill: parent
                        visible: taskEntry.progress >= 0
                        tint: taskEntry.tint
                        stroke: 3 * AtollStyle.density
                        progress: Math.max(0, taskEntry.progress)
                    }
                    Glyph {
                        anchors.centerIn: parent
                        text: String(taskEntry.modelData.glyph ?? "bolt")
                        iconSize: 18 * AtollStyle.density
                        color: taskEntry.tint
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1
                    AtollText {
                        Layout.fillWidth: true
                        text: String(taskEntry.modelData.title ?? "")
                        font.pixelSize: AtollStyle.typeBody
                        font.weight: AtollStyle.weight(Font.DemiBold)
                        elide: Text.ElideRight
                    }
                    AtollText {
                        Layout.fillWidth: true
                        text: String(taskEntry.modelData.detail ?? "").length > 0 ? String(taskEntry.modelData.detail)
                            : taskEntry.progress < 0 ? Translation.tr("Working") : Translation.tr("In progress")
                        role: AtollText.Meta
                        elide: Text.ElideRight
                    }
                }
                AtollNumber {
                    visible: taskEntry.progress >= 0
                    text: Math.round(taskEntry.progress * 100) + "%"
                    color: taskEntry.tint
                    pixelSize: 28 * AtollStyle.typeScale
                    weight: Font.Bold
                    letterSpacing: -1
                }
                GlyphButton {
                    glyph: "close"
                    colBackground: AtollStyle.fill
                    colBackgroundHover: AtollStyle.fillHover
                    glyphSize: 18 * AtollStyle.density
                    Accessible.name: Translation.tr("Dismiss")
                    onClicked: LiveActivities.dismiss(String(taskEntry.modelData.id))
                }
            }
        }
    }
}
