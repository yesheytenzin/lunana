pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../../../services"
import "../../common"
import "../../common/functions"
import "../../common/widgets"
import "../style"
import "../components"
import "../pieces"

Item {
    id: root
    focus: true

    required property var targetWindow
    signal confirm()
    signal cancel()

    readonly property string appId: String(targetWindow?.app_id ?? "")
    readonly property string titleText: String(targetWindow?.title ?? "")
    readonly property var desktopEntry: AppSearch.lookupDesktopEntry(root.appId)

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) {
            root.cancel()
            event.accepted = true
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            root.confirm()
            event.accepted = true
        }
    }

    property real shown: 0
    Component.onCompleted: root.shown = 1
    Behavior on shown { NumberAnimation { duration: AtollStyle.emergeDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: AtollStyle.emergeCurve } }

    Rectangle {
        anchors.fill: parent
        opacity: Math.min(1, root.shown)
        color: AtollStyle.scrim
        MouseArea { anchors.fill: parent; onClicked: root.cancel() }
    }

    readonly property string appName: root.desktopEntry?.name ?? (root.appId.length > 0 ? root.appId : Translation.tr("this app"))

    AtollSurface {
        anchors.centerIn: parent
        opacity: Math.min(1, root.shown * 1.6)
        scale: 1.08 - 0.08 * root.shown
        width: Math.min(300 * AtollStyle.density, parent.width - 40)
        implicitHeight: alert.implicitHeight + 40 * AtollStyle.density
        radius: AtollStyle.radiusPlate
        raised: true
        MouseArea { anchors.fill: parent }

        ColumnLayout {
            id: alert
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 20 * AtollStyle.density
            anchors.rightMargin: 20 * AtollStyle.density
            spacing: 0

            SmartAppIcon {
                Layout.alignment: Qt.AlignHCenter
                icon: AtollPieces.appIcon(root.appId)
                fallback: "application-x-executable"
                iconSize: Math.round(52 * AtollStyle.density)
            }
            AtollText {
                Layout.fillWidth: true
                Layout.topMargin: 14 * AtollStyle.density
                horizontalAlignment: Text.AlignHCenter
                text: Translation.tr("Close “%1”?").arg(root.appName)
                font.pixelSize: AtollStyle.typeHeadline
                font.weight: AtollStyle.weight(Font.DemiBold)
                wrapMode: Text.Wrap
            }
            AtollText {
                Layout.fillWidth: true
                Layout.topMargin: 6 * AtollStyle.density
                horizontalAlignment: Text.AlignHCenter
                text: root.titleText.length > 0
                    ? Translation.tr("“%1” will close. Unsaved changes may be lost.").arg(root.titleText)
                    : Translation.tr("Unsaved changes may be lost.")
                color: AtollStyle.subtext
                font.pixelSize: AtollStyle.typeMeta
                wrapMode: Text.Wrap
                maximumLineCount: 3
                elide: Text.ElideRight
            }
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 18 * AtollStyle.density
                spacing: 8 * AtollStyle.density
                AtollButton {
                    Layout.fillWidth: true
                    implicitHeight: Math.round(32 * AtollStyle.density)
                    buttonRadius: AtollStyle.radiusRow
                    colBackground: AtollStyle.fill
                    colBackgroundHover: AtollStyle.fillHover
                    text: Translation.tr("Cancel")
                    onClicked: root.cancel()
                }
                AtollButton {
                    Layout.fillWidth: true
                    implicitHeight: Math.round(32 * AtollStyle.density)
                    buttonRadius: AtollStyle.radiusRow
                    emphasized: true
                    danger: true
                    text: Translation.tr("Close")
                    onClicked: root.confirm()
                }
            }
        }
    }

}
