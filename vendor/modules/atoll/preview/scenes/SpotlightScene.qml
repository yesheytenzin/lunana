pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../../../services"
import "../../../common/widgets"
import "../../style"
import "../../frame"
import "../../components"
import "../../pieces"
import "../parts"

PreviewScene {
    id: spotRoot
    readonly property bool on: spotRoot.opt("atoll.modules.palette", true)
    readonly property bool fromIsland: String(spotRoot.opt("atoll.palette.opens", "floating")) === "island"
    readonly property bool hints: spotRoot.opt("atoll.palette.showHints", true)
    readonly property int results: Math.max(3, Math.min(14, Number(spotRoot.opt("atoll.palette.maxResults", 8))))
    readonly property real plateWidth: Math.max(420, Math.min(900, Number(spotRoot.opt("atoll.palette.width", 640)))) * spotRoot.d
    readonly property var apps: (TaskbarApps.apps ?? []).filter(app => app && !app.separator && String(app.appId ?? "").length > 0 && app.appId !== "SEPARATOR")
    readonly property real naturalWidth: spotRoot.plateWidth + Math.round(80 * spotRoot.d)
    readonly property real naturalHeight: spotPlate.y + spotPlate.height + Math.round(24 * spotRoot.d)
    readonly property bool cropBottom: true
    IslandPill {
        id: spotIsland
        visible: spotRoot.fromIsland
        anchors.horizontalCenter: parent.horizontalCenter
        y: AtollFrame.band
    }
    Plate {
        id: spotPlate
        surface: "spotlight"
        opacity: spotRoot.on ? 1 : 0.35
        anchors.horizontalCenter: parent.horizontalCenter
        y: spotRoot.fromIsland ? spotIsland.y + spotIsland.height + AtollStyle.weld : Math.round(40 * spotRoot.d)
        width: spotRoot.plateWidth
        height: spotColumn.implicitHeight + Math.round(28 * spotRoot.d)
        ColumnLayout {
            id: spotColumn
            x: Math.round(14 * spotRoot.d); y: Math.round(14 * spotRoot.d)
            width: parent.width - 2 * x
            spacing: Math.round(6 * spotRoot.d)
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: Math.round(40 * spotRoot.d)
                radius: height / 2
                color: AtollStyle.fillQuiet
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Math.round(14 * spotRoot.d)
                    spacing: Math.round(8 * spotRoot.d)
                    MaterialSymbol { text: "search"; iconSize: Math.round(18 * spotRoot.d); color: AtollStyle.muted }
                    AtollText { text: Translation.tr("Search apps, files and actions"); color: AtollStyle.muted; font.pixelSize: AtollStyle.typeLabel }
                }
            }
            Row {
                visible: spotRoot.hints
                spacing: Math.round(6 * spotRoot.d)
                Repeater {
                    model: [";  " + Translation.tr("Clipboard"), "=  " + Translation.tr("Calculator"), "/  " + Translation.tr("Actions"), ":  " + Translation.tr("Emoji")]
                    Rectangle {
                        required property string modelData
                        width: hintLabel.implicitWidth + Math.round(18 * spotRoot.d)
                        height: Math.round(24 * spotRoot.d)
                        radius: height / 2
                        color: AtollStyle.fillQuiet
                        AtollText { id: hintLabel; anchors.centerIn: parent; text: parent.modelData; color: AtollStyle.subtext; font.pixelSize: AtollStyle.typeFootnote }
                    }
                }
            }
            AtollText { text: Translation.tr("Top hit"); role: AtollText.Meta; Layout.topMargin: Math.round(4 * spotRoot.d) }
            Repeater {
                model: spotRoot.results
                RowLayout {
                    id: hit
                    required property int index
                    readonly property var app: spotRoot.apps[hit.index % Math.max(1, spotRoot.apps.length)] ?? null
                    Layout.fillWidth: true
                    spacing: Math.round(10 * spotRoot.d)
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: Math.round(36 * spotRoot.d)
                        radius: AtollStyle.radiusRow
                        color: hit.index === 0 ? AtollStyle.tintFill(AtollStyle.accent) : "transparent"
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Math.round(8 * spotRoot.d)
                            anchors.rightMargin: Math.round(10 * spotRoot.d)
                            spacing: Math.round(10 * spotRoot.d)
                            SmartAppIcon { implicitSize: Math.round(24 * spotRoot.d); icon: AtollPieces.appIcon(hit.app?.appId ?? ""); fallback: "application-x-executable" }
                            AtollText {
                                Layout.fillWidth: true
                                text: DesktopEntries.heuristicLookup(hit.app?.appId ?? "")?.name ?? String(hit.app?.appId ?? Translation.tr("Result"))
                                elide: Text.ElideRight
                            }
                            AtollText { text: hit.index === 0 ? Translation.tr("Open") : Translation.tr("App"); color: AtollStyle.muted; font.pixelSize: AtollStyle.typeMeta }
                        }
                    }
                }
            }
        }
    }
    OffState { visible: !spotRoot.on; text: Translation.tr("Spotlight off") }
    Caption {
        glyph: spotRoot.fromIsland ? "pill" : "web_asset"
        text: Translation.tr("%1 results").arg(spotRoot.results) + " · " + (spotRoot.fromIsland ? Translation.tr("grows out of the Island") : Translation.tr("floats over the screen"))
    }
}
