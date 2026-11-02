pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Widgets
import "../../../services"
import "../../common"
import "../../common/widgets"
import "../style"
import "../components"

ClippingRectangle {
    id: root

    property int sourceIndex: 0
    readonly property string primarySource: Directories.userAvatarSourcePrimary
    onPrimarySourceChanged: root.sourceIndex = 0

    radius: width / 2
    color: AtollStyle.fill

    AtollImage {
        id: picture
        anchors.fill: parent
        source: Directories.avatarSourceAt(root.sourceIndex)
        onStatusChanged: {
            if (status === Image.Error && root.sourceIndex + 1 < Directories.userAvatarPaths.length)
                Qt.callLater(() => root.sourceIndex++)
        }
    }
    StyledText {
        anchors.centerIn: parent
        visible: picture.status !== Image.Ready
        text: (SystemInfo.displayName || SystemInfo.username || "?").charAt(0).toUpperCase()
        color: AtollStyle.text
        font.family: AtollStyle.fontTitle
        font.pixelSize: root.height * 0.42
        font.weight: AtollStyle.weight(Font.DemiBold)
    }
}
