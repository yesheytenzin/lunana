pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../.."
import "../../../services"
import "../../common/widgets"
import "../style"
import "../components"

// The stack of a widget in its quick controls. `manage` is the Stack page of a widget that is in one: its pages in
// order, how they turn and how to split them. `join` is a block of the Arrange page of one that is not: the widgets
// it could be stacked with. Dropping one widget on another does the same.
ColumnLayout {
    id: root

    required property var widget
    property string part: "manage"
    readonly property real d: AtollStyle.density
    readonly property var stack: root.widget.stack
    readonly property var others: root.stack ? [] : DesktopWidgetStacks.candidates(root.widget.outputName, root.widget.configEntryName)
    readonly property var intervals: [10, 20, 30, 60, 300]

    Layout.fillWidth: true
    visible: root.part === "manage" ? root.stack !== null
        : root.stack === null && root.widget.stackable && root.others.length > 0
    spacing: Math.round(8 * root.d)

    function entry(key: string): var {
        return AtollFaceData.galleryEntries.find(item => item.key === key)
            ?? { key: key, glyph: DesktopWidgetIdentity.glyph(key), label: key, tint: AtollStyle.identityOf(DesktopWidgetIdentity.tint(key)) }
    }
    function intervalLabel(seconds: int): string {
        return seconds >= 60 ? Translation.tr("%1 min").arg(Math.round(seconds / 60)) : Translation.tr("%1 s").arg(seconds)
    }
    // The page opens in the same sheet, in the same place.
    function turnTo(key: string): void {
        DesktopWidgetStacks.show(root.widget.outputName, root.stack.id, key)
        const instance = root.widget.outputName + "::" + key
        GlobalStates.selectDesktopWidget(instance)
        GlobalStates.requestDesktopWidgetQuickControls(instance)
    }

    AtollText {
        Layout.fillWidth: true
        visible: root.part === "join"
        text: Translation.tr("Stack with")
        color: AtollStyle.textSecondary
        font.pixelSize: AtollStyle.typeMeta
        font.weight: AtollStyle.weight(Font.DemiBold)
    }

    ColumnLayout {
        Layout.fillWidth: true
        visible: root.stack !== null
        spacing: Math.round(2 * root.d)

        Repeater {
            model: ScriptModel { values: root.stack ? root.stack.keys : [] }

            Rectangle {
                id: page
                required property string modelData
                required property int index
                readonly property var facts: root.entry(page.modelData)
                readonly property bool shown: root.stack !== null && root.stack.shownIndex === page.index
                Layout.fillWidth: true
                implicitHeight: Math.round(40 * root.d)
                radius: AtollStyle.radiusRow
                color: page.shown ? AtollStyle.tintFill(AtollStyle.accent)
                    : pageHover.hovered ? AtollStyle.fillHover : AtollStyle.fillQuiet
                Behavior on color { ColorAnimation { duration: AtollStyle.feedbackDuration; easing.type: AtollStyle.feedbackEasing } }

                HoverHandler { id: pageHover; cursorShape: Qt.PointingHandCursor }
                TapHandler { onTapped: root.turnTo(page.modelData) }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Math.round(8 * root.d)
                    anchors.rightMargin: Math.round(4 * root.d)
                    spacing: Math.round(8 * root.d)

                    Rectangle {
                        Layout.preferredWidth: Math.round(24 * root.d)
                        Layout.preferredHeight: Layout.preferredWidth
                        radius: AtollStyle.iconRadius(width)
                        gradient: Gradient {
                            GradientStop { position: 0; color: AtollStyle.tileTop(page.facts.tint) }
                            GradientStop { position: 1; color: page.facts.tint }
                        }
                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: page.facts.glyph
                            fill: 1
                            iconSize: Math.round(14 * root.d)
                            color: AtollStyle.onTint
                        }
                    }
                    AtollText {
                        Layout.fillWidth: true
                        text: page.facts.label
                        font.pixelSize: AtollStyle.typeLabel
                        font.weight: page.shown ? AtollStyle.weight(Font.DemiBold) : AtollStyle.weight(Font.Normal)
                        elide: Text.ElideRight
                    }
                    AtollIconButton {
                        materialIcon: "keyboard_arrow_up"
                        iconSize: Math.round(16 * root.d)
                        implicitWidth: Math.round(28 * root.d)
                        enabled: page.index > 0
                        onClicked: DesktopWidgetStacks.move(root.stack.id, page.modelData, -1)
                        Accessible.name: Translation.tr("Move earlier")
                    }
                    AtollIconButton {
                        materialIcon: "keyboard_arrow_down"
                        iconSize: Math.round(16 * root.d)
                        implicitWidth: Math.round(28 * root.d)
                        enabled: root.stack !== null && page.index < root.stack.count - 1
                        onClicked: DesktopWidgetStacks.move(root.stack.id, page.modelData, 1)
                        Accessible.name: Translation.tr("Move later")
                    }
                    AtollIconButton {
                        materialIcon: "close"
                        iconSize: Math.round(16 * root.d)
                        implicitWidth: Math.round(28 * root.d)
                        onClicked: DesktopWidgetStacks.remove(page.modelData)
                        Accessible.name: Translation.tr("Take out of the stack")
                    }
                }
            }
        }
    }

    AtollControlRow {
        visible: root.stack !== null
        glyph: "autorenew"
        label: Translation.tr("Turn pages by themselves")
        tint: AtollStyle.accent
        on: root.stack !== null && root.stack.rotate
        onToggled: DesktopWidgetStacks.setRotate(root.stack.id, !root.stack.rotate)
    }

    RowLayout {
        Layout.fillWidth: true
        visible: root.stack !== null && root.stack.rotate
        spacing: Math.round(4 * root.d)

        Repeater {
            model: root.intervals

            FaceChoice {
                required property int modelData
                Layout.fillWidth: true
                label: root.intervalLabel(modelData)
                selected: root.stack !== null && root.stack.interval === modelData
                onClicked: DesktopWidgetStacks.setSeconds(root.stack.id, modelData)
            }
        }
    }

    AtollButton {
        Layout.fillWidth: true
        visible: root.stack !== null
        text: Translation.tr("Split the stack")
        onClicked: DesktopWidgetStacks.dissolve(root.stack.id)
    }

    Flow {
        Layout.fillWidth: true
        visible: root.part === "join"
        spacing: Math.round(4 * root.d)

        Repeater {
            model: ScriptModel { values: root.others }

            FaceChoice {
                required property string modelData
                readonly property var facts: root.entry(modelData)
                icon: facts.glyph
                label: facts.label
                onClicked: DesktopWidgetStacks.merge(root.widget.configEntryName, modelData)
            }
        }
    }
}
