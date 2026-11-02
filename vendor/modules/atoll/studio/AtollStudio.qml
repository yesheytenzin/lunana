pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../../.."
import "../../../services"
import "../../common"
import "../../common/widgets"
import "../frame"
import "../components"
import "../settings"
import "../style"
import "../preview"
import "../edit"

// Studio: Customize as a panel beside the screen (atoll.appearance.customize "studio"). Every area in one
// column, one forgiving search across all of them, the same rows and history as Customize on the shell.
PanelWindow {
    id: root
    readonly property real d: AtollStyle.density
    property string target: "material"

    readonly property var areas: AtollOptions.customizeAreas
    readonly property var railGroups: [["material", "colour", "type", "motion"],
        ["island", "pieces", "bodies", "places", "transients", "dock", "desktop"], ["themes"]]
    function areaOf(id: string): var { return AtollOptions.customizeArea(id) }
    function tipOf(area: var): string { return AtollOptions.customizeTip(area.id) }

    readonly property var specifications: AtollOptions.studio
    readonly property var groups: {
        Config.revision
        const out = []
        for (const spec of root.specifications) {
            if (spec.target !== root.target || !AtollOptions.shown(spec)) continue
            if (out.length === 0 || out[out.length - 1].title !== spec.group) out.push({ title: spec.group, rows: [] })
            out[out.length - 1].rows.push(spec)
        }
        return out
    }
    function modifiedIn(id: string): int {
        void Config.revision
        const counted = new Set()
        for (const spec of root.specifications) {
            if (spec.target !== id || !String(spec.path).startsWith("atoll.") || spec.fallback === undefined || counted.has(spec.path)) continue
            if (!AtollOptions.same(Config.getNestedValue(spec.path, spec.fallback), spec.fallback)) counted.add(spec.path)
        }
        return counted.size
    }
    function resetArea(): void {
        const updates = {}
        for (const spec of root.specifications)
            if (spec.target === root.target && String(spec.path).startsWith("atoll.") && spec.fallback !== undefined) updates[spec.path] = spec.fallback
        Config.setNestedValues(updates)
        AtollEditHistory.say(Translation.tr("%1 is back to how Atoll comes").arg(Translation.tr(root.areaOf(root.target).label)))
    }

    // Search reads every area the forgiving way Spotlight does; results stay grouped under their area.
    property string query: ""
    readonly property var searchable: root.specifications.filter(spec => !spec.mirror).map(spec => AtollSearch.prepare({
        name: Translation.tr(spec.label), english: spec.label, detail: Translation.tr(spec.group ?? ""),
        areaName: Translation.tr(root.areaOf(spec.target).label), words: [spec.group ?? ""].concat(spec.keywords ?? []).join(" "), description: spec.description ?? "",
        spec: spec }))
    readonly property var matches: {
        void Config.revision
        const q = root.query.trim()
        if (q.length === 0) return []
        const scored = root.searchable.filter(entry => AtollOptions.shown(entry.spec))
            .map(entry => ({ entry: entry, score: AtollSearch.score(q, entry) })).filter(hit => hit.score >= 0.55)
        scored.sort((a, b) => b.score - a.score)
        const out = []
        for (const hit of scored) {
            const area = root.areaOf(hit.entry.spec.target)
            let block = out.find(item => item.area.id === area.id)
            if (!block) { block = { area: area, title: area.label, rows: [] }; out.push(block) }
            block.rows.push(hit.entry.spec)
        }
        return out
    }

    function select(id: string): void {
        if (id === root.target) return
        root.target = id
        flick.contentY = 0
    }
    function takeRequest(): void {
        const wanted = GlobalStates.atollStudioTarget
        if (wanted.length === 0) return
        GlobalStates.atollStudioTarget = ""
        if (wanted.startsWith("search:")) searchField.text = wanted.slice(7)
        else if (root.areas.some(area => area.id === wanted)) { searchField.text = ""; root.select(wanted) }
    }
    Component.onCompleted: root.takeRequest()
    Connections {
        target: GlobalStates
        function onIrisStudioTargetChanged(): void { root.takeRequest() }
    }

    visible: GlobalStates.atollStudioOpen || frame.progress > 0
    AtollOutputHold {
        id: outputHold
        wanted: GlobalStates.focusedScreen
        live: root.visible
    }
    screen: outputHold.output
    color: "transparent"
    anchors { left: true; top: true; bottom: true }
    implicitWidth: frame.width + Math.round(24 * root.d) + AtollFrame.clear("left")
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "quickshell:atoll-studio"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: GlobalStates.atollStudioOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    mask: Region { item: frame }

    Shortcut {
        sequence: "Escape"
        enabled: GlobalStates.atollStudioOpen
        onActivated: {
            if (root.query.length > 0) searchField.text = ""
            else GlobalStates.atollStudioOpen = false
        }
    }
    Shortcut { sequences: [StandardKey.Undo]; enabled: GlobalStates.atollStudioOpen; onActivated: AtollEditHistory.undo() }
    Shortcut { sequences: [StandardKey.Redo, "Ctrl+Shift+Z"]; enabled: GlobalStates.atollStudioOpen; onActivated: AtollEditHistory.redo() }
    Shortcut { sequence: "Ctrl+F"; enabled: GlobalStates.atollStudioOpen; onActivated: searchField.forceActiveFocus() }

    AtollMorphSurface {
        id: frame
        open: GlobalStates.atollStudioOpen
        motionSurface: "settings"
        radius: AtollStyle.surfaceRadius("settings", AtollStyle.radiusPanel)
        light: AtollStyle.surfaceLight("settings", AtollStyle.wallpaperLight)
        x: Math.round(12 * root.d) + AtollFrame.clear("left")
        y: (parent.height - height) / 2
        width: Math.min((root.screen?.width ?? 1920) - Math.round(48 * root.d) - AtollFrame.band * 2, Math.round(560 * root.d))
        height: Math.min(parent.height - Math.round(24 * root.d) - AtollFrame.band * 2, Math.round(960 * root.d))
        MouseArea { anchors.fill: parent }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: AtollStyle.concentricPad(frame.radius, 16 * root.d)
            spacing: Math.round(12 * root.d)

            RowLayout {
                Layout.fillWidth: true
                spacing: Math.round(8 * root.d)
                AtollMark { implicitSize: Math.round(24 * root.d) }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    AtollText {
                        text: Translation.tr("Studio")
                        font.family: AtollStyle.fontTitle
                        font.pixelSize: AtollStyle.typeTitle
                        font.weight: AtollStyle.weight(Font.Bold)
                    }
                    AtollText {
                        Layout.fillWidth: true
                        text: AtollEditHistory.notice.length > 0 ? AtollEditHistory.notice : Translation.tr("Everything you change is the shell itself")
                        color: AtollEditHistory.notice.length > 0 ? AtollStyle.accent : AtollStyle.muted
                        font.pixelSize: AtollStyle.typeFootnote
                        elide: Text.ElideRight
                    }
                }
                AtollIconButton {
                    materialIcon: "undo"
                    enabled: AtollEditHistory.undoStack.length > 0
                    opacity: enabled ? 1 : 0.35
                    Accessible.name: Translation.tr("Undo")
                    onClicked: AtollEditHistory.undo()
                }
                AtollIconButton {
                    materialIcon: "redo"
                    enabled: AtollEditHistory.redoStack.length > 0
                    opacity: enabled ? 1 : 0.35
                    Accessible.name: Translation.tr("Redo")
                    onClicked: AtollEditHistory.redo()
                }
                Rectangle { implicitWidth: 1; implicitHeight: Math.round(18 * root.d); color: AtollStyle.hairline }
                AtollIconButton {
                    materialIcon: "touch_app"
                    Accessible.name: Translation.tr("Customize on the shell")
                    onClicked: {
                        GlobalStates.atollEditTarget = root.target
                        GlobalStates.atollEdit = true
                    }
                }
                AtollIconButton {
                    materialIcon: "tune"
                    Accessible.name: Translation.tr("All settings")
                    onClicked: { GlobalStates.atollStudioOpen = false; GlobalStates.openSettings() }
                }
                AtollIconButton {
                    materialIcon: "close"
                    Accessible.name: Translation.tr("Close Studio")
                    onClicked: GlobalStates.atollStudioOpen = false
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: Math.round(36 * root.d)
                radius: height / 2
                color: searchField.activeFocus ? AtollStyle.fill : AtollStyle.fillQuiet
                Behavior on color { ColorAnimation { duration: AtollStyle.duration(120); easing.type: AtollStyle.feedbackEasing } }
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Math.round(12 * root.d)
                    anchors.rightMargin: Math.round(6 * root.d)
                    spacing: Math.round(8 * root.d)
                    MaterialSymbol {
                        text: "search"
                        iconSize: Math.round(18 * root.d)
                        color: searchField.text.length > 0 ? AtollStyle.accent : AtollStyle.muted
                    }
                    TextInput {
                        id: searchField
                        Layout.fillWidth: true
                        verticalAlignment: TextInput.AlignVCenter
                        color: AtollStyle.text
                        selectionColor: AtollStyle.accentContainer
                        font.family: AtollStyle.fontMain
                        font.pixelSize: AtollStyle.typeLabel
                        clip: true
                        onTextChanged: { root.query = text; flick.contentY = 0 }
                        AtollText {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: searchField.text.length === 0
                            text: Translation.tr("Search every area: blur, corners, dock…")
                            color: AtollStyle.muted
                            font.pixelSize: searchField.font.pixelSize
                        }
                    }
                    AtollIconButton {
                        visible: searchField.text.length > 0
                        implicitWidth: Math.round(24 * root.d)
                        materialIcon: "close"
                        iconSize: Math.round(14 * root.d)
                        Accessible.name: Translation.tr("Clear search")
                        onClicked: searchField.text = ""
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: Math.round(12 * root.d)

                Flickable {
                    Layout.preferredWidth: Math.round(64 * root.d)
                    Layout.fillHeight: true
                    contentHeight: rail.implicitHeight
                    boundsBehavior: Flickable.StopAtBounds
                    clip: true
                    opacity: root.query.length > 0 ? 0.4 : 1
                    Behavior on opacity { NumberAnimation { duration: AtollStyle.duration(140); easing.type: AtollStyle.feedbackEasing } }

                    ColumnLayout {
                        id: rail
                        width: parent.width
                        spacing: Math.round(2 * root.d)
                        Repeater {
                            model: root.railGroups
                            ColumnLayout {
                                id: railGroup
                                required property var modelData
                                required property int index
                                Layout.fillWidth: true
                                spacing: Math.round(2 * root.d)
                                Rectangle {
                                    visible: railGroup.index > 0
                                    Layout.alignment: Qt.AlignHCenter
                                    Layout.topMargin: Math.round(4 * root.d)
                                    Layout.bottomMargin: Math.round(4 * root.d)
                                    implicitWidth: Math.round(24 * root.d)
                                    implicitHeight: 1
                                    color: AtollStyle.hairline
                                }
                                Repeater {
                                    model: railGroup.modelData
                                    RailButton {
                                        required property string modelData
                                        Layout.fillWidth: true
                                        area: root.areaOf(modelData)
                                    }
                                }
                            }
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: Math.round(10 * root.d)

                    RowLayout {
                        id: areaHead
                        readonly property var area: root.areaOf(root.target)
                        Layout.fillWidth: true
                        visible: root.query.length === 0
                        spacing: Math.round(10 * root.d)
                        AtollSquircle {
                            Layout.alignment: Qt.AlignTop
                            implicitWidth: Math.round(36 * root.d)
                            implicitHeight: implicitWidth
                            tint: areaHead.area.tint
                            glyph: areaHead.area.glyph
                            glyphShare: 0.56
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Math.round(2 * root.d)
                            AtollText {
                                text: Translation.tr(areaHead.area.label)
                                font.family: AtollStyle.fontTitle
                                font.pixelSize: AtollStyle.typeTitle
                                font.weight: AtollStyle.weight(Font.Bold)
                            }
                            AtollText {
                                Layout.fillWidth: true
                                text: Translation.tr(areaHead.area.about)
                                color: AtollStyle.subtext
                                font.pixelSize: AtollStyle.typeFootnote
                                wrapMode: Text.WordWrap
                            }
                        }
                        AtollButton {
                            readonly property int changed: root.modifiedIn(root.target)
                            visible: root.target !== "themes" && changed > 0
                            Layout.alignment: Qt.AlignTop
                            quiet: true
                            buttonRadius: height / 2
                            text: Translation.tr("Reset %1").arg(changed)
                            Accessible.name: Translation.tr("Reset what changed here")
                            onClicked: root.resetArea()
                        }
                    }

                    // One line worth knowing about this area, marked in its colour; never a paragraph.
                    RowLayout {
                        readonly property string tip: root.tipOf(root.areaOf(root.target))
                        Layout.fillWidth: true
                        visible: root.query.length === 0 && tip.length > 0
                        spacing: Math.round(6 * root.d)
                        MaterialSymbol {
                            Layout.alignment: Qt.AlignTop
                            text: "lightbulb"
                            fill: 1
                            iconSize: Math.round(14 * root.d)
                            color: root.areaOf(root.target).tint
                        }
                        AtollText {
                            Layout.fillWidth: true
                            text: parent.tip
                            color: AtollStyle.muted
                            font.pixelSize: AtollStyle.typeFootnote
                            wrapMode: Text.WordWrap
                        }
                    }

                    Loader {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Math.round((root.target === "island" || root.target === "dock" ? 150 : 200) * root.d)
                        active: (Config.options?.atoll?.appearance?.previews ?? true) && root.query.length === 0 && root.target !== "themes"
                        visible: active
                        sourceComponent: root.target === "island" || root.target === "dock" ? screenPreview : scenePreview
                    }
                    Component {
                        id: screenPreview
                        AtollScreenPreview {
                            id: screenMiniature
                            screen: root.screen
                            focusRect: root.target === "dock" ? screenMiniature.dockReach : screenMiniature.islandReach
                        }
                    }
                    Component {
                        id: scenePreview
                        AtollTargetPreview {
                            target: root.target
                            playing: GlobalStates.atollStudioOpen
                        }
                    }

                    Flickable {
                        id: flick
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        contentHeight: rows.implicitHeight + Math.round(8 * root.d)
                        boundsBehavior: Flickable.StopAtBounds
                        ScrollBar.vertical: AtollScrollBar {}

                        ColumnLayout {
                            id: rows
                            width: flick.width
                            spacing: Math.round(14 * root.d)

                            AtollText {
                                visible: root.query.length > 0 && root.matches.length === 0
                                Layout.fillWidth: true
                                Layout.topMargin: Math.round(24 * root.d)
                                horizontalAlignment: Text.AlignHCenter
                                text: Translation.tr("Nothing here matches “%1”. Try a shorter word, or look in All settings.").arg(root.query)
                                color: AtollStyle.muted
                                wrapMode: Text.WordWrap
                            }

                            GroupCard {
                                Layout.fillWidth: true
                                visible: root.query.length === 0 && root.target === "material"
                                title: Translation.tr("Character")
                                tint: root.areaOf("material").tint
                                plain: true
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: Math.round(6 * root.d)
                                    Repeater {
                                        model: ["atoll", "soft", "round", "crisp", "angular", "contrast"]
                                        AtollPresetTile {
                                            required property string modelData
                                            Layout.fillWidth: true
                                            name: modelData
                                        }
                                    }
                                }
                            }

                            // Found rows sit under their area, named and marked in its colour.
                            Repeater {
                                model: root.query.length > 0 ? root.matches : []
                                ColumnLayout {
                                    id: found
                                    required property var modelData
                                    Layout.fillWidth: true
                                    spacing: Math.round(6 * root.d)
                                    RowLayout {
                                        spacing: Math.round(6 * root.d)
                                        AtollSquircle {
                                            implicitWidth: Math.round(18 * root.d)
                                            implicitHeight: implicitWidth
                                            tint: found.modelData.area.tint
                                            glyph: found.modelData.area.glyph
                                            glyphShare: 0.62
                                        }
                                        AtollText {
                                            text: Translation.tr(found.modelData.title)
                                            color: found.modelData.area.tint
                                            font.family: AtollStyle.fontTitle
                                            font.pixelSize: AtollStyle.typeLabel
                                            font.weight: AtollStyle.weight(Font.DemiBold)
                                        }
                                    }
                                    Rectangle {
                                        Layout.fillWidth: true
                                        implicitHeight: foundRows.implicitHeight
                                        radius: AtollStyle.radiusTile
                                        color: AtollStyle.readingCard
                                        ColumnLayout {
                                            id: foundRows
                                            anchors.left: parent.left
                                            anchors.right: parent.right
                                            spacing: 0
                                            Repeater {
                                                model: found.modelData.rows
                                                AtollSetting {
                                                    required property var modelData
                                                    required property int index
                                                    Layout.fillWidth: true
                                                    spec: modelData
                                                    highlight: root.query
                                                    last: index === found.modelData.rows.length - 1
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            Repeater {
                                model: root.query.length > 0 || root.target === "themes" ? [] : root.groups
                                GroupCard {
                                    id: groupCard
                                    required property var modelData
                                    Layout.fillWidth: true
                                    title: groupCard.modelData.title
                                    tint: root.areaOf(root.target).tint
                                    Repeater {
                                        model: groupCard.modelData.rows
                                        AtollSetting {
                                            required property var modelData
                                            required property int index
                                            Layout.fillWidth: true
                                            spec: modelData
                                            last: index === groupCard.modelData.rows.length - 1
                                        }
                                    }
                                }
                            }

                            Loader {
                                Layout.fillWidth: true
                                active: root.query.length === 0 && root.target === "themes"
                                visible: active
                                sourceComponent: themesPage
                            }
                        }
                    }
                }
            }
        }
    }

    component RailButton: MouseArea {
        id: railButton
        required property var area
        readonly property bool selected: root.target === railButton.area.id && root.query.length === 0
        readonly property int changed: root.modifiedIn(railButton.area.id)
        implicitHeight: Math.round(52 * root.d)
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        Accessible.role: Accessible.PageTab
        Accessible.name: Translation.tr(railButton.area.label)
        Accessible.checked: railButton.selected
        onClicked: {
            if (root.query.length > 0) searchField.text = ""
            root.select(railButton.area.id)
        }
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            y: Math.round(2 * root.d)
            width: Math.round(40 * root.d)
            height: Math.round(30 * root.d)
            radius: height / 2
            color: railButton.selected ? AtollStyle.tintFill(railButton.area.tint)
                : railButton.containsMouse ? AtollStyle.fillHover : "transparent"
            Behavior on color { ColorAnimation { duration: AtollStyle.duration(110); easing.type: AtollStyle.feedbackEasing } }
            MaterialSymbol {
                anchors.centerIn: parent
                text: railButton.area.glyph
                iconSize: Math.round(19 * root.d)
                fill: railButton.selected ? 1 : 0
                animateFill: true
                color: railButton.selected ? railButton.area.tint : AtollStyle.textSecondary
            }
            Rectangle {
                visible: railButton.changed > 0
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.rightMargin: Math.round(4 * root.d)
                anchors.topMargin: Math.round(4 * root.d)
                width: Math.round(6 * root.d)
                height: width
                radius: width / 2
                color: railButton.area.tint
            }
        }
        AtollText {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Math.round(2 * root.d)
            width: Math.min(implicitWidth, railButton.width)
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            text: Translation.tr(railButton.area.label)
            color: railButton.selected ? AtollStyle.text : AtollStyle.muted
            font.pixelSize: AtollStyle.typeCaption
            font.weight: AtollStyle.weight(railButton.selected ? Font.DemiBold : Font.Normal)
        }
    }

    // Choosing a theme can take only its colours (atoll.appearance.themeColoursOnly), said beside the switch.
    component ColoursOnly: RowLayout {
        spacing: Math.round(8 * root.d)
        AtollText {
            text: Translation.tr("Colours only")
            color: AtollThemes.coloursOnly ? AtollStyle.text : AtollStyle.subtext
            font.pixelSize: AtollStyle.typeLabel
        }
        AtollSwitch {
            on: AtollThemes.coloursOnly
            name: Translation.tr("Colours only")
            onToggled: Config.setNestedValue("atoll.appearance.themeColoursOnly", !AtollThemes.coloursOnly)
        }
    }

    // A group's title carries its area's colour: the one accent that says where you are.
    component GroupCard: ColumnLayout {
        id: card
        property string title: ""
        property color tint: AtollStyle.accent
        property bool plain: false
        default property alias rows: body.data
        spacing: Math.round(6 * root.d)
        AtollText {
            Layout.leftMargin: Math.round(14 * root.d)
            text: Translation.tr(card.title)
            color: card.tint
            font.family: AtollStyle.fontTitle
            font.pixelSize: AtollStyle.typeMeta
            font.weight: AtollStyle.weight(Font.DemiBold)
        }
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: body.implicitHeight
            radius: AtollStyle.radiusTile
            color: card.plain ? "transparent" : AtollStyle.readingCard
            ColumnLayout {
                id: body
                anchors.left: parent.left
                anchors.right: parent.right
                spacing: 0
            }
        }
    }

    Component {
        id: themesPage
        ColumnLayout {
            spacing: Math.round(12 * root.d)
            RowLayout {
                Layout.fillWidth: true
                spacing: Math.round(6 * root.d)
                AtollText {
                    Layout.fillWidth: true
                    text: AtollThemes.active ? AtollThemes.active.name : Translation.tr("Your own mix")
                    font.pixelSize: AtollStyle.typeBody
                    font.weight: AtollStyle.weight(Font.DemiBold)
                    elide: Text.ElideRight
                }
                ColoursOnly {}
                AtollButton {
                    quiet: true
                    text: Translation.tr("Paste")
                    buttonRadius: height / 2
                    onClicked: {
                        const theme = AtollThemes.importText(String(Quickshell.clipboardText ?? ""))
                        AtollEditHistory.say(theme ? Translation.tr("Imported “%1”").arg(theme.name) : Translation.tr("The clipboard does not hold an Atoll theme"))
                    }
                }
                AtollButton {
                    text: Translation.tr("Save current")
                    buttonRadius: height / 2
                    onClicked: {
                        AtollThemes.save(Translation.tr("My theme %1").arg(AtollThemes.all.filter(theme => theme.user).length + 1), "")
                        AtollEditHistory.say(Translation.tr("Saved as a theme"))
                    }
                }
            }
            GridLayout {
                id: cells
                Layout.fillWidth: true
                columns: 2
                rowSpacing: Math.round(12 * root.d)
                columnSpacing: Math.round(10 * root.d)
                Repeater {
                    model: AtollThemes.all
                    AtollThemeCard {
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.preferredWidth: (cells.width - cells.columnSpacing) / 2
                        theme: modelData
                        screen: root.screen
                        onShareRequested: {
                            Quickshell.clipboardText = AtollThemes.exportText(modelData)
                            AtollEditHistory.say(Translation.tr("Copied “%1”, paste it anywhere to share it").arg(modelData.name))
                        }
                    }
                }
            }
        }
    }
}
