pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Quickshell.Widgets
import "../../../services"
import "../../common"
import "../../common/widgets"
import "../style"
import "../components"
import "../pieces"

// A window as Orbit shows it: the picture Niri took of it, or its app's icon on a quiet fill until there is one.
// Used by the workspace cards, the recent row and the pocket, so a window looks the same wherever it is.
Item {
    id: root

    property int windowId: -1
    property string appId: ""
    property string title: ""
    property bool previews: true
    // Pixels the picture is decoded at: a stable budget chosen by the owner, never this item's animated size.
    property size decodeSize: Qt.size(640, 360)
    property real cornerRadius: AtollStyle.radiusTile
    property bool cursor: false
    property bool dimmed: false
    // How visible a dimmed (non-matching) window stays, 0..1.
    property real dimOpacity: 0.22
    property bool minimised: false
    // On a shelf the window is named under its picture and its app's icon rides the bottom edge; the owner leaves room.
    property bool shelved: false
    // Title strip over the bottom of the picture (the keyboard's tile and the hovered one).
    property bool titled: !root.shelved && (root.cursor || hover.hovered)
    readonly property alias hovered: hover.hovered
    readonly property bool ready: shot.status === Image.Ready
    readonly property real d: AtollStyle.density

    HoverHandler { id: hover }

    // The keyboard's window lifts off the strip on a halo of the accent, the way a picked window rises in Mission Control.
    RectangularShadow {
        anchors.fill: parent
        radius: root.cornerRadius
        blur: Math.round(22 * root.d)
        spread: Math.round(2 * root.d)
        color: AtollStyle.tintFillHover(AtollStyle.accent)
        opacity: root.cursor && !root.dimmed ? 1 : 0
        visible: opacity > 0.001
        Behavior on opacity { NumberAnimation { duration: AtollStyle.duration(160); easing.type: AtollStyle.feedbackEasing } }
    }

    ClippingRectangle {
        id: face
        anchors.fill: parent
        radius: root.cornerRadius
        color: AtollStyle.fill
        opacity: root.dimmed ? root.dimOpacity : 1
        Behavior on opacity { NumberAnimation { duration: AtollStyle.duration(140); easing.type: AtollStyle.feedbackEasing } }

        Image {
            id: shot
            anchors.fill: parent
            source: root.previews && root.windowId >= 0 ? WindowPreviewService.getPreviewUrl(root.windowId) : ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            smooth: true
            // A screenshot is small text and hard edges: decoded at the size it is drawn, mipmaps only soften it.
            mipmap: false
            retainWhileLoading: true
            sourceSize: root.decodeSize
            opacity: status === Image.Ready ? (root.minimised ? 0.55 : 1) : 0
            visible: opacity > 0.001
            Behavior on opacity { NumberAnimation { duration: AtollStyle.duration(160); easing.type: AtollStyle.feedbackEasing } }
        }
        SmartAppIcon {
            anchors.centerIn: parent
            icon: AtollPieces.appIcon(root.appId)
            fallback: "application-x-executable"
            iconSize: Math.max(16, Math.min(56, Math.round(Math.min(root.width, root.height) * 0.36)))
            opacity: 1 - shot.opacity
            visible: opacity > 0.001
        }

        // The title, read over a veil that fades up from the bottom edge.
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: Math.min(parent.height, Math.round(44 * root.d))
            opacity: root.titled && root.width > Math.round(84 * root.d) ? 1 : 0
            visible: opacity > 0.001
            Behavior on opacity { NumberAnimation { duration: AtollStyle.duration(120); easing.type: AtollStyle.feedbackEasing } }
            gradient: Gradient {
                GradientStop { position: 0; color: "transparent" }
                GradientStop { position: 1; color: AtollStyle.veilStrong }
            }
            Row {
                anchors.left: parent.left
                anchors.leftMargin: Math.round(8 * root.d)
                anchors.right: parent.right
                anchors.rightMargin: Math.round(8 * root.d)
                anchors.bottom: parent.bottom
                anchors.bottomMargin: Math.round(6 * root.d)
                spacing: Math.round(6 * root.d)
                SmartAppIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    icon: AtollPieces.appIcon(root.appId)
                    fallback: "application-x-executable"
                    iconSize: Math.round(16 * root.d)
                }
                AtollText {
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.min(implicitWidth, parent.width - Math.round(22 * root.d))
                    text: root.title
                    color: AtollStyle.onMedia
                    font.pixelSize: AtollStyle.typeFootnote
                    font.weight: AtollStyle.weight(Font.DemiBold)
                    elide: Text.ElideRight
                }
            }
        }
        Rectangle {
            anchors.fill: parent
            color: AtollStyle.fillHover
            opacity: hover.hovered && !root.cursor ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: AtollStyle.duration(110); easing.type: AtollStyle.feedbackEasing } }
        }
    }

    SmartAppIcon {
        visible: root.shelved
        x: Math.round((root.width - width) / 2)
        y: Math.round(root.height - height / 2)
        icon: AtollPieces.appIcon(root.appId)
        fallback: "application-x-executable"
        iconSize: Math.round(24 * root.d)
        opacity: root.dimmed ? root.dimOpacity : 1
    }
    AtollText {
        visible: root.shelved
        y: Math.round(root.height + 12 * root.d + 4 * root.d)
        width: root.width
        horizontalAlignment: Text.AlignHCenter
        text: root.title
        role: AtollText.Meta
        color: root.cursor ? AtollStyle.text : AtollStyle.subtext
        elide: Text.ElideRight
        opacity: root.dimmed ? root.dimOpacity : 1
    }

    // The keyboard's tile wears the accent; a border is a state.
    Rectangle {
        anchors.fill: parent
        anchors.margins: -Math.round(1 * root.d)
        radius: root.cornerRadius + Math.round(1 * root.d)
        color: "transparent"
        border.width: root.cursor ? Math.max(2, Math.round(2 * root.d)) : 0
        border.color: AtollStyle.accent
        opacity: root.dimmed ? Math.min(1, root.dimOpacity * 2) : 1
    }
}
