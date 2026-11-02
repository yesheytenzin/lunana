pragma ComponentBehavior: Bound

import QtQuick
import "../../style"
import "../../frame"
import "../../components"
import "../../field" as Field
import "../../bar/island" as IslandParts

// The resting Island, drawn by the field like the real one: its rim, glass edge, Afterglow and shadow come from the
// same pass instead of a bordered Rectangle that only resembled them.
Item {
    id: pill
    property bool vertical: false
    readonly property real radius: Math.min(width, height) / 2
    width: pill.vertical ? Math.round(AtollFrame.islandBand) : Math.round(150 * AtollStyle.density)
    height: pill.vertical ? Math.round(150 * AtollStyle.density) : Math.round(AtollFrame.islandBand)
    Field.AtollField {
        anchors.fill: parent
        framed: false
        shapes: [{ id: "island", x: 0, y: 0, width: pill.width, height: pill.height, radius: pill.radius }]
    }
    AtollClock {
        visible: !pill.vertical
        anchors.centerIn: parent
        pixelSize: AtollStyle.typeHeadline
        separatorColor: AtollStyle.secondaryAccent
    }
    IslandParts.IslandStackedClock {
        visible: pill.vertical
        anchors.centerIn: parent
        pixelSize: AtollStyle.typeHeadline
        accent: AtollStyle.secondaryAccent
    }
}
