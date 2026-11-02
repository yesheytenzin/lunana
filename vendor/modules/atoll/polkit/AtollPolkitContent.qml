pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../../../services"
import "../../common"
import "../../common/functions"
import "../../common/widgets"
import "../style"
import "../components"

Item {
    id: root
    focus: true

    readonly property bool usePasswordChars: !(PolkitService.flow?.responseVisible ?? false)
    readonly property real d: AtollStyle.density

    function submit(): void {
        if (!PolkitService.interactionAvailable)
            return
        PolkitService.submit(input.text)
    }

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) {
            PolkitService.cancel()
            event.accepted = true
        }
    }

    Connections {
        target: PolkitService
        function onInteractionAvailableChanged(): void {
            if (!PolkitService.interactionAvailable)
                return
            input.text = ""
            input.forceActiveFocus()
        }
    }

    property real shown: 0
    Component.onCompleted: root.shown = 1
    Behavior on shown { NumberAnimation { duration: AtollStyle.emergeDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: AtollStyle.emergeCurve } }

    Rectangle {
        anchors.fill: parent
        opacity: Math.min(1, root.shown)
        color: AtollStyle.scrim
    }

    AtollSurface {
        id: card
        anchors.centerIn: parent
        opacity: Math.min(1, root.shown * 1.6)
        scale: 1.08 - 0.08 * root.shown
        width: Math.min(320 * root.d, parent.width - 40)
        implicitHeight: body.implicitHeight + 40 * root.d
        radius: AtollStyle.radiusPlate
        raised: true

        ColumnLayout {
            id: body
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 20 * root.d
            anchors.rightMargin: 20 * root.d
            spacing: 0

            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: Math.round(52 * root.d)
                implicitHeight: implicitWidth
                radius: width / 2
                color: AtollStyle.tintFill(AtollStyle.accent)
                MaterialSymbol {
                    anchors.centerIn: parent
                    text: PolkitService.batteryChargeLimitRequest ? "battery_charging_full" : "lock"
                    fill: 1
                    iconSize: Math.round(26 * root.d)
                    color: AtollStyle.accent
                }
            }
            AtollText {
                Layout.fillWidth: true
                Layout.topMargin: 14 * root.d
                horizontalAlignment: Text.AlignHCenter
                text: PolkitService.actionLabel !== Translation.tr("Authentication")
                    ? PolkitService.actionLabel : Translation.tr("Authentication required")
                font.pixelSize: AtollStyle.typeHeadline
                font.weight: AtollStyle.weight(Font.DemiBold)
                wrapMode: Text.Wrap
            }
            AtollText {
                Layout.fillWidth: true
                Layout.topMargin: 6 * root.d
                visible: text.length > 0
                horizontalAlignment: Text.AlignHCenter
                text: PolkitService.cleanMessage
                color: AtollStyle.subtext
                font.pixelSize: AtollStyle.typeMeta
                wrapMode: Text.Wrap
                maximumLineCount: 4
                elide: Text.ElideRight
            }

            AtollField {
                id: input
                Layout.fillWidth: true
                Layout.topMargin: 16 * root.d
                implicitHeight: Math.round(40 * root.d)
                focus: true
                enabled: PolkitService.interactionAvailable
                echoMode: root.usePasswordChars ? TextInput.Password : TextInput.Normal
                placeholderText: PolkitService.cleanPrompt
                font.pixelSize: AtollStyle.typeBody
                onAccepted: root.submit()
                background: Rectangle {
                    radius: height / 2
                    color: (input.activeFocus ? AtollStyle.fill : AtollStyle.fillQuiet)
                    border.width: input.activeFocus ? Math.max(1, Math.round(1.5 * root.d)) : 0
                    border.color: AtollStyle.tintBorder(AtollStyle.accent)
                    Behavior on color { ColorAnimation { duration: AtollStyle.duration(120); easing.type: AtollStyle.feedbackEasing } }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 14 * root.d
                spacing: 8 * root.d
                AtollButton {
                    Layout.fillWidth: true
                    implicitHeight: Math.round(34 * root.d)
                    buttonRadius: height / 2
                    buttonRadiusPressed: height / 2
                    colBackground: AtollStyle.fill
                    colBackgroundHover: AtollStyle.fillHover
                    text: Translation.tr("Cancel")
                    onClicked: PolkitService.cancel()
                }
                AtollButton {
                    Layout.fillWidth: true
                    implicitHeight: Math.round(34 * root.d)
                    buttonRadius: height / 2
                    buttonRadiusPressed: height / 2
                    emphasized: true
                    enabled: PolkitService.interactionAvailable
                    text: Translation.tr("Authenticate")
                    onClicked: root.submit()
                }
            }
        }
    }
}
