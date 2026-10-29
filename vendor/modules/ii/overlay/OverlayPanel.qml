pragma ComponentBehavior: Bound

import QtQuick
import "../../common/widgets"
import "."

Item {
    id: root

    default property alias content: holder.data
    property int elevation: 1

    Loader {
        anchors.fill: parent
        active: !OverlayLook.iris
        sourceComponent: PanelSurface {
            elevation: root.elevation
            outlined: false
        }
    }

    Rectangle {
        anchors.fill: parent
        visible: OverlayLook.iris
        radius: OverlayLook.roundingNormal
        color: OverlayLook.colRecessed
    }

    Item {
        id: holder
        anchors.fill: parent
    }
}
