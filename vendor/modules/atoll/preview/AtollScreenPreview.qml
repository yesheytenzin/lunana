pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import "../../.."
import "../../../services"
import "../../common"
import "../../common/widgets"
import "../style"
import "../frame"
import "../components"
import "../pieces"
import "../bar/island"
import "../field" as Field

ClippingRectangle {
    id: root

    property var screen: GlobalStates.focusedScreen
    readonly property string screenName: root.screen?.name ?? ""
    readonly property real screenW: Math.max(1, root.screen?.width ?? 1920)
    readonly property real screenH: Math.max(1, root.screen?.height ?? 1080)
    property var focusRect: null
    property real maxScale: 1
    readonly property rect view: {
        const f = root.focusRect
        if (!f || root.width <= 0 || root.height <= 0) return Qt.rect(0, 0, root.screenW, root.screenH)
        const k = Math.min(root.maxScale, root.width / Math.max(1, f.width), root.height / Math.max(1, f.height))
        const w = Math.min(root.screenW, root.width / k)
        const h = Math.min(root.screenH, root.height / k)
        const x = Math.round(Math.max(0, Math.min(root.screenW - w, f.x + f.width / 2 - w / 2)))
        const y = Math.round(Math.max(0, Math.min(root.screenH - h, f.y + f.height / 2 - h / 2)))
        return Qt.rect(x, y, w, h)
    }
    readonly property real s: root.width / Math.max(1, root.view.width)
    readonly property real d: AtollStyle.density
    function reachOf(body: var, edge: string, pad: real): rect {
        switch (edge) {
        case "bottom": return Qt.rect(body.x - pad, body.y - pad, body.width + 2 * pad, root.screenH - body.y + pad)
        case "left": return Qt.rect(0, body.y - pad, body.x + body.width + pad, body.height + 2 * pad)
        case "right": return Qt.rect(body.x - pad, body.y - pad, root.screenW - body.x + pad, body.height + 2 * pad)
        default: return Qt.rect(body.x - pad, 0, body.width + 2 * pad, body.y + body.height + pad)
        }
    }
    readonly property rect islandReach: {
        const g = root.island
        let x0 = g.x, y0 = g.y, x1 = g.x + g.width, y1 = g.y + g.height
        // A full bar spans its edge: look at the middle of it, where the heart rests, not at all of it.
        if (g.fullWidth) {
            if (g.vertical) { const span = root.screenH * 0.4; y0 = (root.screenH - span) / 2; y1 = y0 + span }
            else { const span = root.screenW * 0.4; x0 = (root.screenW - span) / 2; x1 = x0 + span }
        }
        for (const sat of root.satellites) {
            x0 = Math.min(x0, sat.x); y0 = Math.min(y0, sat.y)
            x1 = Math.max(x1, sat.x + sat.width); y1 = Math.max(y1, sat.y + sat.height)
        }
        return root.reachOf({ x: x0, y: y0, width: x1 - x0, height: y1 - y0 }, root.islandEdge, Math.round(28 * root.d))
    }

    readonly property rect dockReach: root.dock ? root.reachOf(root.dock, AtollFrame.dockEdge, Math.round(36 * root.d))
        : Qt.rect(0, 0, root.screenW, root.screenH)

    implicitHeight: Math.round(root.width * root.screenH / root.screenW)
    radius: AtollStyle.radiusTile
    color: AtollStyle.surfaceHigh

    readonly property var bar: Config.options?.atoll?.bar ?? ({})
    readonly property var bubbles: Config.options?.atoll?.bubbles ?? ({})
    readonly property var dockOptions: Config.options?.atoll?.dock ?? ({})
    readonly property bool notch: AtollFrame.notch
    readonly property bool framed: AtollFrame.framed
    readonly property real clockScale: Math.max(0.8, Math.min(1.5, Number(root.bar?.clockScale ?? 100) / 100))
    readonly property color clockAccent: String(root.bar?.clockAccent ?? "highlight") === "accent" ? AtollStyle.accent
        : String(root.bar?.clockAccent ?? "highlight") === "plain" ? AtollStyle.text : AtollStyle.secondaryAccent
    readonly property string clockStyle: String(AtollStyle.structuralValue("atoll.bar.clockStyle", "dateTime"))

    readonly property string layout: String(root.bar?.layout ?? "island")
    readonly property var island: {
        const g = GlobalStates.atollIslandGeometry?.[root.screenName] ?? null
        if (g && g.width > 0 && g.height > 0) {
            const edge = String(g.edge ?? (g.bottomEdge ? "bottom" : "top"))
            return Object.assign({}, g, { edge: edge, vertical: edge === "left" || edge === "right" })
        }
        const edge = AtollFrame.islandEdge
        const vertical = edge === "left" || edge === "right"
        const thick = AtollFrame.islandBand
        const span = vertical ? root.screenH : root.screenW
        const full = root.layout === "full" || root.layout === "menubar"
        const length = full ? span - 2 * (AtollFrame.band + AtollFrame.islandMargin) : Math.round(thick * 4.2)
        const margin = AtollFrame.band + Math.round(16 * root.d)
        const along = full ? AtollFrame.band + AtollFrame.islandMargin : root.layout === "left" ? margin
            : root.layout === "right" ? span - margin - length : Math.round((span - length) / 2)
        const inset = AtollFrame.band + AtollFrame.islandMargin
        const across = edge === "bottom" ? root.screenH - inset - thick : edge === "right" ? root.screenW - inset - thick : inset
        return { x: vertical ? across : along, y: vertical ? along : across,
            width: vertical ? thick : length, height: vertical ? length : thick,
            bubble: thick - Math.round(6 * root.d), gap: Math.round(6 * root.d), edge: edge, vertical: vertical,
            bottomEdge: edge === "bottom", auxiliarySlot: 2, fullWidth: full }
    }
    readonly property string islandEdge: String(root.island.edge ?? "top")
    readonly property var kinds: GlobalStates.atollBubbleKinds?.[root.screenName] ?? ({})

    function satelliteRect(slot: string): var {
        const g = root.island
        const size = Number(g.bubble ?? Math.min(g.width, g.height))
        const gap = Number(g.gap ?? 6)
        const step = size + gap
        const start = g.vertical ? g.y : g.x
        const end = g.vertical ? g.y + g.height : g.x + g.width
        const along = slot === "left" ? start - gap - size / 2
            : slot === "utility" ? end + (Number(g.auxiliarySlot ?? 2) - 1) * step + gap + size / 2
            : end + gap + size / 2
        const across = g.vertical ? g.x + g.width / 2
            : g.bottomEdge ? g.y + g.height - size / 2 : g.y + size / 2
        return g.vertical ? { x: across - size / 2, y: along - size / 2, width: size, height: size }
            : { x: along - size / 2, y: across - size / 2, width: size, height: size }
    }
    readonly property var satellites: ["left", "right", "utility"]
        .filter(slot => String(root.kinds?.[slot] ?? "").length > 0
            && String(root.bubbles?.[slot]?.place ?? "island") === "island")
        .map(slot => Object.assign(root.satelliteRect(slot), { slot: slot, kind: String(root.kinds[slot]) }))

    readonly property var dock: {
        if (!(root.dockOptions?.enable ?? true)) return null
        const published = GlobalStates.atollDockBody?.[root.screenName]
        const body = Array.isArray(published) ? published.find(shape => shape.id === "dock") : null
        if (body && body.width > 0)
            return { x: body.x, y: body.y, width: body.width, height: body.height, radius: body.radius }
        const icon = AtollFrame.dockIcon
        const count = Math.max(4, Math.min(10, root.apps.length))
        const thick = Math.round(icon + 18 * root.d)
        const length = Math.round(count * (icon + 10 * root.d) + 16 * root.d)
        const dockNotch = Boolean(root.dockOptions?.notch ?? false)
        const inset = AtollFrame.band + (dockNotch ? 0 : Math.round(10 * root.d))
        const edge = AtollFrame.dockEdge
        const vertical = edge === "left" || edge === "right"
        const across = edge === "bottom" ? root.screenH - inset - thick : edge === "right" ? root.screenW - inset - thick : inset
        const along = Math.round(((vertical ? root.screenH : root.screenW) - length) / 2)
        return { x: vertical ? across : along, y: vertical ? along : across,
            width: vertical ? thick : length, height: vertical ? length : thick,
            radius: AtollStyle.dockShape !== "auto" ? AtollStyle.profileRadius(AtollStyle.bodyProfile(AtollStyle.dockShape, dockNotch), thick)
                : dockNotch ? Math.round(16 * root.d) : Math.round(thick / 2) }
    }
    readonly property bool dockVertical: AtollFrame.dockEdge === "left" || AtollFrame.dockEdge === "right"
    function edgeBody(edge: string, id: string): var {
        const deep = Math.max(8, AtollStyle.fuseDeep * 2)
        const wide = root.screenW + 4 * AtollStyle.fuseDeep
        const tall = root.screenH + 4 * AtollStyle.fuseDeep
        switch (edge) {
        case "bottom": return { x: -2 * AtollStyle.fuseDeep, y: root.screenH + 1, width: wide, height: deep, radius: 0, fuse: AtollStyle.fuseDeep, id: id }
        case "left": return { x: -deep - 1, y: -2 * AtollStyle.fuseDeep, width: deep, height: tall, radius: 0, fuse: AtollStyle.fuseDeep, id: id }
        case "right": return { x: root.screenW + 1, y: -2 * AtollStyle.fuseDeep, width: deep, height: tall, radius: 0, fuse: AtollStyle.fuseDeep, id: id }
        default: return { x: -2 * AtollStyle.fuseDeep, y: -deep - 1, width: wide, height: deep, radius: 0, fuse: AtollStyle.fuseDeep, id: id }
        }
    }
    readonly property bool menubar: root.layout === "menubar" && !root.island.vertical
    readonly property var zoneLists: root.island.fullWidth && (root.layout === "full" || root.layout === "menubar")
        ? [AtollStyle.structuralValue("bar.fullStart", ["workspaces", "window"]), AtollStyle.structuralValue("bar.fullEnd", ["tray", "notifications", "sound", "controls"])]
        : [[], []]
    readonly property bool dockNotch: Boolean(root.dockOptions?.notch ?? false)
    readonly property var apps: (TaskbarApps.apps ?? []).filter(app => app && !app.separator && String(app.appId ?? "").length > 0 && app.appId !== "SEPARATOR")

    function scaled(shape: var): var {
        const out = Object.assign({}, shape)
        out.x = shape.x * root.s
        out.y = shape.y * root.s
        out.width = shape.width * root.s
        out.height = shape.height * root.s
        out.radius = Number(shape.radius ?? 0) * root.s
        out.fuse = Number(shape.fuse ?? AtollStyle.fuse) * root.s
        out.paints = true
        return out
    }

    Item {
        id: canvas
        x: -root.view.x * root.s
        y: -root.view.y * root.s
        width: root.screenW * root.s
        height: root.screenH * root.s

        AtollWallpaperView {
            live: false
            anchors.fill: parent
            screen: root.screen
            decodeSize: Qt.size(Math.round(Math.max(1, canvas.width) * 1.5), 0)
            opacity: ready ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: AtollStyle.duration(180); easing.type: AtollStyle.feedbackEasing } }
        }

        Field.AtollField {
            anchors.fill: parent
            framed: root.framed
            band: AtollFrame.band * root.s
            cornerRadius: AtollFrame.cornerRadius * root.s
            smoothing: AtollStyle.fuse * root.s
            rimWidth: 1
            shapes: {
                const out = []
                const g = root.island
                if (root.notch && !root.framed) out.push(root.edgeBody(root.islandEdge, "edge"))
                if (root.menubar) {
                    const strip = AtollFrame.islandBand
                    const notchW = Math.round(g.height * 4.2)
                    const inset = root.framed ? AtollFrame.band : 0
                    const clear = String(root.bar?.strip ?? "clear") === "clear"
                    if (clear && !root.notch && !root.framed) out.push(root.edgeBody(root.islandEdge, "edge"))
                    if (!clear) out.push({ x: inset, y: g.edge === "bottom" ? g.y + g.height - strip : g.y,
                        width: root.screenW - 2 * inset, height: strip, radius: 0,
                        fuse: Math.round(16 * root.d), id: "island",
                        joins: !root.notch ? "" : root.framed ? "frame" : "edge" })
                    out.push({ x: g.x + (g.width - notchW) / 2, y: g.y, width: notchW, height: g.height, radius: AtollStyle.profileRadius(AtollStyle.bodyProfile(AtollStyle.barShape, true), g.height),
                        fuse: clear ? AtollStyle.fuseEdge : Math.round(32 * root.d), id: "islandnotch",
                        joins: !clear ? "island" : root.framed ? "frame" : "edge" })
                } else out.push({ x: g.fullWidth && !g.vertical ? (root.framed ? AtollFrame.band : 0) : g.x,
                    y: g.y, width: g.fullWidth && !g.vertical ? root.screenW - (root.framed ? 2 * AtollFrame.band : 0) : g.width,
                    height: g.height, radius: g.fullWidth && !g.vertical ? 0
                        : AtollStyle.profileRadius(AtollStyle.bodyProfile(AtollStyle.barShape, root.notch), Math.min(g.width, g.height)),
                    fuse: g.fullWidth && !g.vertical ? Math.round(16 * root.d) : root.notch ? AtollStyle.fuseEdge : AtollStyle.fuse, id: "island",
                    joins: !root.notch ? "" : root.framed ? "frame" : "edge" })
                for (const sat of root.satellites)
                    out.push({ x: sat.x, y: sat.y, width: sat.width, height: sat.height,
                        radius: AtollStyle.pieceRadius(sat.width), fuse: AtollStyle.fuse, id: "satellite:" + sat.slot, joins: "island" })
                const dk = root.dock
                if (dk) {
                    if (root.dockNotch && !root.framed) out.push(root.edgeBody(AtollFrame.dockEdge, "dockEdge"))
                    out.push({ x: dk.x, y: dk.y, width: dk.width, height: dk.height, radius: dk.radius,
                        fuse: root.dockNotch ? AtollStyle.fuseEdge : AtollStyle.fuse, id: "dock",
                        joins: !root.dockNotch ? "" : root.framed ? "frame" : "dockEdge" })
                }
                return out.map(shape => root.scaled(shape))
            }
        }

        Item {
            id: world
            width: root.screenW
            height: root.screenH
            scale: root.s
            transformOrigin: Item.TopLeft
            layer.enabled: canvas.width > 0 && root.s < 0.999
            layer.smooth: true
            layer.mipmap: true
            layer.textureSize: Qt.size(Math.max(1, Math.ceil(canvas.width * 2)), Math.max(1, Math.ceil(canvas.height * 2)))

            Item {
                id: islandBox
                x: root.island.x
                y: root.island.y
                width: root.island.width
                height: root.island.height

                IslandStackedClock {
                    visible: root.island.vertical
                    anchors.centerIn: parent
                    pixelSize: 15 * AtollStyle.typeScale * root.clockScale
                    accent: root.clockAccent
                    showDay: root.clockStyle === "dateTime"
                }

                Repeater {
                    model: [0, 1]
                    Grid {
                        id: zone
                        required property int modelData
                        readonly property var kinds: Array.from(root.zoneLists[zone.modelData] ?? []).filter(kind => kind !== "island")
                        readonly property real size: Math.round(Math.min(root.island.width, root.island.height) * 0.56)
                        readonly property real inset: Math.round((Math.min(root.island.width, root.island.height) - zone.size) / 2)
                        visible: zone.kinds.length > 0
                        columns: zone.vertical ? 1 : zone.kinds.length
                        spacing: Math.round(6 * root.d)
                        readonly property bool vertical: root?.island?.vertical ?? false
                        x: zone.vertical ? zone.inset : zone.modelData === 0 ? zone.inset * 2 : islandBox.width - width - zone.inset * 2
                        y: !zone.vertical ? zone.inset : zone.modelData === 0 ? zone.inset * 2 : islandBox.height - height - zone.inset * 2
                        Repeater {
                            model: zone.kinds
                            Rectangle {
                                required property string modelData
                                readonly property bool wide: modelData === "workspaces" || modelData === "window"
                                width: root.island.vertical || !wide ? zone.size : zone.size * 2.4
                                height: root.island.vertical && wide ? zone.size * 2.4 : zone.size
                                radius: Math.min(width, height) / 2
                                color: AtollStyle.fill
                            }
                        }
                    }
                }

                RowLayout {
                    visible: !root.island.vertical
                    anchors.centerIn: parent
                    spacing: Math.round(6 * root.d)
                    DateMark {
                        visible: root.clockStyle === "dateTime"
                        Layout.alignment: Qt.AlignVCenter
                        pixelSize: 12 * AtollStyle.typeScale * root.clockScale
                        dayColor: root.clockAccent
                    }
                    Glyph {
                        visible: root.clockStyle === "weather"
                        text: Icons.getWeatherIcon(Weather.data?.wCode, Weather.isNightNow()) ?? "cloud"
                        iconSize: Math.round(16 * root.d)
                        color: AtollStyle.subtext
                    }
                    Tabular {
                        visible: root.clockStyle === "weather"
                        text: String(Weather.data?.temp ?? "").replace(/[CF]$/, "")
                        color: AtollStyle.subtext
                        font.pixelSize: AtollStyle.typeMeta
                        font.weight: AtollStyle.weight(Font.Medium)
                    }
                    AtollClock {
                        Layout.alignment: Qt.AlignVCenter
                        pixelSize: 15 * AtollStyle.typeScale * root.clockScale
                        separatorColor: root.clockAccent
                    }
                }
            }

            Repeater {
                model: root.satellites
                AtollBubbleFace {
                    required property var modelData
                    x: modelData.x
                    y: modelData.y
                    width: modelData.width
                    height: modelData.height
                    bodyless: true
                    screenName: root.screenName
                    kind: modelData.kind
                }
            }

            Grid {
                visible: root.dock !== null
                readonly property real icon: AtollFrame.dockIcon
                readonly property real length: root.dock ? (root.dockVertical ? root.dock.height : root.dock.width) : 0
                readonly property int fits: root.dock ? Math.max(0, Math.floor((length - 16 * root.d) / (icon + 10 * root.d))) : 0
                columns: root.dockVertical ? 1 : Math.max(1, fits)
                x: root.dock ? root.dock.x + (root.dock.width - width) / 2 : 0
                y: root.dock ? root.dock.y + (root.dock.height - height) / 2 : 0
                spacing: Math.round(10 * root.d)
                Repeater {
                    model: root.apps.slice(0, parent.fits)
                    SmartAppIcon {
                        required property var modelData
                        icon: AtollPieces.appIcon(modelData.appId)
                        fallback: "application-x-executable"
                        iconSize: Math.round(AtollFrame.dockIcon)
                    }
                }
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: "transparent"
        border.width: 1
        border.color: AtollStyle.border
    }
}
