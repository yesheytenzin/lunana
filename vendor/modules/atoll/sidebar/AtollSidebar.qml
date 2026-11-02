pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import "../../.."
import "../../../services"
import "../../common"
import "../../common/functions"
import "../../common/widgets"
import "../../settings"
import "../components"
import "../frame"
import "../style"
import "../field" as Field

PanelWindow {
    id: root
    required property string side
    readonly property bool left: root.side === "left"
    readonly property var options: Config.options?.atoll?.sidebars?.[root.side] ?? ({})
    readonly property bool open: root.left ? GlobalStates.sidebarLeftOpen : GlobalStates.sidebarRightOpen
    readonly property bool pinned: root.options.pinned ?? false
    readonly property real d: AtollStyle.density
    readonly property string outputName: root.left ? GlobalStates.sidebarLeftTargetOutput : GlobalStates.sidebarRightTargetOutput
    readonly property real edgeHeld: AtollFrame.clear(root.left ? "left" : "right") - AtollFrame.band
    readonly property bool notch: (root.options.notch ?? false) && root.edgeHeld <= 0
    readonly property bool peek: root.open && !root.pinned && GlobalStates.atollSidebarPeek === root.side
    property bool editing: false
    property bool contentSettled: false
    Timer { id: settle; interval: 80; onTriggered: root.contentSettled = true }

    property Item settingsOrigin: null
    function publishSettingsOrigin(): void {
        const item = root.settingsOrigin
        if (!item || !item.visible || !root.open) { GlobalStates.atollMorphOwner = ""; return }
        const p = item.mapToItem(null, 0, 0)
        GlobalStates.atollMorphOrigin = { x: p.x, y: p.y, width: item.width, height: item.height,
            radius: item.height / 2, screen: root.screen?.name ?? "" }
        GlobalStates.atollMorphOwner = root.side
    }
    readonly property var expandedSections: root.options.expanded ?? []
    function toggleSection(kind: string): void {
        const next = root.expandedSections.includes(kind)
            ? root.expandedSections.filter(k => k !== kind) : [...root.expandedSections, kind]
        Config.setNestedValue("atoll.sidebars." + root.side + ".expanded", next)
    }
    property int sectionMorphs: 0
    function close(): void {
        if (root.left) GlobalStates.closeSidebarLeft()
        else GlobalStates.closeSidebarRight()
    }
    function opened(): void {
        if (!root.open) return
        const other = root.left ? "right" : "left"
        if (!(Config.options?.atoll?.sidebars?.[other]?.pinned ?? false)) {
            if (root.left) GlobalStates.closeSidebarRight()
            else GlobalStates.closeSidebarLeft()
        }
        GlobalStates.controlPanelOpen = false
        GlobalStates.searchOpen = false
    }
    onOpenChanged: {
        if (root.open) { root.engaged = false; root.opened(); return }
        root.editing = false
        if (GlobalStates.atollSidebarPeek === root.side) GlobalStates.atollSidebarPeek = ""
    }
    Component.onCompleted: root.opened()
    Connections {
        target: GlobalStates
        function onSettingsOverlayOpenChanged(): void {
            if (GlobalStates.settingsOverlayOpen && root.peek) GlobalStates.atollSidebarPeek = ""
            if (!GlobalStates.settingsOverlayOpen && GlobalStates.atollMorphOwner === root.side) root.publishSettingsOrigin()
        }
        function onControlPanelOpenChanged(): void { if (GlobalStates.controlPanelOpen && !root.pinned) root.close() }
        function onSearchOpenChanged(): void { if (GlobalStates.searchOpen && !root.pinned) root.close() }
        function onScreenLockedChanged(): void { if (GlobalStates.screenLocked) root.close() }
    }

    AtollOutputHold {
        id: outputHold
        wanted: Quickshell.screens.find(s => s.name === root.outputName) ?? GlobalStates.focusedScreen
        live: root.visible
    }
    screen: outputHold.output
    visible: root.open || frame.progress > 0
    color: "transparent"
    anchors { left: true; right: true; top: true; bottom: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "quickshell:atoll-sidebar-" + root.side
    Field.AtollBlurRegion {
        id: placeBlur
        window: root
        shapes: frame.blurShapes
        windowWidth: root.width
        windowHeight: root.height
    }
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: !root.open ? WlrKeyboardFocus.None
        : root.pinned || root.peek ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.Exclusive
    mask: ownMask
    Region { id: ownMask; item: !root.open || !frame.armed ? frame : root.pinned || root.peek ? peekZone : dismiss }
    MouseArea { id: dismiss; anchors.fill: parent; enabled: !root.pinned && !root.peek; onClicked: root.close() }

    Item {
        id: peekZone
        readonly property rect live: Qt.rect(root.left ? 0 : frame.x, frame.y,
            root.left ? frame.x + frame.width : root.width - frame.x, frame.height)
        property real x0: 0
        property real y0: 0
        property real x1: 0
        property real y1: 0
        function release(): void {
            x0 = live.x; y0 = live.y; x1 = live.x + live.width; y1 = live.y + live.height
        }
        onLiveChanged: {
            if (!peekHover.hovered) { release(); return }
            x0 = Math.min(x0, live.x); y0 = Math.min(y0, live.y)
            x1 = Math.max(x1, live.x + live.width); y1 = Math.max(y1, live.y + live.height)
        }
        x: x0
        y: y0
        width: x1 - x0
        height: y1 - y0
    }
    HoverHandler {
        id: peekHover
        property point last: Qt.point(-1, -1)
        onHoveredChanged: if (!hovered) peekZone.release()
        onPointChanged: {
            const p = point.position
            if (Math.abs(p.x - last.x) + Math.abs(p.y - last.y) > 2) {
                last = p
                peekZone.release()
            }
        }
    }
    property bool engaged: false
    property real heldTop: 0
    readonly property bool holding: !root.open || (root.engaged && frame.settled)
    readonly property real alignedY: Math.round(root.topInset + (root.availableHeight - frame.height)
        * (root.options.alignment === "top" ? 0 : root.options.alignment === "bottom" ? 1 : 0.5))
    Timer {
        interval: 320
        running: root.peek && !peekHover.hovered && frame.settled
        onTriggered: if (root.peek && !peekHover.hovered) root.close()
    }
    Shortcut {
        sequence: "Escape"
        enabled: root.open
        onActivated: { if (root.editing) root.editing = false; else root.close() }
    }
    Shortcut { sequence: "Ctrl+E"; enabled: root.open; onActivated: root.editing = !root.editing }

    readonly property real edgeGap: (root.notch ? 0 : 12 * root.d) + AtollFrame.band + root.edgeHeld
    readonly property real verticalGap: 12 * root.d
    readonly property real notchOverflow: root.notch ? frame.radius : 0
    readonly property real topInset: root.verticalGap + AtollFrame.safeInset("top")
    readonly property real bottomInset: root.verticalGap + AtollFrame.safeInset("bottom")
    readonly property real availableHeight: Math.max(1, root.height - root.topInset - root.bottomInset)

    AtollMorphSurface {
        motionSurface: "panels"
        // Out of its own edge, never faded: nothing sits between it and that edge to hide behind.
        behindOrigin: false
        id: frame
        compositorBlurred: true
        ownField: !root.notch
        fieldBacked: root.notch
        chassisKey: "sidebar-" + root.side
        chassisJoin: {
            const id = "panel:" + root.side
            if (AtollFrame.framed) return { id: id, joins: "frame", fuse: AtollStyle.fuseEdge }
            const deep = Math.max(8, AtollStyle.fuseEdge)
            return { id: id, joins: "panelEdge:" + root.side, fuse: AtollStyle.fuseEdge,
                edge: { x: root.left ? -deep - 1 : root.width + 1, y: -2 * AtollStyle.fuseEdge, width: deep,
                    height: root.height + 4 * AtollStyle.fuseEdge, radius: 0, paints: true, fuse: 0, id: "panelEdge:" + root.side,
                    glass: AtollStyle.surfaceGlass("panels") } }
        }
        open: root.open
        light: AtollStyle.surfaceLight("panels", AtollStyle.wallpaperLight)
        lightFrom: root.left ? "left" : "right"
        contentScaleFrom: 1
        contentFadeStart: 0
        contentFadeSpan: 0.12
        contentTravels: true
        contentReady: root.contentSettled
        radius: AtollStyle.surfaceRadius("panels", AtollStyle.radius)
        width: Math.round(Math.min(root.width - root.edgeGap * 2, Math.max(300, Math.min(600, root.options.width ?? 380)) * root.d)) + root.notchOverflow
        height: Math.round(Math.min(root.availableHeight * Math.max(0.45, Math.min(1, (root.options.height ?? 88) / 100)),
            panelLayout.implicitHeight + 36 * root.d))
        x: root.left ? root.edgeGap - root.notchOverflow : root.width - width - root.edgeGap + root.notchOverflow
        y: root.holding
            ? Math.round(Math.max(root.topInset, Math.min(root.heldTop, root.topInset + root.availableHeight - height)))
            : root.alignedY
        onYChanged: if (!root.holding) root.heldTop = frame.y
        Behavior on y {
            enabled: frame.settled
            NumberAnimation { duration: AtollStyle.morphDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: AtollStyle.morphCurve }
        }
        Behavior on height {
            enabled: frame.settled && root.sectionMorphs === 0
            NumberAnimation { duration: AtollStyle.morphDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: AtollStyle.morphCurve }
        }
        origin: ({ x: root.left ? 0 : root.width - Math.max(2, AtollFrame.band), y: frame.y,
            width: Math.max(2, AtollFrame.band), height: frame.height, radius: Math.max(1, AtollFrame.band / 2) })
        MouseArea { anchors.fill: parent }
        HoverHandler { id: frameHover; onHoveredChanged: if (hovered) root.engaged = true }
        PointHandler { onActiveChanged: if (active && root.peek) GlobalStates.atollSidebarPeek = "" }

        ColumnLayout {
            id: panelLayout
            anchors.fill: parent
            anchors.margins: 18 * root.d
            anchors.leftMargin: 18 * root.d + (root.left ? root.notchOverflow : 0)
            anchors.rightMargin: 18 * root.d + (root.left ? 0 : root.notchOverflow)
            spacing: 14 * root.d
            RowLayout {
                Layout.fillWidth: true
                spacing: 4 * root.d
                Text {
                    visible: !root.left && !root.editing
                    text: String(DateTime.clock.date.getDate())
                    color: AtollStyle.identity.red
                    font.family: AtollStyle.fontNumbers
                    font.pixelSize: 40 * AtollStyle.typeScale
                    font.weight: AtollStyle.weight(Font.Light)
                    font.features: ({ "tnum": 1 })
                    Layout.alignment: Qt.AlignVCenter
                    Layout.rightMargin: 6 * root.d
                }
                ClippingRectangle {
                    id: headerAvatar
                    visible: root.left && !root.editing
                    property int sourceIndex: 0
                    Layout.preferredWidth: Math.round(42 * root.d)
                    Layout.preferredHeight: Layout.preferredWidth
                    Layout.rightMargin: 8 * root.d
                    radius: width / 2
                    color: AtollStyle.fill
                    AtollImage {
                        id: headerAvatarImage
                        anchors.fill: parent
                        source: Directories.avatarSourceAt(headerAvatar.sourceIndex)
                        onStatusChanged: if (status === Image.Error && headerAvatar.sourceIndex + 1 < Directories.userAvatarPaths.length)
                            Qt.callLater(() => headerAvatar.sourceIndex++)
                    }
                    AtollText {
                        anchors.centerIn: parent
                        visible: headerAvatarImage.status !== Image.Ready
                        text: (SystemInfo.displayName || SystemInfo.username || "?").charAt(0).toUpperCase()
                        font.pixelSize: AtollStyle.typeTitle
                        font.weight: AtollStyle.weight(Font.DemiBold)
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    spacing: 1
                    readonly property int hour: DateTime.clock.date.getHours()
                    AtollText {
                        Layout.fillWidth: true
                        text: root.editing ? Translation.tr("Make it yours")
                            : root.left ? (parent.hour < 5 ? Translation.tr("Good night")
                                : parent.hour < 12 ? Translation.tr("Good morning")
                                : parent.hour < 19 ? Translation.tr("Good afternoon") : Translation.tr("Good evening"))
                            : Translation.locale.toString(DateTime.clock.date, "dddd")
                        font.pixelSize: AtollStyle.typeTitle
                        font.weight: AtollStyle.weight(Font.Bold)
                        elide: Text.ElideRight
                    }
                    AtollText {
                        Layout.fillWidth: true
                        text: root.editing ? Translation.tr("Choose sections and their order")
                            : root.pinned ? Translation.tr("Kept open")
                            : root.left ? (SystemInfo.displayName || SystemInfo.username || "")
                            : Translation.locale.toString(DateTime.clock.date, "MMMM yyyy")
                        role: AtollText.Meta
                        elide: Text.ElideRight
                    }
                }
                AtollControlPlate {
                    id: headerTools
                    Layout.alignment: Qt.AlignVCenter
                    controlHeight: Math.round(34 * root.d)
                    RowLayout {
                        spacing: Math.round(2 * root.d)
                        AtollIconButton {
                            buttonRadius: headerTools.framed ? headerTools.controlRadius : AtollStyle.radiusSmall
                            buttonRadiusPressed: headerTools.framed ? headerTools.controlRadius : Math.max(3, AtollStyle.radiusSmall - 2)
                            materialIcon: "keep"
                            selected: root.pinned
                            Accessible.name: root.pinned ? Translation.tr("Stop keeping open") : Translation.tr("Keep open beside windows")
                            onClicked: Config.setNestedValue("atoll.sidebars." + root.side + ".pinned", !root.pinned)
                        }
                        AtollIconButton {
                            buttonRadius: headerTools.framed ? headerTools.controlRadius : AtollStyle.radiusSmall
                            buttonRadiusPressed: headerTools.framed ? headerTools.controlRadius : Math.max(3, AtollStyle.radiusSmall - 2)
                            materialIcon: root.editing ? "check" : "tune"
                            selected: root.editing
                            Accessible.name: Translation.tr("Customize panel")
                            onClicked: root.editing = !root.editing
                        }
                        AtollIconButton {
                            buttonRadius: headerTools.framed ? headerTools.controlRadius : AtollStyle.radiusSmall
                            buttonRadiusPressed: headerTools.framed ? headerTools.controlRadius : Math.max(3, AtollStyle.radiusSmall - 2)
                            materialIcon: "close"
                            Accessible.name: Translation.tr("Close panel")
                            onClicked: root.close()
                        }
                    }
                }
            }
            Flickable {
                id: scroll
                Layout.fillWidth: true
                Layout.fillHeight: true
                implicitHeight: content.implicitHeight
                contentHeight: content.implicitHeight
                boundsBehavior: Flickable.StopAtBounds
                clip: true
                ScrollBar.vertical: AtollScrollBar {}
                onWidthChanged: contentX = 0
                ColumnLayout {
                    id: content
                    width: scroll.width
                    onImplicitHeightChanged: if (!root.contentSettled) settle.restart()
                    Component.onCompleted: settle.restart()
                    spacing: 14 * root.d
                    Loader {
                        Layout.fillWidth: true
                        active: root.editing
                        visible: active
                        sourceComponent: ColumnLayout {
                            spacing: 16 * root.d
                            AtollSidebarEditor { Layout.fillWidth: true; side: root.side }
                            AtollButton {
                                id: layoutButton
                                Layout.fillWidth: true
                                text: Translation.tr("Panel size and position")
                                onClicked: {
                                    root.settingsOrigin = layoutButton
                                    root.publishSettingsOrigin()
                                    const page = SettingsPageRegistry.pages.findIndex(entry => entry.key === "atoll")
                                    if (page >= 0) GlobalStates.openSettingsPage(page, "sidebars")
                                    else GlobalStates.openSettings()
                                }
                            }
                        }
                    }
                    Repeater {
                        model: root.options.sections ?? (root.left ? ["media", "tasks", "notes"] : ["calendar", "weather", "notifications"])
                        Loader {
                            required property string modelData
                            Layout.fillWidth: true
                            active: !root.editing
                            visible: active
                            sourceComponent: AtollSidebarSection {
                                kind: modelData
                                contentActive: root.open
                                expanded: root.expandedSections.includes(modelData)
                                onNavigate: root.close()
                                onToggleRequested: root.toggleSection(modelData)
                                onMorphingChanged: root.sectionMorphs = Math.max(0, root.sectionMorphs + (morphing ? 1 : -1))
                                Component.onDestruction: if (morphing) root.sectionMorphs = Math.max(0, root.sectionMorphs - 1)
                            }
                        }
                    }
                    AtollButton {
                        Layout.fillWidth: true
                        visible: !root.editing && (root.options.sections?.length ?? 3) === 0
                        text: Translation.tr("Add your first section")
                        onClicked: root.editing = true
                    }
                }
            }
        }
    }
}
