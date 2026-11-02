pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../../../../services"
import "../../../common/widgets"
import "../../style"
import "../../frame"
import "../../components"
import "../../field" as Field
import "../parts"

PreviewScene {
    id: bubRoot
    readonly property real naturalWidth: Math.round(760 * bubRoot.d)
    readonly property real naturalHeight: Math.round(300 * bubRoot.d)
    readonly property bool snap: bubRoot.opt("atoll.bubbles.snap", true)
    readonly property bool attach: bubRoot.opt("atoll.bubbles.attach", true)
    readonly property bool cluster: bubRoot.opt("atoll.bubbles.cluster", true)
    readonly property bool opensIsland: String(bubRoot.opt("atoll.bubbles.opens", "card")) === "island"
    readonly property bool joined: bubRoot.opt("atoll.appearance.surfaces.cards.joinOrigin", false)
    readonly property real size: AtollFrame.pieceBand
    readonly property real gap: bubRoot.attach ? 0 : Math.round(Math.max(0, Math.min(64, Number(bubRoot.opt("atoll.bubbles.edgeGap", 20)))) * bubRoot.d)
    readonly property real split: bubRoot.cluster ? 0 : Math.round(6 * bubRoot.d)
    readonly property real pad: bubRoot.cluster ? Math.round(4 * bubRoot.d) : 0
    readonly property point home: Qt.point(width - AtollFrame.band - bubRoot.gap - bubRoot.pad - bubRoot.size, AtollFrame.band + bubRoot.gap + bubRoot.pad)
    readonly property point slot: Qt.point(bubRoot.home.x - bubRoot.size - bubRoot.split, bubRoot.home.y)
    readonly property point start: Qt.point(Math.round(width * 0.3), Math.round(height * 0.5))
    readonly property point drop: Qt.point(bubRoot.slot.x - Math.round(34 * bubRoot.d), bubRoot.slot.y + Math.round(46 * bubRoot.d))
    property int step: 0
    readonly property bool grabbed: bubRoot.step === 1
    readonly property bool settled: bubRoot.step >= 2 && bubRoot.step <= 5
    readonly property bool open: bubRoot.step === 4 || bubRoot.step === 5
    readonly property point rest: bubRoot.settled ? (bubRoot.snap ? bubRoot.slot : bubRoot.drop) : bubRoot.start
    property real bx: bubRoot.rest.x
    property real by: bubRoot.rest.y
    Behavior on bx { enabled: !bubRoot.grabbed; NumberAnimation { duration: AtollStyle.moveDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: AtollStyle.moveCurve } }
    Behavior on by { enabled: !bubRoot.grabbed; NumberAnimation { duration: AtollStyle.moveDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: AtollStyle.moveCurve } }
    Binding { when: bubRoot.grabbed; bubRoot.bx: bubPointer.x - bubRoot.size / 2 + bubPointer.width / 2 }
    Binding { when: bubRoot.grabbed; bubRoot.by: bubPointer.y - bubRoot.size / 2 + bubPointer.height / 2 }
    readonly property bool together: bubRoot.cluster && bubRoot.settled && bubRoot.snap
    readonly property bool framed: bubRoot.attach && bubRoot.settled && bubRoot.snap
    property real openness: bubRoot.open ? 1 : 0
    Behavior on openness { NumberAnimation { duration: bubRoot.open ? AtollStyle.emergeDuration : AtollStyle.recedeDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: bubRoot.open ? AtollStyle.emergeCurve : AtollStyle.recedeCurve } }
    readonly property real islandW: Math.round(150 * bubRoot.d + (340 - 150) * bubRoot.d * (bubRoot.opensIsland ? bubRoot.openness : 0))
    readonly property real islandH: Math.round(AtollFrame.islandBand + (130 * bubRoot.d - AtollFrame.islandBand) * (bubRoot.opensIsland ? bubRoot.openness : 0))
    readonly property var card: ({
        x: Math.round(Math.max(AtollFrame.band + 8 * bubRoot.d, Math.min(bubRoot.width - AtollFrame.band - 230 * bubRoot.d, bubRoot.bx + bubRoot.size / 2 - 115 * bubRoot.d))),
        y: Math.round(bubRoot.by + bubRoot.size + (bubRoot.joined ? AtollStyle.weld : AtollFrame.bodyAir)),
        width: Math.round(230 * bubRoot.d),
        height: Math.max(1, Math.round(120 * bubRoot.d * bubRoot.openness))
    })

    Timer {
        running: bubRoot.playing
        interval: 900
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            bubRoot.step = (bubRoot.step + 1) % 7
            if (bubRoot.step === 1 || bubRoot.step === 3) bubPointer.click()
        }
        onRunningChanged: if (!running) bubRoot.step = 2
    }

    Field.AtollField {
        anchors.fill: parent
        shapes: {
            const out = []
            const s = bubRoot.size
            out.push({ x: (bubRoot.width - bubRoot.islandW) / 2, y: AtollFrame.band, width: bubRoot.islandW, height: bubRoot.islandH,
                radius: Math.min(bubRoot.islandH / 2, AtollStyle.radius), fuse: AtollStyle.fuseEdge, id: "island", joins: "frame", paints: true })
            if (bubRoot.together) {
                const w = bubRoot.home.x + s - bubRoot.bx + 2 * bubRoot.pad
                out.push({ x: bubRoot.bx - bubRoot.pad, y: bubRoot.home.y - bubRoot.pad, width: w, height: s + 2 * bubRoot.pad,
                    radius: AtollStyle.pieceRadius(s + 2 * bubRoot.pad), fuse: bubRoot.framed ? AtollStyle.fuseEdge : AtollStyle.fuse,
                    id: "plate", joins: bubRoot.framed ? "frame" : "", paints: true })
            } else {
                out.push({ x: bubRoot.home.x, y: bubRoot.home.y, width: s, height: s, radius: AtollStyle.pieceRadius(s),
                    fuse: bubRoot.attach ? AtollStyle.fuseEdge : AtollStyle.fuse, id: "resident", joins: bubRoot.attach ? "frame" : "", paints: true })
                out.push({ x: bubRoot.bx, y: bubRoot.by, width: s, height: s, radius: AtollStyle.pieceRadius(s),
                    fuse: bubRoot.framed ? AtollStyle.fuseEdge : AtollStyle.fuse, id: "carried", joins: bubRoot.framed ? "frame" : "", paints: true })
            }
            if (!bubRoot.opensIsland && bubRoot.openness > 0.01)
                out.push(Object.assign({ radius: Math.min(AtollStyle.radiusSheet, bubRoot.card.height / 2), fuse: AtollStyle.fuseDeep,
                    id: "card", joins: bubRoot.joined ? (bubRoot.together ? "plate" : "carried") : "", paints: true }, bubRoot.card))
            return out
        }
    }

    AtollClock {
        x: (bubRoot.width - width) / 2
        y: AtollFrame.band + (AtollFrame.islandBand - height) / 2
        opacity: 1 - (bubRoot.opensIsland ? bubRoot.openness : 0)
        pixelSize: AtollStyle.typeHeadline
        separatorColor: AtollStyle.secondaryAccent
    }
    MaterialSymbol {
        x: bubRoot.home.x + (bubRoot.size - width) / 2
        y: bubRoot.home.y + (bubRoot.size - height) / 2
        text: "partly_cloudy_day"; fill: 1
        iconSize: Math.round(bubRoot.size * 0.46)
        color: AtollStyle.identity.sky
    }
    MaterialSymbol {
        x: bubRoot.bx + (bubRoot.size - width) / 2
        y: bubRoot.by + (bubRoot.size - height) / 2
        scale: bubRoot.grabbed ? 1.08 : 1
        Behavior on scale { NumberAnimation { duration: AtollStyle.duration(140); easing.type: AtollStyle.feedbackEasing } }
        text: "volume_up"; fill: 1
        iconSize: Math.round(bubRoot.size * 0.46)
        color: AtollStyle.identity.indigo
    }

    ColumnLayout {
        visible: bubRoot.openness > 0.02
        opacity: AtollStyle.ramp(bubRoot.openness, AtollStyle.dropRise, AtollStyle.dropSpan)
        x: bubRoot.opensIsland ? (bubRoot.width - bubRoot.islandW) / 2 + Math.round(18 * bubRoot.d) : bubRoot.card.x + Math.round(16 * bubRoot.d)
        y: bubRoot.opensIsland ? AtollFrame.band + Math.round(16 * bubRoot.d) : bubRoot.card.y + Math.round(14 * bubRoot.d)
        width: (bubRoot.opensIsland ? bubRoot.islandW : bubRoot.card.width) - Math.round(32 * bubRoot.d)
        spacing: Math.round(10 * bubRoot.d)
        RowLayout {
            spacing: Math.round(8 * bubRoot.d)
            MaterialSymbol { text: "volume_up"; fill: 1; iconSize: Math.round(18 * bubRoot.d); color: AtollStyle.identity.indigo }
            AtollText { text: Translation.tr("Sound"); font.weight: AtollStyle.weight(Font.DemiBold) }
        }
        Level { value: 0.62; tint: AtollStyle.identity.indigo }
        AtollText { text: Translation.tr("Speakers"); color: AtollStyle.muted; font.pixelSize: AtollStyle.typeMeta }
    }

    Pointer {
        id: bubPointer
        grabbing: bubRoot.grabbed
        travel: bubRoot.step === 1 ? 820 : 560
        x: bubRoot.step === 0 ? bubRoot.start.x + bubRoot.size * 0.55
            : bubRoot.step === 1 ? bubRoot.drop.x + bubRoot.size / 2 - width / 2
            : bubRoot.step === 2 ? bubRoot.drop.x + bubRoot.size * 0.9
            : bubRoot.step === 6 ? bubRoot.width * 0.45
            : bubRoot.rest.x + bubRoot.size * 0.55
        y: bubRoot.step === 0 ? bubRoot.start.y + bubRoot.size * 0.55
            : bubRoot.step === 1 ? bubRoot.drop.y + bubRoot.size / 2 - height / 2
            : bubRoot.step === 2 ? bubRoot.drop.y + bubRoot.size * 1.4
            : bubRoot.step === 6 ? bubRoot.height * 0.72
            : bubRoot.rest.y + bubRoot.size * 0.55
    }

    Caption {
        glyph: ["near_me", "back_hand", bubRoot.snap ? "select" : "pan_tool", "touch_app", bubRoot.opensIsland ? "pill" : "web_asset", bubRoot.opensIsland ? "pill" : "web_asset", "undo"][bubRoot.step]
        text: [Translation.tr("A bubble floats over the desktop"),
            Translation.tr("Drag it towards a corner"),
            !bubRoot.snap ? Translation.tr("Snap off: it stays where you let go")
                : (bubRoot.attach ? Translation.tr("Snaps onto the frame") : Translation.tr("Snaps %1 px from the edges").arg(Math.round(bubRoot.gap / bubRoot.d)))
                    + (bubRoot.cluster ? " · " + Translation.tr("grouped into a bar") : ""),
            Translation.tr("Tap it"),
            bubRoot.opensIsland ? Translation.tr("Opens the Island") : bubRoot.joined ? Translation.tr("Grows its card, joined to it") : Translation.tr("Grows its card"),
            bubRoot.opensIsland ? Translation.tr("Opens the Island") : bubRoot.joined ? Translation.tr("Grows its card, joined to it") : Translation.tr("Grows its card"),
            Translation.tr("And back")][bubRoot.step]
    }
}
