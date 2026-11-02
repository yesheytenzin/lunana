pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtMultimedia
import Quickshell.Widgets
import "../../../services"
import "../../common"
import "../../common/functions"
import "../../common/widgets"
import "../style"
import "../components"

ClippingRectangle {
    id: root

    required property var picker
    property var entry: null
    readonly property real d: AtollStyle.density
    readonly property string key: String(root.entry?.key ?? "")
    property string settledKey: ""
    readonly property bool settled: root.key.length > 0 && root.settledKey === root.key

    color: AtollStyle.surfaceHigh
    onKeyChanged: settle.restart()
    Timer { id: settle; interval: String(root.entry?.filePath ?? "").length > 0 ? 90 : 280; onTriggered: root.settledKey = root.key }

    // The last entry that finished arriving stays underneath, so a new selection fades in over it
    // instead of dropping to the empty stage first.
    property var heldEntry: null
    Timer { id: adopt; interval: AtollStyle.duration(260); onTriggered: root.heldEntry = root.entry }
    onEntryChanged: if (root.entry === null) root.heldEntry = null
    Loader {
        anchors.fill: parent
        active: root.entry !== null && String(root.heldEntry?.filePath ?? "").length > 0 && root.heldEntry?.key !== root.key
        sourceComponent: ThumbnailImage {
            generateThumbnail: true
            cleanVideoStill: true
            sourcePath: String(root.heldEntry?.filePath ?? "")
            thumbnailSizeName: "large"
            fillMode: Image.PreserveAspectCrop
        }
    }
    AtollImage {
        anchors.fill: parent
        visible: root.entry !== null && String(root.heldEntry?.imageUrl ?? "").length > 0 && root.heldEntry?.key !== root.key
        source: root.heldEntry?.imageUrl ?? ""
    }
    Loader {
        anchors.fill: parent
        active: String(root.entry?.filePath ?? "").length > 0
        sourceComponent: ThumbnailImage {
            generateThumbnail: true
            cleanVideoStill: true
            sourcePath: String(root.entry?.filePath ?? "")
            thumbnailSizeName: "large"
            fillMode: Image.PreserveAspectCrop
            onStatusChanged: if (status === Image.Ready) adopt.restart()
        }
    }
    AtollImage {
        anchors.fill: parent
        visible: String(root.entry?.imageUrl ?? "").length > 0
        source: root.entry?.imageUrl ?? ""
        opacity: status === Image.Ready ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: AtollStyle.duration(220); easing.type: AtollStyle.feedbackEasing } }
        onStatusChanged: if (status === Image.Ready) adopt.restart()
    }
    AtollImage {
        id: sharp
        anchors.fill: parent
        source: root.settled && root.picker.opened ? String(root.entry?.fullUrl ?? "") : ""
        opacity: status === Image.Ready ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: AtollStyle.duration(260); easing.type: AtollStyle.feedbackEasing } }
    }
    Loader {
        id: motionLoader
        anchors.fill: parent
        active: root.settled && root.picker.opened && root.picker.playMotion && String(root.entry?.motionSource ?? "").length > 0
        sourceComponent: Video {
            id: motion
            property bool shown: false
            readonly property string path: String(root.entry?.motionSource ?? "")
            source: motion.path.startsWith("/") ? "file://" + motion.path : motion.path
            fillMode: VideoOutput.PreserveAspectCrop
            loops: MediaPlayer.Infinite
            muted: true
            autoPlay: true
            opacity: motion.shown ? 1 : 0
            onPositionChanged: if (motion.position > 0) motion.shown = true
            Behavior on opacity { NumberAnimation { duration: AtollStyle.duration(320); easing.type: AtollStyle.feedbackEasing } }
        }
    }

    Rectangle {
        visible: root.entry !== null
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: Math.min(parent.height, Math.round(96 * root.d))
        gradient: Gradient {
            GradientStop { position: 0; color: ColorUtils.applyAlpha(AtollStyle.surface, 0) }
            GradientStop { position: 0.55; color: AtollStyle.veilStrong }
            GradientStop { position: 1; color: AtollStyle.veilHeavy }
        }
    }

    ColumnLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: Math.round(18 * root.d)
        spacing: Math.round(4 * root.d)
        visible: root.entry !== null

        AtollText {
            Layout.fillWidth: true
            visible: text.length > 0
            text: String(root.entry?.eyebrow ?? "")
            color: AtollStyle.onMedia
            font.family: AtollStyle.fontTitle
            font.pixelSize: AtollStyle.typeHeadline
            font.weight: AtollStyle.weight(Font.DemiBold)
            elide: Text.ElideRight
        }
        Row {
            spacing: Math.round(6 * root.d)
            Repeater {
                model: root.entry?.facts ?? []
                Rectangle {
                    id: fact
                    required property var modelData
                    height: Math.round(24 * root.d)
                    width: factRow.implicitWidth + Math.round(18 * root.d)
                    radius: height / 2
                    color: AtollStyle.onMediaFill
                    Row {
                        id: factRow
                        anchors.centerIn: parent
                        spacing: Math.round(4 * root.d)
                        MaterialSymbol {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: String(fact.modelData.glyph ?? "").length > 0
                            text: String(fact.modelData.glyph ?? "")
                            fill: 1
                            iconSize: Math.round(14 * root.d)
                            color: AtollStyle.onMedia
                        }
                        AtollText {
                            anchors.verticalCenter: parent.verticalCenter
                            text: String(fact.modelData.label ?? "")
                            width: Math.min(implicitWidth, Math.round(220 * root.d))
                            elide: Text.ElideMiddle
                            color: AtollStyle.onMedia
                            font.family: fact.modelData.figure ? AtollStyle.fontNumbers : AtollStyle.fontMain
                            font.features: ({ "tnum": 1 })
                            font.pixelSize: AtollStyle.typeMeta
                            font.weight: AtollStyle.weight(Font.DemiBold)
                        }
                    }
                }
            }
        }
    }

    Rectangle {
        visible: root.entry?.current ?? false
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: Math.round(14 * root.d)
        height: Math.round(26 * root.d)
        width: inUse.implicitWidth + Math.round(20 * root.d)
        radius: height / 2
        color: AtollStyle.accent
        Row {
            id: inUse
            anchors.centerIn: parent
            spacing: Math.round(4 * root.d)
            MaterialSymbol {
                anchors.verticalCenter: parent.verticalCenter
                text: "check"
                iconSize: Math.round(14 * root.d)
                color: AtollStyle.inkOnAccent
            }
            AtollText {
                anchors.verticalCenter: parent.verticalCenter
                text: Translation.tr("In use")
                color: AtollStyle.inkOnAccent
                font.pixelSize: AtollStyle.typeMeta
                font.weight: AtollStyle.weight(Font.DemiBold)
            }
        }
    }

    WallpaperEmpty {
        anchors.centerIn: parent
        width: parent.width - 40 * root.d
        visible: root.entry === null
        picker: root.picker
    }
}
