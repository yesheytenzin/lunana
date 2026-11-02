pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../.."
import "../../../services"
import "../../common"
import "../../common/functions"
import "../../common/widgets"
import "../../atoll/style"
import "../../atoll/settings"
import "../../atoll/components"
import "../../atoll/field" as AtollFieldModule

Item {
    id: root

    required property real availableWidth
    required property real availableHeight
    property bool libraryOpen: false
    property string outputName: ""
    property bool hasSelection: false
    property bool gridExpanded: false
    property bool attachedTopEdge: false
    // Atoll draws the body in the chassis field, joined to the frame; the toolbar keeps only its controls.
    property bool bodyless: false

    signal libraryRequested()
    signal settingsRequested()
    signal edgeSettingsRequested()
    signal doneRequested()

    readonly property int gridSize: Config.getNestedValue("background.widgets.editGrid.size", 32)
    readonly property bool snap: Config.getNestedValue("background.widgets.editGrid.snap", true)
    readonly property bool compact: availableWidth < 760
    readonly property int railItemStride: 34
    readonly property int railSlots: Math.max(4, Math.min(root.atoll ? 12 : 14,
        Math.floor(Math.max(railStride * 4, availableWidth - (root.compact ? 330 : 470)) / railStride)))
    readonly property real railWidth: railSlots * railStride - (root.atoll ? root.atollRailSpacing : 0)
    readonly property int atollRailSpacing: Math.round(4 * root.d)
    readonly property var builtinWidgets: [
        { key: "weather", icon: "cloud", label: "Weather", defaultOn: false },
        { key: "customImage", icon: "add_photo_alternate", label: "Custom Image", defaultOn: false },
        { key: "imageConverter", icon: "transform", label: "Image Converter", defaultOn: false },
        { key: "clock", icon: "schedule", label: "Clock", defaultOn: true },
        { key: "mediaControls", icon: "album", label: "Media", defaultOn: false },
        { key: "japaneseTypography", icon: "translate", label: "Japanese Typography", defaultOn: false },
        { key: "visualizer", icon: "graphic_eq", label: "Visualizer", defaultOn: false },
        { key: "systemMonitor", icon: "monitor_heart", label: "System Monitor", defaultOn: false },
        { key: "battery", icon: "battery_full", label: "Battery", defaultOn: false },
        { key: "notes", icon: "sticky_note_2", label: "Notes", defaultOn: false },
        { key: "calendarUpcoming", icon: "event", label: "Upcoming Events", defaultOn: false },
        { key: "monthCalendar", icon: "calendar_month", label: "Month Calendar", defaultOn: false },
        { key: "todo", icon: "checklist", label: "Todo", defaultOn: false },
        { key: "timers", icon: "timer", label: "Timers", defaultOn: false },
        { key: "dayProgress", icon: "timelapse", label: "Day progress", defaultOn: false },
        { key: "uptime", icon: "avg_pace", label: "System Uptime", defaultOn: false },
        { key: "shape", icon: "category", label: "Decorative Shape", defaultOn: false },
        { key: "dateBadge", icon: "today", label: "Date Badge", defaultOn: false },
        { key: "editorial", icon: "text_fields", label: "Editorial", defaultOn: false },
        { key: "mascot", icon: "pets", label: "Mascot", defaultOn: false },
        { key: "newsTicker", icon: "newspaper", label: "News Ticker", defaultOn: false },
        { key: "worldClock", icon: "public", label: "World Clock", defaultOn: false },
        { key: "userCard", icon: "account_circle", label: "User Card", defaultOn: false },
        { key: "controls", icon: "toggle_on", label: "Controls", defaultOn: false, atollOnly: true },
        { key: "screenTime", icon: "hourglass_bottom", label: "Screen Time", defaultOn: false, atollOnly: true }
    ]

    readonly property bool atoll: (Config.options?.panelFamily ?? "drift") === "atoll"
    readonly property real d: root.atoll ? AtollStyle.density : 1
    readonly property real atollSlot: Math.round(30 * root.d)
    readonly property real controlHeight: Math.round(38 * root.d)
    readonly property real railStride: root.atoll ? root.atollSlot + root.atollRailSpacing : root.railItemStride
    readonly property var atollEntries: {
        const out = root.builtinWidgets.map(widget => ({ key: widget.key, icon: widget.icon, label: widget.label,
            tint: AtollStyle.identityOf(DesktopWidgetIdentity.tint(widget.key)),
            on: DesktopWidgetLayout.enabled(root.outputName, widget.key,
                Config.getNestedValue("background.widgets." + widget.key + ".enable", widget.defaultOn)) }))
        for (const custom of (CustomWidgets.ready ? CustomWidgets.widgets : [])) {
            const key = "custom." + custom.id
            out.push({ key: key, icon: custom.icon || "widgets", label: custom.name, tint: AtollStyle.identityOf(DesktopWidgetIdentity.customTint),
                on: DesktopWidgetLayout.enabled(root.outputName, key,
                    Config.getNestedValue("background.widgets.custom." + custom.id + ".enable", false)) })
        }
        return out
    }
    readonly property int atollOnCount: root.atollEntries.filter(entry => entry.on).length
    // ── Finding a widget (Atoll) ───────────────────────────────────────────
    // Spotlight's grammar in the bar's own tiles: the shell's forgiving matcher (AtollSearch), a selection that slides
    // between tiles, ↑/↓/Tab/←/→ to move, ↵ to take it, Escape to clear and then close.
    readonly property string searchText: GlobalStates.widgetSearchText
    property int searchIndex: 0
    property bool pointerArmed: false
    property point lastPointer: Qt.point(-1, -1)
    readonly property bool searching: root.atoll && GlobalStates.widgetSearchOpen && GlobalStates.widgetEditMode
        && (GlobalStates.focusedScreen?.name ?? root.outputName) === root.outputName
    readonly property var searchResults: {
        if (!root.searching) return []
        const entries = AtollSearch.entries().filter(entry => entry.kind === "widget")
        const query = root.searchText.trim()
        const hits = []
        entries.forEach((entry, order) => {
            const score = query.length === 0 ? 1 : AtollSearch.score(query, entry)
            if (score > 0) hits.push({ entry: entry, score: score, order: order })
        })
        hits.sort((a, b) => b.score - a.score || (b.entry.on ? 1 : 0) - (a.entry.on ? 1 : 0) || a.order - b.order)
        return hits.map(hit => hit.entry)
    }
    readonly property var chosen: root.searchResults[Math.min(root.searchIndex, root.searchResults.length - 1)] ?? null
    onSearchTextChanged: root.searchIndex = 0
    function openSearch(): void {
        GlobalStates.widgetSearchOpen = true
        root.searchIndex = 0
        root.pointerArmed = false
        root.lastPointer = Qt.point(-1, -1)
        focusTimer.restart()
    }
    function closeSearch(): void {
        GlobalStates.widgetSearchOpen = false
        GlobalStates.widgetSearchText = ""
    }
    // Escape clears what was typed, then closes.
    function escapeSearch(): void {
        if (root.searchText.length > 0) GlobalStates.widgetSearchText = ""
        else root.closeSearch()
    }
    function moveSearch(step: int): void {
        root.pointerArmed = false
        root.searchIndex = Math.max(0, Math.min(root.searchResults.length - 1, root.searchIndex + step))
    }
    function takeResult(index: int): void {
        const entry = root.searchResults[index]
        if (!entry) return
        root.closeSearch()
        entry.run()
    }
    // A hover only picks a result once the pointer has really moved, so a still pointer never fights the keys.
    function pointerOver(index: int, x: real, y: real): void {
        const moved = root.lastPointer.x >= 0 && (Math.abs(x - root.lastPointer.x) > 0.5 || Math.abs(y - root.lastPointer.y) > 0.5)
        root.lastPointer = Qt.point(x, y)
        if (moved) root.pointerArmed = true
        if (root.pointerArmed && root.searchIndex !== index) root.searchIndex = index
    }
    Connections {
        target: GlobalStates
        function onWidgetSearchCommand(verb: string): void {
            if (!root.searching) return
            if (verb === "next") root.moveSearch(1)
            else if (verb === "previous") root.moveSearch(-1)
            else if (verb === "take") root.takeResult(root.searchIndex)
        }
    }
    Timer { id: focusTimer; interval: 60; onTriggered: searchInput.forceActiveFocus() }
    property var atollOrder: []
    function atollResort(): void {
        const on = root.atollEntries.filter(entry => entry.on).map(entry => entry.key)
        const off = root.atollEntries.filter(entry => !entry.on).map(entry => entry.key)
        root.atollOrder = on.length > 0 && off.length > 0 ? on.concat(["|"], off) : on.concat(off)
    }
    onIrisOnCountChanged: if (!railHover.hovered) root.atollResort()
    Component.onCompleted: root.atollResort()
    readonly property real bodyHeight: root.atoll ? Math.round(56 * root.d) : 48
    readonly property real bodyRadius: root.atoll ? Math.min(AtollStyle.radius, root.bodyHeight / 2) : 0
    readonly property real fillet: root.atoll ? Math.round(root.bodyRadius * 0.62) : 0
    readonly property string inwardTooltipPosition: root.attachedTopEdge ? "bottom" : "top"
    // Searching swaps the middle of the bar for the field and its results; the body keeps the width it had.
    property real idleRowWidth: 0
    Binding { target: root; property: "idleRowWidth"; value: toolbarRow.implicitWidth; when: !root.searching; restoreMode: Binding.RestoreNone }
    readonly property real rowWidth: root.searching ? root.idleRowWidth : toolbarRow.implicitWidth
    readonly property real bodyWidth: root.atoll
        ? Math.min(Math.max(280, availableWidth - 2 * root.fillet),
            Math.max(320, root.rowWidth + 20))
        : Math.min(availableWidth, Math.max(320, root.rowWidth + 12))
    width: root.bodyWidth + (root.atoll ? 2 * root.fillet : 0)
    height: root.bodyHeight

    Item {
        id: bodyFrame
        x: root.atoll ? root.fillet : 0
        width: root.bodyWidth
        height: root.height
    }

    Toolbar {
        anchors.fill: bodyFrame
        padding: 6
        spacing: 4
        transparent: root.atoll
        screenX: root.x
        screenY: root.y
    }

    AtollFieldModule.AtollField {
        id: atollNotchField
        visible: root.atoll && !root.bodyless
        readonly property real pad: AtollStyle.fuseEdge
        readonly property real deep: Math.max(8, AtollStyle.fuseEdge)
        readonly property real bodyTop: root.attachedTopEdge ? atollNotchField.deep - root.bodyRadius : 0
        x: -atollNotchField.pad
        y: root.attachedTopEdge ? -atollNotchField.deep : 0
        width: root.width + 2 * atollNotchField.pad
        height: root.height + atollNotchField.deep
        framed: false
        tint: AtollStyle.surface
        shapes: !root.atoll ? [] : [
            { x: 0, y: root.attachedTopEdge ? 0 : root.height, width: atollNotchField.width, height: atollNotchField.deep,
                radius: 0, paints: true, fuse: 0, id: "edge" },
            { x: atollNotchField.pad + bodyFrame.x, y: atollNotchField.bodyTop, width: root.bodyWidth,
                height: root.bodyHeight + root.bodyRadius, radius: root.bodyRadius, paints: true,
                fuse: AtollStyle.fuseEdge, id: "toolbar", joins: "edge" }
        ]
    }

    // Grid is one control: off, then each lattice size, then off again.
    readonly property var gridSteps: [0, 16, 32, 48, 64]
    function cycleGrid(): void {
        const current = root.snap ? root.gridSize : 0
        const next = root.gridSteps[(Math.max(0, root.gridSteps.indexOf(current)) + 1) % root.gridSteps.length]
        if (next === 0)
            Config.setNestedValue("background.widgets.editGrid.snap", false)
        else
            Config.setNestedValues({ "background.widgets.editGrid.snap": true, "background.widgets.editGrid.size": next })
    }

    // A small round arrow at an end of the rail that scrolls on.
    component RailArrow: Rectangle {
        id: arrow
        property bool leading: true
        property bool shown: false
        property bool usable: true
        signal activated()
        enabled: arrow.usable
        width: root.atoll ? Math.round(24 * root.d) : 26
        height: width
        radius: width / 2
        anchors.verticalCenter: parent ? parent.verticalCenter : undefined
        color: arrowHover.hovered ? (root.atoll ? AtollStyle.fillActive : Appearance.colors.colLayer2Hover)
            : (root.atoll ? AtollStyle.fillHover : Appearance.colors.colLayer2)
        opacity: !arrow.shown ? 0 : arrow.usable ? 1 : 0.35
        visible: opacity > 0
        scale: arrowTap.pressed ? 0.92 : 1
        Behavior on opacity { NumberAnimation { duration: 140 } }
        Behavior on scale { NumberAnimation { duration: 110 } }
        MaterialSymbol {
            anchors.centerIn: parent
            text: arrow.leading ? "chevron_left" : "chevron_right"
            iconSize: root.atoll ? Math.round(15 * root.d) : 17
            color: root.atoll ? AtollStyle.text : Appearance.colors.colOnLayer2
        }
        HoverHandler { id: arrowHover; cursorShape: Qt.PointingHandCursor }
        TapHandler { id: arrowTap; gesturePolicy: TapHandler.WithinBounds; onTapped: arrow.activated() }
        StyledToolTip {
            text: arrow.leading ? Translation.tr("Previous widgets") : Translation.tr("More widgets")
            extraVisibleCondition: arrowHover.hovered
            position: root.atoll ? root.inwardTooltipPosition : "bottom"
        }
    }

    MouseArea {
        anchors.fill: bodyFrame
        z: -1
        acceptedButtons: Qt.AllButtons
    }

    RowLayout {
        id: toolbarRow
        anchors.fill: bodyFrame
        anchors.margins: root.atoll ? Math.round(9 * root.d) : 6
        anchors.leftMargin: root.atoll ? Math.round(10 * root.d) : 6
        anchors.rightMargin: root.atoll ? Math.round(8 * root.d) : 6
        spacing: root.atoll ? Math.round(8 * root.d) : 4

        WidgetEditAction {
            id: libraryAction
            visible: !root.searching
            plate: true
            iconName: "add"
            label: Translation.tr("Add widgets")
            compact: root.compact
            toggled: root.libraryOpen
            tooltip: Translation.tr("Browse every widget")
            tooltipPosition: root.atoll ? root.inwardTooltipPosition : "bottom"
            onClicked: root.libraryRequested()
        }

        Rectangle {
            id: railBox
            visible: !root.searching
            Layout.fillWidth: true
            Layout.minimumWidth: root.railStride * 3
            Layout.preferredWidth: root.railWidth + (root.atoll ? 8 : 0)
            Layout.maximumWidth: root.railWidth + (root.atoll ? 8 : 0)
            Layout.preferredHeight: root.atoll ? root.controlHeight : 34
            radius: height / 2
            color: root.atoll ? AtollStyle.fillQuiet : "transparent"
            // Measured against the box, not the rail, so reserving the arrow slots cannot feed back.
            readonly property bool overflows: widgetRow.implicitWidth > railBox.width - (root.atoll ? 8 : 0)

            Flickable {
                id: widgetRail
                // Arrows take their own slot at an end that scrolls, so they never sit on a tile, and the
                // view is a whole number of slots so no tile is cut at its edge.
                readonly property real room: railBox.width - 2 * (root.atoll ? 4 : 0) - (railBox.overflows ? 60 : 0)
                width: railBox.overflows
                    ? Math.max(root.railStride, Math.floor((widgetRail.room + (root.atoll ? root.atollRailSpacing : 0)) / root.railStride) * root.railStride
                        - (root.atoll ? root.atollRailSpacing : 0))
                    : widgetRail.room
                height: railBox.height
                x: Math.round((railBox.width - widgetRail.width) / 2)
                contentWidth: widgetRow.implicitWidth
                contentHeight: height
                clip: true
                interactive: contentWidth > width
                boundsBehavior: Flickable.StopAtBounds
                flickableDirection: Flickable.HorizontalFlick
                readonly property bool canBack: widgetRail.contentX > 1
                readonly property bool canForward: widgetRail.contentX < Math.max(0, widgetRail.contentWidth - widgetRail.width) - 1

                function snapContentX(value: real): real {
                    const maxX = Math.max(0, contentWidth - width)
                    const snapped = Math.round(value / root.railStride) * root.railStride
                    return Math.max(0, Math.min(maxX, snapped))
                }

                function scrollPage(direction: int): void {
                    const page = Math.max(root.railStride, Math.floor(width / root.railStride - 1) * root.railStride)
                    contentX = snapContentX(contentX + direction * page)
                }

                Behavior on contentX {
                    enabled: !widgetRail.moving
                    NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
                }
                onMovementEnded: contentX = snapContentX(contentX)
                onWidthChanged: railSnapSettle.restart()
                onContentWidthChanged: railSnapSettle.restart()

                Timer {
                    id: railSnapSettle
                    interval: 0
                    onTriggered: widgetRail.contentX = widgetRail.snapContentX(widgetRail.contentX)
                }

                WheelHandler {
                    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                    onWheel: event => {
                        const horizontal = event.angleDelta.x
                        const vertical = event.angleDelta.y
                        const delta = Math.abs(horizontal) > Math.abs(vertical) ? -horizontal : -vertical
                        if (delta !== 0)
                            widgetRail.contentX = widgetRail.snapContentX(widgetRail.contentX
                                + (delta > 0 ? root.railStride * 3 : -root.railStride * 3))
                        event.accepted = true
                    }
                }

                HoverHandler {
                    id: railHover
                    onHoveredChanged: if (!hovered) root.atollResort()
                }

                Row {
                    id: widgetRow
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: root.atoll ? root.atollRailSpacing : 2

                    Repeater {
                        model: root.atoll ? root.atollOrder : []
                        Item {
                            id: atollSlot
                            required property string modelData
                            readonly property var entry: root.atollEntries.find(item => item.key === atollSlot.modelData) ?? null
                            width: root.atollSlot
                            height: railBox.height
                            Rectangle {
                                visible: !atollSlot.entry
                                anchors.centerIn: parent
                                width: 1
                                height: Math.round(16 * root.d)
                                color: AtollStyle.hairlineStrong
                            }
                            WidgetEditAction {
                                visible: atollSlot.entry !== null
                                compact: true
                                tileTint: atollSlot.entry?.tint ?? "transparent"
                                iconName: atollSlot.entry?.icon ?? ""
                                label: Translation.tr(atollSlot.entry?.label ?? "")
                                tooltip: (atollSlot.entry?.on ? Translation.tr("%1 · on, click to remove") : Translation.tr("%1 · click to add"))
                                    .arg(Translation.tr(atollSlot.entry?.label ?? ""))
                                tooltipPosition: root.inwardTooltipPosition
                                toggled: atollSlot.entry?.on ?? false
                                onClicked: DesktopWidgetLayout.setGloballyEnabled(atollSlot.modelData, !(atollSlot.entry?.on ?? false))
                            }
                        }
                    }

                    Repeater {
                        model: root.atoll ? [] : root.builtinWidgets.filter(widget => !widget.atollOnly)
                        WidgetEditAction {
                            required property var modelData
                            readonly property bool widgetEnabled: DesktopWidgetLayout.enabled(
                                root.outputName, modelData.key,
                                Config.getNestedValue("background.widgets." + modelData.key + ".enable", modelData.defaultOn))
                            compact: true
                            iconName: modelData.icon
                            label: Translation.tr(modelData.label)
                            tooltip: Translation.tr(modelData.label)
                            tooltipPosition: "bottom"
                            toggled: widgetEnabled
                            onClicked: DesktopWidgetLayout.setGloballyEnabled(modelData.key, !widgetEnabled)
                        }
                    }

                    Repeater {
                        model: !root.atoll && CustomWidgets.ready ? CustomWidgets.widgets : []
                        WidgetEditAction {
                            required property var modelData
                            readonly property string layoutKey: "custom." + modelData.id
                            readonly property bool widgetEnabled: DesktopWidgetLayout.enabled(
                                root.outputName, layoutKey,
                                Config.getNestedValue("background.widgets.custom." + modelData.id + ".enable", false))
                            compact: true
                            iconName: modelData.icon || "widgets"
                            label: modelData.name
                            tooltip: modelData.name
                            tooltipPosition: "bottom"
                            toggled: widgetEnabled
                            onClicked: DesktopWidgetLayout.setGloballyEnabled(layoutKey, !widgetEnabled)
                        }
                    }
                }
            }

            RailArrow {
                id: backArrow
                anchors.left: parent.left
                anchors.leftMargin: 6
                leading: true
                shown: railBox.overflows
                usable: widgetRail.canBack
                onActivated: widgetRail.scrollPage(-1)
            }
            RailArrow {
                id: forwardArrow
                anchors.right: parent.right
                anchors.rightMargin: 6
                leading: false
                shown: railBox.overflows
                usable: widgetRail.canForward
                onActivated: widgetRail.scrollPage(1)
            }
        }

        // Grid, screen edges and settings share one quiet pill, concentric with the rail beside it.
        Rectangle {
            id: toolsBox
            visible: !root.searching
            Layout.preferredHeight: root.atoll ? root.controlHeight : 34
            Layout.preferredWidth: toolsRow.implicitWidth + (root.atoll ? Math.round(8 * root.d) : 0)
            radius: height / 2
            color: root.atoll ? AtollStyle.fillQuiet : "transparent"

            RowLayout {
                id: toolsRow
                anchors.centerIn: parent
                spacing: root.atoll ? Math.round(2 * root.d) : 4

                WidgetEditAction {
                    visible: root.atoll
                    compact: true
                    inPill: true
                    iconName: "search"
                    label: Translation.tr("Search widgets")
                    tooltip: Translation.tr("Search widgets (Ctrl+F)")
                    tooltipPosition: root.inwardTooltipPosition
                    toggled: root.searching
                    onClicked: root.searching ? root.closeSearch() : root.openSearch()
                }

                WidgetEditAction {
                    id: gridAction
                    inPill: true
                iconName: "grid_on"
                    label: root.snap ? Translation.tr("Grid %1").arg(root.gridSize) : Translation.tr("No grid")
                    compact: root.compact
                    toggled: root.snap
                    tooltip: root.snap ? Translation.tr("Widgets snap to a %1 px grid · click for the next size").arg(root.gridSize)
                        : Translation.tr("Widgets move freely · click to snap them to a grid")
                    tooltipPosition: root.atoll ? root.inwardTooltipPosition : "bottom"
                    onClicked: root.cycleGrid()
                }

                WidgetEditAction {
                    compact: true
                    iconName: "border_outer"
                    label: Translation.tr("Screen edges")
                    tooltip: Translation.tr("Organic edge settings")
                    tooltipPosition: root.atoll ? root.inwardTooltipPosition : "bottom"
                    onClicked: root.edgeSettingsRequested()
                }

                WidgetEditAction {
                    compact: true
                    iconName: "settings"
                    label: Translation.tr("Widget settings")
                    tooltip: Translation.tr("Every widget option in Settings")
                    tooltipPosition: root.atoll ? root.inwardTooltipPosition : "bottom"
                    onClicked: root.settingsRequested()
                }
            }
        }

        Rectangle {
            id: searchBox
            visible: root.searching
            Layout.fillWidth: true
            Layout.preferredHeight: root.controlHeight
            radius: height / 2
            color: AtollStyle.fillQuiet

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Math.round(14 * root.d)
                anchors.rightMargin: Math.round(12 * root.d)
                spacing: Math.round(8 * root.d)

                MaterialSymbol {
                    Layout.alignment: Qt.AlignVCenter
                    text: "search"
                    iconSize: Math.round(18 * root.d)
                    color: root.searchText.length > 0 ? AtollStyle.accent : AtollStyle.subtext
                }
                TextInput {
                    id: searchInput
                    Layout.preferredWidth: Math.round(184 * root.d)
                    Layout.alignment: Qt.AlignVCenter
                    text: root.searchText
                    color: AtollStyle.text
                    selectionColor: AtollStyle.accentContainer
                    selectedTextColor: AtollStyle.inkOnAccentContainer
                    font.family: AtollStyle.fontMain
                    font.pixelSize: AtollStyle.typeBody
                    clip: true
                    onTextChanged: if (GlobalStates.widgetSearchText !== text) GlobalStates.widgetSearchText = text
                    Keys.onPressed: event => {
                        const atEnd = searchInput.cursorPosition >= searchInput.text.length && searchInput.selectedText.length === 0
                        const atStart = searchInput.cursorPosition === 0 && searchInput.selectedText.length === 0
                        if (event.key === Qt.Key_Down || event.key === Qt.Key_Tab || (event.key === Qt.Key_Right && atEnd))
                            root.moveSearch(1)
                        else if (event.key === Qt.Key_Up || event.key === Qt.Key_Backtab || (event.key === Qt.Key_Left && atStart))
                            root.moveSearch(-1)
                        else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter)
                            root.takeResult(root.searchIndex)
                        else if (event.key === Qt.Key_F && (event.modifiers & Qt.ControlModifier))
                            searchInput.selectAll()
                        else
                            return
                        event.accepted = true
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: searchInput.text.length === 0
                        text: Translation.tr("Search widgets")
                        color: AtollStyle.muted
                        font.family: searchInput.font.family
                        font.pixelSize: searchInput.font.pixelSize
                    }
                }
                Rectangle {
                    Layout.alignment: Qt.AlignVCenter
                    Layout.preferredWidth: Math.round(20 * root.d)
                    Layout.preferredHeight: Layout.preferredWidth
                    radius: width / 2
                    opacity: root.searchText.length > 0 ? 1 : 0
                    enabled: root.searchText.length > 0
                    color: clearHover.hovered ? AtollStyle.fillActive : AtollStyle.fillHover
                    Behavior on opacity { NumberAnimation { duration: AtollStyle.feedbackDuration } }
                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "close"
                        iconSize: Math.round(13 * root.d)
                        color: AtollStyle.textSecondary
                    }
                    HoverHandler { id: clearHover; cursorShape: Qt.PointingHandCursor }
                    TapHandler { onTapped: { GlobalStates.widgetSearchText = ""; searchInput.forceActiveFocus() } }
                    Accessible.role: Accessible.Button
                    Accessible.name: Translation.tr("Clear")
                }
                Rectangle {
                    Layout.alignment: Qt.AlignVCenter
                    Layout.leftMargin: Math.round(4 * root.d)
                    Layout.rightMargin: Math.round(4 * root.d)
                    Layout.preferredWidth: 1
                    Layout.preferredHeight: Math.round(16 * root.d)
                    color: AtollStyle.hairlineStrong
                }

                // The widgets that answer, in the rail's own tiles, in whole slots; the selection slides between them.
                Item {
                    id: resultsBox
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    Flickable {
                        id: resultsView
                        anchors.verticalCenter: parent.verticalCenter
                        height: parent.height
                        // Room at both ends for the selection to breathe, so a tile is never pressed against the edge of
                        // the view: whole slots between two equal margins, centred in what the name leaves.
                        // As wide as the gap between tiles, so the next tile never shows as a sliver at the edge.
                        readonly property real pad: root.atollRailSpacing
                        readonly property int fits: Math.max(1, Math.floor((resultsBox.width - 2 * resultsView.pad + root.atollRailSpacing) / root.railStride))
                        leftMargin: resultsView.pad
                        rightMargin: resultsView.pad
                        width: Math.min(root.searchResults.length, resultsView.fits) * root.railStride - root.atollRailSpacing + 2 * resultsView.pad
                        x: Math.round((resultsBox.width - width) / 2)
                        contentWidth: root.searchResults.length * root.railStride - root.atollRailSpacing
                        contentHeight: height
                        clip: true
                        interactive: root.searchResults.length > resultsView.fits
                        flickableDirection: Flickable.HorizontalFlick
                        boundsBehavior: Flickable.StopAtBounds

                        readonly property real plateX: root.searchIndex * root.railStride - Math.round(2 * root.d)
                        Behavior on contentX {
                            enabled: !resultsView.moving
                            NumberAnimation { duration: AtollStyle.duration(140); easing.type: AtollStyle.feedbackEasing }
                        }
                        function reveal(): void {
                            const plate = root.atollSlot + Math.round(4 * root.d)
                            const room = resultsView.pad - Math.round(2 * root.d)
                            const low = -resultsView.leftMargin
                            const high = Math.max(low, resultsView.contentWidth + resultsView.rightMargin - resultsView.width)
                            let target = resultsView.contentX
                            if (resultsView.plateX - room < target) target = resultsView.plateX - room
                            else if (resultsView.plateX + plate + room > target + resultsView.width) target = resultsView.plateX + plate + room - resultsView.width
                            resultsView.contentX = Math.max(low, Math.min(high, target))
                        }
                        Connections { target: root; function onSearchIndexChanged(): void { resultsView.reveal() } }

                        WheelHandler {
                            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                            onWheel: event => {
                                const delta = Math.abs(event.angleDelta.x) > Math.abs(event.angleDelta.y) ? -event.angleDelta.x : -event.angleDelta.y
                                const low = -resultsView.leftMargin
                                const high = Math.max(low, resultsView.contentWidth + resultsView.rightMargin - resultsView.width)
                                resultsView.contentX = Math.max(low, Math.min(high,
                                    resultsView.contentX + (delta > 0 ? 1 : -1) * root.railStride * 2))
                                event.accepted = true
                            }
                        }

                        // Spotlight's selection: the accent wash, one radius wider than what it holds.
                        Rectangle {
                            visible: root.searchResults.length > 0
                            x: resultsView.plateX
                            anchors.verticalCenter: parent.verticalCenter
                            width: root.atollSlot + Math.round(4 * root.d)
                            height: width
                            radius: AtollStyle.radiusRow
                            color: AtollStyle.tintFill(AtollStyle.accent)
                            Behavior on x { NumberAnimation { duration: AtollStyle.duration(120); easing.type: AtollStyle.feedbackEasing } }
                        }

                        Row {
                            id: resultsRow
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: root.atollRailSpacing

                            Repeater {
                                model: ScriptModel { values: root.searchResults; objectProp: "name" }

                                Item {
                                    id: hit
                                    required property var modelData
                                    required property int index
                                    width: root.atollSlot
                                    height: railBox.height

                                    WidgetEditAction {
                                        compact: true
                                        badge: false
                                        tileTint: hit.modelData.tint
                                        iconName: hit.modelData.icon
                                        label: hit.modelData.name
                                        toggled: hit.modelData.on
                                        tooltip: hit.modelData.name
                                        tooltipPosition: root.inwardTooltipPosition
                                        onClicked: root.takeResult(hit.index)
                                    }
                                    HoverHandler {
                                        onPointChanged: root.pointerOver(hit.index, point.scenePosition.x, point.scenePosition.y)
                                    }
                                }
                            }
                        }
                    }

                    AtollText {
                        visible: root.searchResults.length === 0
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: Translation.tr("No widget called “%1”").arg(root.searchText.trim())
                        color: AtollStyle.textSecondary
                        font.pixelSize: AtollStyle.typeLabel
                    }
                }

                // What ↵ will do, as Spotlight says it: the name, the verb and the key.
                RowLayout {
                    visible: root.chosen !== null
                    Layout.alignment: Qt.AlignVCenter
                    Layout.fillWidth: false
                    // As wide as the longest name among the results, so it does not move while the selection does.
                    Layout.preferredWidth: Math.min(Math.round(230 * root.d), Math.ceil(nameMetrics.width + verbMetrics.width + Math.round((24 + 16 + 4) * root.d)))
                    spacing: Math.round(8 * root.d)

                    TextMetrics {
                        id: nameMetrics
                        font.family: AtollStyle.fontMain
                        font.pixelSize: AtollStyle.typeLabel
                        font.weight: AtollStyle.weight(Font.DemiBold)
                        text: root.searchResults.reduce((longest, entry) => entry.name.length > longest.length ? entry.name : longest, "")
                    }
                    TextMetrics {
                        id: verbMetrics
                        font.family: AtollStyle.fontMain
                        font.pixelSize: AtollStyle.typeMeta
                        text: Translation.tr("Show").length > Translation.tr("Add").length ? Translation.tr("Show") : Translation.tr("Add")
                    }

                    AtollText {
                        Layout.fillWidth: true
                        text: root.chosen?.name ?? ""
                        font.pixelSize: AtollStyle.typeLabel
                        font.weight: AtollStyle.weight(Font.DemiBold)
                        horizontalAlignment: Text.AlignRight
                        elide: Text.ElideRight
                    }
                    AtollText {
                        text: root.chosen ? (root.chosen.on ? Translation.tr("Show") : Translation.tr("Add")) : ""
                        color: AtollStyle.subtext
                        font.pixelSize: AtollStyle.typeMeta
                    }
                    Rectangle {
                        Layout.preferredWidth: Math.round(24 * root.d)
                        Layout.preferredHeight: Math.round(20 * root.d)
                        radius: AtollStyle.radiusChip
                        color: AtollStyle.fill
                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: "keyboard_return"
                            iconSize: Math.round(14 * root.d)
                            color: AtollStyle.text
                        }
                    }
                }
            }
        }

        WidgetEditAction {
            id: doneAction
            iconName: "check"
            label: Translation.tr("Done")
            compact: root.availableWidth < 560
            primary: true
            tooltip: Translation.tr("Done editing")
            tooltipPosition: root.atoll ? root.inwardTooltipPosition : "bottom"
            onClicked: root.doneRequested()
        }
    }
}
