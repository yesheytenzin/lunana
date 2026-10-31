pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../lunana-vendor/" as Inir
import "../../lunana-vendor/modules/iris/bar" as LnIris
import "../../lunana-vendor/modules/iris/dock" as LnDock
import "../../lunana-vendor/modules/iris/field" as LnField
import "../../lunana-vendor/modules/iris/frame" as LnFrame
import "../../lunana-vendor/modules/iris/style" as LnStyle

// Fused iRiS chassis field — the "warp around" look. One IrisField per output
// draws the island, dock and surround frame as ONE fused glass surface, so the
// island melts into the top band and the frame molds the tiled window area
// around the island/dock (instead of three separate fields that never fuse).
// Replicates inir IrisBar's fieldShapes fusion (satellite→body + frame joins).
// The field is framed when iris.surround.enable is on (IrisFrame.framed).
// The island and dock items render their content on top; input is masked to
// their bodies only, so everything else passes through to windows.
Variants {
    model: Quickshell.screens
    delegate: Component {
        PanelWindow {
            id: chassis
            required property var modelData
            screen: modelData
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            exclusiveZone: 0
            WlrLayershell.namespace: "lunana-iris"
            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            anchors { top: true; bottom: true; left: true; right: true }

            // Input only on the island + dock bodies; the glass passes through.
            readonly property var dockRects: Inir.GlobalStates.irisDockBody?.[chassis.modelData?.name ?? ""] ?? []
            readonly property var dockBounds: {
                const list = Array.isArray(chassis.dockRects) ? chassis.dockRects.filter(s => s && s.width > 1 && s.height > 1) : []
                if (list.length === 0) return { x: 0, y: 0, width: 0, height: 0 }
                let x0 = Infinity, y0 = Infinity, x1 = -Infinity, y1 = -Infinity
                for (const s of list) {
                    x0 = Math.min(x0, s.x); y0 = Math.min(y0, s.y)
                    x1 = Math.max(x1, s.x + s.width); y1 = Math.max(y1, s.y + s.height)
                }
                const m = 24
                return { x: x0 - m, y: y0 - m, width: x1 - x0 + m * 2, height: y1 - y0 + m * 2 }
            }
            mask: Region {
                x: islandItem.x; y: islandItem.y
                width: islandItem.width; height: islandItem.height
                Region {
                    x: chassis.dockBounds.x; y: chassis.dockBounds.y
                    width: chassis.dockBounds.width; height: chassis.dockBounds.height
                }
            }

            // Fused shape set: island + dock + frame pieces, with satellite→body
            // joining and frame fuse (inir IrisBar.fieldShapes, trimmed to the
            // surfaces this consolidated plugin composes in one field).
            readonly property var fieldShapes: {
                const dockBody = dockItem?.bodyShape ?? null
                const hung = (Array.isArray(dockBody) ? dockBody : [])
                    .concat(LnFrame.IrisFrame.placeShapesOn(chassis.screen?.name ?? ""))
                const bodies = hung.filter(shape => shape.joins === "island")
                const island = (islandItem?.fieldShapes ?? []).map(shape => {
                    if (!shape.satellite) return shape
                    const reach = LnStyle.IrisStyle.fuse
                    const body = bodies.find(b => shape.x < b.x + b.width + reach && shape.x + shape.width > b.x - reach
                        && shape.y < b.y + b.height + reach && shape.y + shape.height > b.y - reach)
                    return body ? Object.assign({}, shape, { joins: [body.id].concat(Array.isArray(shape.joins) ? shape.joins.slice(1) : []), fuse: LnStyle.IrisStyle.fuse }) : shape
                })
                const framed = shape => (Array.isArray(shape.joins) ? shape.joins : [shape.joins]).length === 1
                    && (Array.isArray(shape.joins) ? shape.joins[0] : shape.joins) === "frame" && !!shape.id
                const joined = island.concat(hung)
                const all = joined.map(shape => {
                    if (!framed(shape)) return shape
                    let near = null, best = Infinity
                    for (const other of joined) {
                        if (other === shape || !framed(other)) continue
                        const dx = Math.max(0, other.x - shape.x - shape.width, shape.x - other.x - other.width)
                        const dy = Math.max(0, other.y - shape.y - shape.height, shape.y - other.y - other.height)
                        const gap = Math.hypot(dx, dy)
                        if (gap < Number(shape.fuse ?? 0) && gap < best) { best = gap; near = other }
                    }
                    return near ? Object.assign({}, shape, { joins: ["frame", near.id] }) : shape
                })
                if (all.length <= chassisField.capacity) return all
                return all.filter(shape => !shape.paints)
                    .concat(all.filter(shape => shape.paints))
                    .slice(0, chassisField.capacity)
            }

            LnField.IrisField {
                id: chassisField
                anchors.fill: parent
                compositorAllowed: true
                providesBackdrop: true
                shapes: chassis.fieldShapes
            }

            LnDock.IrisDock {
                id: dockItem
                anchors.fill: parent
                screen: chassis.modelData
            }

            LnIris.IrisIsland {
                id: islandItem
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                targetScreen: chassis.modelData
            }
        }
    }
}
