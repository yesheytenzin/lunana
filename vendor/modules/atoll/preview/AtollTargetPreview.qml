pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../.."
import "../../../services"
import "../../common"
import "../../common/functions"
import "../../common/widgets"
import "../style"
import "../frame"
import "../components"
import "../pieces"

Item {
    id: root

    clip: true
    property string target: "material"
    property bool playing: true
    readonly property real d: AtollStyle.density
    readonly property real specimenHeight: specimen.height + Math.round(44 * root.d)
    readonly property string scene: ({ motion: "card", bodies: "card", pieces: "card", island: "island" })[root.target]
        ?? ({ transients: "feedback", dock: "dock", places: "place", desktop: "widget" })[root.target] ?? "specimen"

    AtollPreviewStage {
        anchors.fill: parent
        visible: root.scene !== "card" && root.scene !== "island"
    }

    AtollMotionLab {
        anchors.fill: parent
        visible: root.scene === "card" || root.scene === "island"
        mode: root.scene === "island" ? "island" : "card"
        playing: root.playing && visible
    }

    component Body: Rectangle {
        color: AtollStyle.bodySurface
        radius: AtollStyle.radiusSheet
        border.width: AtollStyle.rim.a > 0 ? 1 : 0
        border.color: AtollStyle.rim
        AtollGlassEdge { anchors.fill: parent; z: 10; visible: AtollStyle.edgeLit && shown; radius: parent.radius }
        AtollLightWash {
            anchors.fill: parent
            radius: parent.radius
            light: AtollStyle.wallpaperLight
        }
    }

    Item {
        anchors.fill: parent
        anchors.margins: Math.round(22 * root.d)
        visible: root.scene === "specimen"

        Body {
            id: specimen
            anchors.centerIn: parent
            width: Math.min(parent.width, Math.round(420 * root.d))
            height: specimenColumn.implicitHeight + Math.round(40 * root.d)
            scale: Math.min(1, parent.height / Math.max(1, specimen.height), parent.width / Math.max(1, specimen.width))
            layer.enabled: specimen.scale < 0.999
            layer.smooth: true
            layer.mipmap: true

            ColumnLayout {
                id: specimenColumn
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Math.round(20 * root.d)
                spacing: Math.round(14 * root.d)

                RowLayout {
                    spacing: Math.round(10 * root.d)
                    Rectangle {
                        implicitWidth: Math.round(34 * root.d)
                        implicitHeight: implicitWidth
                        radius: AtollStyle.iconRadius(width)
                        color: AtollStyle.accent
                        MaterialSymbol { anchors.centerIn: parent; text: "palette"; fill: 1; iconSize: Math.round(19 * root.d); color: AtollStyle.inkOnAccent }
                    }
                    ColumnLayout {
                        spacing: 0
                        AtollText { text: Translation.tr("Studio"); font.family: AtollStyle.fontTitle; font.weight: Font.Bold; font.pixelSize: 19 * AtollStyle.typeScale }
                        AtollText { text: Translation.tr("How every surface looks"); color: AtollStyle.textSecondary; font.pixelSize: AtollStyle.typeMeta }
                    }
                    Item { Layout.fillWidth: true }
                    AtollNumber {
                        text: Translation.locale.toString(DateTime.clock.date, "hh:mm")
                        pixelSize: 30 * AtollStyle.typeScale
                        weight: AtollStyle.figureWeight
                    }
                }

                Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: AtollStyle.hairline }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Math.round(6 * root.d)
                    Repeater {
                        model: [AtollStyle.fillQuiet, AtollStyle.fill, AtollStyle.fillHover, AtollStyle.fillActive, AtollStyle.fillStrong]
                        Rectangle {
                            required property color modelData
                            Layout.fillWidth: true
                            implicitHeight: Math.round(30 * root.d)
                            radius: AtollStyle.radiusRow
                            color: modelData
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Math.round(8 * root.d)
                    Rectangle {
                        implicitWidth: accentLabel.implicitWidth + Math.round(26 * root.d)
                        implicitHeight: Math.round(32 * root.d)
                        radius: height / 2
                        color: AtollStyle.accent
                        AtollText { id: accentLabel; anchors.centerIn: parent; text: Translation.tr("Accent"); color: AtollStyle.inkOnAccent; font.weight: Font.DemiBold }
                    }
                    Rectangle {
                        implicitWidth: highlightLabel.implicitWidth + Math.round(26 * root.d)
                        implicitHeight: Math.round(32 * root.d)
                        radius: height / 2
                        color: AtollStyle.tintFill(AtollStyle.secondaryAccent)
                        AtollText { id: highlightLabel; anchors.centerIn: parent; text: Translation.tr("Highlight"); color: AtollStyle.secondaryAccent; font.weight: Font.DemiBold }
                    }
                    Item { Layout.fillWidth: true }
                    Rectangle {
                        implicitWidth: Math.round(22 * root.d)
                        implicitHeight: implicitWidth
                        radius: width / 2
                        color: AtollStyle.badge
                        AtollText { anchors.centerIn: parent; text: "3"; color: AtollStyle.inkOnBadge; font.family: AtollStyle.fontNumbers; font.weight: Font.Bold; font.pixelSize: AtollStyle.typeMeta }
                    }
                }

                AtollCapsuleSlider {
                    Layout.fillWidth: true
                    implicitHeight: Math.round(44 * root.d)
                    icon: "volume_up"
                    value: 0.64
                }

                AtollText {
                    Layout.fillWidth: true
                    text: Translation.tr("Text reads in the main face. Secondary lines step back, tertiary ones whisper.")
                    wrapMode: Text.WordWrap
                    font.pixelSize: AtollStyle.typeLabel
                }
                AtollText {
                    Layout.fillWidth: true
                    text: Translation.tr("Secondary text")
                    color: AtollStyle.textSecondary
                }
                AtollText {
                    Layout.fillWidth: true
                    text: Translation.tr("Tertiary text")
                    color: AtollStyle.textTertiary
                }
            }
        }
    }

    Item {
        anchors.fill: parent
        anchors.margins: Math.round(22 * root.d)
        visible: root.scene === "feedback"

        Body {
            id: banner
            anchors.horizontalCenter: parent.horizontalCenter
            y: parent.height * 0.22
            width: Math.min(parent.width, Math.round(Number(Config.options?.atoll?.notifications?.width ?? 380) * root.d))
            height: Math.round(74 * root.d)
            radius: AtollStyle.radiusPlate
            RowLayout {
                anchors.fill: parent
                anchors.margins: Math.round(14 * root.d)
                spacing: Math.round(12 * root.d)
                AtollMark { implicitSize: Math.round(38 * root.d) }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Math.round(2 * root.d)
                    AtollText { text: Translation.tr("A notification"); font.weight: Font.DemiBold }
                    AtollText { Layout.fillWidth: true; text: Translation.tr("Banners grow out of the Island and fold back into it."); color: AtollStyle.textSecondary; elide: Text.ElideRight }
                }
            }
        }
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: banner.bottom
            anchors.topMargin: Math.round(28 * root.d)
            width: Math.round(250 * root.d)
            height: Math.round(42 * root.d)
            radius: height / 2
            color: AtollStyle.bodySurface
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Math.round(14 * root.d)
                anchors.rightMargin: Math.round(14 * root.d)
                spacing: Math.round(10 * root.d)
                MaterialSymbol { text: "volume_up"; fill: 1; iconSize: Math.round(18 * root.d); color: AtollStyle.text }
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: Math.round(6 * root.d)
                    radius: height / 2
                    color: AtollStyle.fill
                    Rectangle { width: parent.width * 0.7; height: parent.height; radius: height / 2; color: AtollStyle.fillStrong }
                }
                AtollText { text: "70"; font.family: AtollStyle.fontNumbers; font.weight: Font.DemiBold }
            }
        }
    }

    Item {
        anchors.fill: parent
        visible: root.scene === "dock"
        readonly property real icon: Math.max(28, Math.min(64, Number(Config.options?.atoll?.dock?.iconSize ?? 40))) * root.d
        Rectangle {
            id: dockPlate
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Math.round(28 * root.d)
            width: dockRow.implicitWidth + Math.round(20 * root.d)
            height: parent.icon + Math.round(18 * root.d)
            radius: Math.min(height / 2, AtollStyle.radiusPlate)
            color: AtollStyle.bodySurface
            Row {
                id: dockRow
                anchors.centerIn: parent
                spacing: Math.round(8 * root.d)
                Repeater {
                    model: (TaskbarApps.apps ?? []).slice(0, 6)
                    Item {
                        required property var modelData
                        width: dockPlate.parent.icon
                        height: width
                        SmartAppIcon { anchors.fill: parent; implicitSize: parent.width; icon: AtollPieces.appIcon(parent.modelData?.appId ?? "") }
                    }
                }
            }
        }
    }

    Item {
        anchors.fill: parent
        anchors.margins: Math.round(22 * root.d)
        visible: root.scene === "place" || root.scene === "widget"
        Body {
            anchors.centerIn: parent
            width: root.scene === "widget" ? Math.round(220 * root.d) : Math.min(parent.width, Math.round(Number(Config.options?.atoll?.sidebars?.right?.width ?? 380) * root.d * 0.8))
            height: root.scene === "widget" ? Math.round(160 * root.d) : Math.min(parent.height, Math.round(420 * root.d))
            radius: root.scene === "widget" ? AtollStyle.radiusPlate : AtollStyle.surfaceRadius("panels", AtollStyle.radiusPanel)
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Math.round(16 * root.d)
                spacing: Math.round(10 * root.d)
                AtollText { text: root.scene === "widget" ? Translation.tr("Widget") : Translation.tr("Today"); font.family: AtollStyle.fontTitle; font.weight: Font.Bold; font.pixelSize: 18 * AtollStyle.typeScale }
                Repeater {
                    model: root.scene === "widget" ? 1 : 3
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: AtollStyle.radiusCard
                        color: AtollStyle.surfaceHigh
                    }
                }
            }
        }
    }
}
