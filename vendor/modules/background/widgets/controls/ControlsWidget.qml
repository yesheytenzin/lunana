pragma ComponentBehavior: Bound

import QtQuick
import ".."
import "../../../atoll/widgets"

AbstractBackgroundWidget {
    id: root

    configEntryName: "controls"
    defaultConfig: ({
        placementStrategy: "free", widgetScale: 100, cornerRadius: -1, x: 120, y: 420
    })

    implicitWidth: root.atollFaced ? root.atollFaceWidth : instrumentBody.implicitWidth
    implicitHeight: root.atollFaced ? root.atollFaceHeight : instrumentBody.implicitHeight
    atollOnly: true
    atollFace: Component { AtollControlsFace { widget: root } }
    atollSizes: ["small", "medium", "large"]
    atollDefaultSize: "medium"
    semanticPaletteControls: false
    widgetSurfaceEnabled: false
    needsColText: !root.atollFaced

    Loader {
        id: instrumentBody
        anchors.fill: parent
        active: !root.atollFaced
        sourceComponent: ControlsInstrument { widget: root }
    }
}
