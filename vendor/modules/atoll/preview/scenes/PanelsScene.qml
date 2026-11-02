pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../../../../services"
import "../../../common/widgets"
import "../../style"
import "../../frame"
import "../../components"
import "../parts"

PreviewScene {
    id: panelRoot
    readonly property real panelWidth: Math.max(300, Math.min(560, Number(panelRoot.opt("atoll.sidebars.right.width", 380)))) * panelRoot.d
    readonly property real naturalWidth: panelRoot.panelWidth * 2.2
    readonly property real naturalHeight: Math.round(420 * panelRoot.d)
    Plate {
        surface: "panels"
        fallbackRadius: AtollStyle.radiusPanel
        anchors.right: parent.right
        anchors.rightMargin: AtollFrame.band + AtollFrame.bodyAir
        y: AtollFrame.band + AtollFrame.bodyAir
        width: panelRoot.panelWidth
        height: parent.height - 2 * y
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Math.round(16 * panelRoot.d)
            spacing: Math.round(10 * panelRoot.d)
            RowLayout {
                spacing: Math.round(10 * panelRoot.d)
                AtollText { text: Translation.locale.toString(DateTime.clock.date, "d"); color: AtollStyle.identity.red; font.family: AtollStyle.fontNumbers; font.weight: AtollStyle.weight(Font.Bold); font.pixelSize: 30 * AtollStyle.typeScale }
                ColumnLayout {
                    spacing: 0
                    AtollText { text: Translation.tr("Today"); font.family: AtollStyle.fontTitle; font.weight: AtollStyle.weight(Font.Bold); font.pixelSize: AtollStyle.typeTitle }
                    AtollText { text: Translation.locale.toString(DateTime.clock.date, "dddd, MMMM"); color: AtollStyle.subtext; font.pixelSize: AtollStyle.typeMeta }
                }
                Item { Layout.fillWidth: true }
                AtollControlPlate {
                    id: previewPanelTools
                    Layout.alignment: Qt.AlignVCenter
                    controlHeight: Math.round(28 * panelRoot.d)
                    Row {
                        spacing: Math.round(2 * panelRoot.d)
                        Repeater {
                            model: ["keep", "tune", "close"]
                            Item {
                                required property string modelData
                                width: Math.round(28 * panelRoot.d); height: width
                                MaterialSymbol { anchors.centerIn: parent; text: parent.modelData; iconSize: Math.round(16 * panelRoot.d); color: AtollStyle.textSecondary }
                            }
                        }
                    }
                }
            }
            Repeater {
                model: [["calendar_month", Translation.tr("Calendar"), AtollStyle.identity.red], ["partly_cloudy_day", Translation.tr("Weather"), AtollStyle.identity.sky], ["notifications", Translation.tr("Notifications"), AtollStyle.identity.orange]]
                Rectangle {
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: AtollStyle.radiusCard
                    color: AtollStyle.surfaceHigh
                    RowLayout {
                        x: Math.round(12 * panelRoot.d); y: Math.round(12 * panelRoot.d)
                        spacing: Math.round(8 * panelRoot.d)
                        Rectangle {
                            implicitWidth: Math.round(24 * panelRoot.d); implicitHeight: implicitWidth
                            radius: AtollStyle.iconRadius(width); color: parent.parent.modelData[2]
                            MaterialSymbol { anchors.centerIn: parent; text: parent.parent.parent.modelData[0]; fill: 1; iconSize: Math.round(14 * panelRoot.d); color: AtollStyle.onTint }
                        }
                        AtollText { text: parent.parent.modelData[1]; font.weight: AtollStyle.weight(Font.DemiBold) }
                    }
                }
            }
        }
    }
}
