pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../lunana-vendor/" as Inir
import "../../lunana-vendor/modules/iris/dock" as LnDock
import "../../lunana-vendor/modules/iris/field" as LnField

// Dock surface — the iRiS dock + its glass field, per output. Input only on the
// dock body (published shapes); the rest passes through. Reveal/auto-hide is
// the dock's own (GlobalStates/Config), shared in this one plugin.
Variants {
    model: Quickshell.screens
    delegate: Component {
        PanelWindow {
            required property var modelData
            screen: modelData
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            exclusiveZone: 0
            WlrLayershell.namespace: "lunana-iris-dock"
            WlrLayershell.layer: WlrLayer.Top
            anchors { top: true; bottom: true; left: true; right: true }
            readonly property var bodyRects: Inir.GlobalStates.irisDockBody?.[modelData.name] ?? []
            readonly property var dockRect: {
                const list = Array.isArray(bodyRects) ? bodyRects.filter(s => s && s.width > 1 && s.height > 1) : []
                if (list.length === 0)
                    return { x: 0, y: 0, width: 0, height: 0 }
                let x0 = Infinity, y0 = Infinity, x1 = -Infinity, y1 = -Infinity
                for (const s of list) {
                    x0 = Math.min(x0, s.x); y0 = Math.min(y0, s.y)
                    x1 = Math.max(x1, s.x + s.width); y1 = Math.max(y1, s.y + s.height)
                }
                const m = 24
                return { x: x0 - m, y: y0 - m, width: x1 - x0 + m * 2, height: y1 - y0 + m * 2 }
            }
            mask: Region {
                x: dockRect.x
                y: dockRect.y
                width: dockRect.width
                height: dockRect.height
            }
            LnField.IrisField {
                anchors.fill: parent
                compositorAllowed: true
                providesBackdrop: true
                shapes: dockItem.bodyShape ?? []
            }
            LnDock.IrisDock {
                id: dockItem
                anchors.fill: parent
                screen: modelData
            }
        }
    }
}
