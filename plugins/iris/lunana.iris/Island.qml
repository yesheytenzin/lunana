pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../lunana-vendor/modules/iris/bar" as LnIris
import "../../lunana-vendor/modules/iris/field" as LnField

// Island surface — the morphing pill + its glass field, per output.
// Always present (the iRiS panel). Input only on the island body; everything
// else passes through. Part of the consolidated lunana.iris plugin, so it
// shares one GlobalStates with the settings/session/sidebar/control surfaces
// it drives through the island's own buttons.
Variants {
    model: Quickshell.screens
    delegate: Component {
        PanelWindow {
            required property var modelData
            screen: modelData
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            exclusiveZone: 0
            WlrLayershell.namespace: "lunana-iris"
            WlrLayershell.layer: WlrLayer.Top
            anchors { top: true; bottom: true; left: true; right: true }
            mask: Region {
                x: islandItem.x
                y: islandItem.y
                width: islandItem.width
                height: islandItem.height
            }
            LnField.IrisField {
                anchors.fill: parent
                compositorAllowed: true
                providesBackdrop: true
                shapes: islandItem.fieldShapes ?? []
            }
            LnIris.IrisIsland {
                id: islandItem
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                targetScreen: modelData
            }
        }
    }
}
