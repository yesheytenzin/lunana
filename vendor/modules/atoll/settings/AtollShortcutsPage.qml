pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../.."
import "../../../services"
import "../../../services/deferred"
import "../../common"
import "../../common/widgets"
import "../components"
import "../style"

Flickable {
    id: root

    readonly property real d: AtollStyle.density
    readonly property bool isNiri: CompositorService.isNiri
    readonly property bool hasEnriched: CompositorService.isNiri && NiriKeybinds.enrichedCategories.length > 0
    readonly property bool canEdit: root.hasEnriched
    readonly property int markInset: Math.round(52 * root.d)
    property string query: ""
    property var open: ({})
    property string statusMsg: ""
    property string statusType: "saved"
    property bool adding: false

    boundsBehavior: Flickable.StopAtBounds
    clip: true
    contentHeight: pageColumn.implicitHeight + 40 * root.d
    ScrollBar.vertical: AtollScrollBar {}

    function displayCategoryName(name: string): string {
        return name === "drift Shell" ? Translation.tr("Lunana Shell") : name
    }
    function categoryGlyph(name: string): string {
        const glyphs = {
            "System": "settings_power", "drift Shell": "auto_awesome", "Lunana Shell": "auto_awesome",
            "Window Switcher": "swap_horiz", "Screenshots": "screenshot_region", "Applications": "apps",
            "Window Management": "web_asset", "Focus": "center_focus_strong", "Move Windows": "open_with",
            "Workspaces": "grid_view", "Media": "volume_up", "Brightness": "light_mode",
            "Layout": "dashboard_customize", "Resize": "photo_size_select_large", "Monitors": "monitor",
            "Region Tools": "screenshot_region", "Other": "more_horiz"
        }
        return glyphs[name] ?? "keyboard"
    }
    function categoryTint(name: string): color {
        const tints = {
            "System": "gray", "drift Shell": "purple", "Lunana Shell": "purple", "Window Switcher": "indigo",
            "Screenshots": "orange", "Region Tools": "orange", "Applications": "blue", "Window Management": "sky",
            "Focus": "teal", "Move Windows": "green", "Workspaces": "indigo", "Media": "pink",
            "Brightness": "yellow", "Layout": "lavender", "Resize": "red", "Monitors": "blue", "Other": "gray"
        }
        return AtollStyle.identityColor(tints[name] ?? "gray")
    }
    function parseCombo(combo: string): var {
        if (!combo || combo.length === 0) return { mods: [], key: "" }
        const parts = combo.split("+")
        if (parts.length === 1) return { mods: [], key: parts[0] }
        return { mods: parts.slice(0, parts.length - 1), key: parts[parts.length - 1] }
    }
    readonly property var keySubstitutions: ({
        "Mod": "Super", "Slash": "/", "Comma": ",", "Period": ".", "Minus": "−", "Equal": "=",
        "Return": "Enter", "Escape": "Esc", "Left": "←", "Right": "→", "Up": "↑", "Down": "↓",
        "Page_Up": "PgUp", "Page_Down": "PgDn", "BackSpace": "⌫", "Print": "PrtSc",
        "WheelScrollUp": "Scroll ↑", "WheelScrollDown": "Scroll ↓", "WheelScrollLeft": "Scroll ←", "WheelScrollRight": "Scroll →"
    })
    readonly property var allCategories: {
        const source = root.hasEnriched ? NiriKeybinds.enrichedCategories : (NiriKeybinds.keybinds?.children ?? [])
        return source.map(category => ({
            name: category.name,
            binds: root.hasEnriched
                ? (category.binds ?? []).map(i => {
                    const b = NiriKeybinds.allBinds[i] ?? {}
                    const parsed = root.parseCombo(b.key_combo ?? "")
                    return { mods: parsed.mods, key: parsed.key, action: b.description ?? b.action ?? "", disabled: b.commented ?? false,
                        keyCombo: b.key_combo ?? "", actionRaw: b.action ?? "", optionsStr: b.options ?? "" }
                })
                : (category.children?.[0]?.keybinds ?? []).map(item => ({ mods: item.mods ?? [], key: item.key ?? "", action: item.comment ?? "",
                    disabled: false, keyCombo: "", actionRaw: "", optionsStr: "" }))
        }))
    }
    readonly property var shownCategories: {
        const terms = root.query.toLowerCase().split(/\s+/).filter(term => term.length > 0)
        if (terms.length === 0) return root.allCategories
        return root.allCategories.map(category => ({
            name: category.name,
            binds: category.binds.filter(bind => {
                const text = [bind.action, bind.keyCombo, ...bind.mods, bind.key, root.displayCategoryName(category.name)].join(" ").toLowerCase()
                return terms.every(term => text.includes(term))
            })
        })).filter(category => category.binds.length > 0)
    }
    function toggle(name: string): void {
        const next = Object.assign({}, root.open)
        next[name] = !next[name]
        root.open = next
    }

    Timer {
        id: statusTimer
        interval: 3000
        onTriggered: root.statusMsg = ""
    }
    Connections {
        target: NiriKeybinds
        function onBindSaved(keyCombo) {
            root.statusType = "saved"
            root.statusMsg = Translation.tr("Saved:") + " " + keyCombo
            statusTimer.restart()
        }
        function onBindRemoved(keyCombo) {
            root.statusType = "removed"
            root.statusMsg = Translation.tr("Removed:") + " " + keyCombo
            statusTimer.restart()
        }
        function onBindError(message) {
            root.statusType = "error"
            root.statusMsg = message
            statusTimer.stop()
        }
    }

    ColumnLayout {
        id: pageColumn
        width: Math.min(root.width - 32 * root.d, 820 * root.d)
        x: Math.round((root.width - width) / 2)
        y: Math.round(6 * root.d)
        spacing: 14 * root.d

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: Math.round(36 * root.d)
            radius: height / 2
            color: filter.activeFocus ? AtollStyle.fill : AtollStyle.readingCard
            border.width: filter.activeFocus ? 1 : 0
            border.color: AtollStyle.tintBorder(AtollStyle.accent)
            MaterialSymbol {
                id: filterGlyph
                anchors.left: parent.left
                anchors.leftMargin: 14 * root.d
                anchors.verticalCenter: parent.verticalCenter
                text: "search"
                iconSize: Math.round(17 * root.d)
                color: AtollStyle.muted
            }
            TextInput {
                id: filter
                anchors.left: filterGlyph.right
                anchors.leftMargin: 8 * root.d
                anchors.right: parent.right
                anchors.rightMargin: 14 * root.d
                anchors.verticalCenter: parent.verticalCenter
                color: AtollStyle.text
                selectionColor: AtollStyle.accentContainer
                font.family: AtollStyle.fontMain
                font.pixelSize: AtollStyle.typeLabel
                clip: true
                onTextChanged: root.query = text
                Keys.onEscapePressed: event => { if (text.length > 0) { text = ""; event.accepted = true } else event.accepted = false }
                AtollText {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: filter.text.length === 0
                    text: Translation.tr("Search an action or a key")
                    color: AtollStyle.muted
                    font.pixelSize: filter.font.pixelSize
                }
            }
        }

        AtollText {
            Layout.fillWidth: true
            Layout.leftMargin: 16 * root.d
            Layout.topMargin: -6 * root.d
            text: root.statusMsg.length > 0 ? root.statusMsg
                : !root.isNiri ? Translation.tr("Shortcuts are only available on Niri.")
                : NiriKeybinds.loaded ? Translation.tr("From %1").arg(NiriKeybinds.configPath)
                : Translation.tr("Could not read your Niri config, showing the defaults")
            color: root.statusMsg.length > 0 ? (root.statusType === "error" ? AtollStyle.danger : AtollStyle.success) : AtollStyle.muted
            font.pixelSize: AtollStyle.typeMeta
            elide: Text.ElideMiddle
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: categoryList.implicitHeight
            radius: AtollStyle.radiusTile
            color: AtollStyle.readingCard
            visible: root.shownCategories.length > 0
            Column {
                id: categoryList
                width: parent.width
                Repeater {
                    model: root.shownCategories
                    Category {}
                }
            }
        }

        AtollText {
            visible: root.query.length > 0 && root.shownCategories.length === 0
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 18 * root.d
            text: Translation.tr("No shortcut matches “%1”").arg(root.query)
            color: AtollStyle.muted
        }

        Rectangle {
            visible: root.canEdit && root.query.length === 0
            Layout.fillWidth: true
            implicitHeight: addColumn.implicitHeight
            radius: AtollStyle.radiusTile
            color: AtollStyle.readingCard
            Column {
                id: addColumn
                width: parent.width
                MouseArea {
                    id: addHeader
                    width: parent.width
                    height: Math.round(46 * root.d)
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.adding = !root.adding
                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 3 * root.d
                        radius: AtollStyle.radiusRow
                        color: addHeader.containsMouse ? AtollStyle.fillQuiet : "transparent"
                    }
                    MaterialSymbol {
                        anchors.left: parent.left
                        anchors.leftMargin: 17 * root.d
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.adding ? "remove" : "add"
                        iconSize: Math.round(20 * root.d)
                        color: AtollStyle.accent
                    }
                    AtollText {
                        anchors.left: parent.left
                        anchors.leftMargin: root.markInset
                        anchors.verticalCenter: parent.verticalCenter
                        text: Translation.tr("Add a shortcut")
                        color: AtollStyle.accent
                        font.pixelSize: AtollStyle.typeLabel
                    }
                }
                Loader {
                    width: parent.width
                    active: root.adding
                    visible: active
                    sourceComponent: BindEditor {
                        onDone: root.adding = false
                    }
                }
            }
        }
    }

    component Category: Item {
        id: category
        required property var modelData
        required property int index
        readonly property bool expanded: root.query.length > 0 || (root.open[category.modelData.name] ?? false)
        width: parent ? parent.width : 0
        implicitHeight: categoryColumn.implicitHeight

        Rectangle {
            visible: category.index > 0
            anchors.left: parent.left
            anchors.leftMargin: root.markInset
            anchors.right: parent.right
            height: 1
            color: AtollStyle.hairline
        }
        Column {
            id: categoryColumn
            width: parent.width
            MouseArea {
                id: header
                width: parent.width
                height: Math.round(46 * root.d)
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                enabled: root.query.length === 0
                onClicked: root.toggle(category.modelData.name)
                Accessible.role: Accessible.Button
                Accessible.name: root.displayCategoryName(category.modelData.name)
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 3 * root.d
                    radius: AtollStyle.radiusRow
                    color: header.containsMouse ? AtollStyle.fillQuiet : "transparent"
                    Behavior on color { ColorAnimation { duration: AtollStyle.duration(110); easing.type: AtollStyle.feedbackEasing } }
                }
                AtollSquircle {
                    id: mark
                    anchors.left: parent.left
                    anchors.leftMargin: 14 * root.d
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.round(26 * root.d)
                    height: width
                    tint: root.categoryTint(category.modelData.name)
                    glyph: root.categoryGlyph(category.modelData.name)
                }
                AtollText {
                    anchors.left: parent.left
                    anchors.leftMargin: root.markInset
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.displayCategoryName(category.modelData.name)
                    font.pixelSize: AtollStyle.typeLabel
                    font.weight: category.expanded ? Font.DemiBold : Font.Normal
                }
                AtollText {
                    anchors.right: chevron.left
                    anchors.rightMargin: 8 * root.d
                    anchors.verticalCenter: parent.verticalCenter
                    text: String(category.modelData.binds.length)
                    color: AtollStyle.muted
                    font.pixelSize: AtollStyle.typeLabel
                }
                MaterialSymbol {
                    id: chevron
                    anchors.right: parent.right
                    anchors.rightMargin: 12 * root.d
                    anchors.verticalCenter: parent.verticalCenter
                    text: "chevron_right"
                    iconSize: Math.round(18 * root.d)
                    color: header.containsMouse ? AtollStyle.text : AtollStyle.textTertiary
                    rotation: category.expanded ? 90 : 0
                    Behavior on rotation { NumberAnimation { duration: AtollStyle.duration(160); easing.type: AtollStyle.feedbackEasing } }
                }
            }
            Repeater {
                model: category.expanded ? category.modelData.binds : []
                BindRow {}
            }
        }
    }

    component BindRow: Item {
        id: bindRow
        required property var modelData
        required property int index
        property bool editing: false
        property bool confirming: false
        width: parent ? parent.width : 0
        implicitHeight: Math.round(40 * root.d) + (editorLoader.active ? editorLoader.implicitHeight : 0) + (bindRow.confirming ? confirmRow.implicitHeight + Math.round(10 * root.d) : 0)

        HoverHandler { id: rowHover }
        Rectangle {
            anchors.left: parent.left
            anchors.leftMargin: root.markInset
            anchors.right: parent.right
            anchors.top: parent.top
            height: 1
            color: AtollStyle.hairline
        }
        AtollText {
            anchors.left: parent.left
            anchors.leftMargin: root.markInset
            anchors.right: tools.left
            anchors.rightMargin: 10 * root.d
            y: Math.round((Math.round(40 * root.d) - height) / 2)
            text: bindRow.modelData.action + (bindRow.modelData.disabled ? "  " + Translation.tr("(off)") : "")
            color: bindRow.modelData.disabled ? AtollStyle.muted : AtollStyle.text
            font.pixelSize: AtollStyle.typeLabel
            elide: Text.ElideRight
        }
        Row {
            id: tools
            anchors.right: keys.left
            anchors.rightMargin: 8 * root.d
            y: Math.round((Math.round(40 * root.d) - height) / 2)
            spacing: 0
            visible: root.canEdit && bindRow.modelData.keyCombo.length > 0
            opacity: rowHover.hovered || bindRow.editing ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: AtollStyle.duration(110); easing.type: AtollStyle.feedbackEasing } }
            AtollIconButton {
                materialIcon: "edit"
                iconSize: Math.round(16 * root.d)
                onClicked: { bindRow.confirming = false; bindRow.editing = !bindRow.editing }
                Accessible.name: Translation.tr("Edit")
            }
            AtollIconButton {
                materialIcon: "delete"
                iconSize: Math.round(16 * root.d)
                danger: true
                onClicked: { bindRow.editing = false; bindRow.confirming = !bindRow.confirming }
                Accessible.name: Translation.tr("Delete")
            }
        }
        Row {
            id: keys
            anchors.right: parent.right
            anchors.rightMargin: 14 * root.d
            y: Math.round((Math.round(40 * root.d) - height) / 2)
            spacing: 3 * root.d
            Repeater {
                model: [...(bindRow.modelData.mods ?? []), bindRow.modelData.key].filter(part => String(part).length > 0)
                KeyCap { required property var modelData; keyText: modelData }
            }
        }
        RowLayout {
            id: confirmRow
            visible: bindRow.confirming
            anchors.left: parent.left
            anchors.leftMargin: root.markInset
            anchors.right: parent.right
            anchors.rightMargin: 14 * root.d
            y: Math.round(40 * root.d)
            spacing: 8 * root.d
            AtollText {
                Layout.fillWidth: true
                text: Translation.tr("Remove %1?").arg(bindRow.modelData.keyCombo)
                font.pixelSize: AtollStyle.typeLabel
                elide: Text.ElideRight
            }
            AtollButton {
                text: Translation.tr("Cancel")
                quiet: true
                onClicked: bindRow.confirming = false
            }
            AtollButton {
                text: Translation.tr("Remove")
                danger: true
                emphasized: true
                onClicked: { NiriKeybinds.removeBind(bindRow.modelData.keyCombo); bindRow.confirming = false }
            }
        }
        Loader {
            id: editorLoader
            anchors.left: parent.left
            anchors.right: parent.right
            y: Math.round(40 * root.d)
            active: bindRow.editing
            sourceComponent: BindEditor {
                combo: bindRow.modelData.keyCombo
                action: bindRow.modelData.actionRaw
                options: bindRow.modelData.optionsStr
                onDone: bindRow.editing = false
            }
        }
    }

    component BindEditor: ColumnLayout {
        id: editor
        property string combo: ""
        property string action: ""
        property string options: ""
        signal done()
        readonly property string conflict: {
            const v = comboField.text.trim()
            if (!v || v === editor.combo) return ""
            const found = (NiriKeybinds.allBinds ?? []).find(b => b.key_combo === v && !b.commented)
            return found ? (found.description ?? found.action ?? v) : ""
        }
        spacing: 8 * root.d
        Item { implicitHeight: 2 * root.d }
        EditorField { id: comboField; label: Translation.tr("Keys"); text: editor.combo; placeholder: "Mod+Shift+E" }
        AtollText {
            visible: editor.conflict.length > 0
            Layout.leftMargin: root.markInset
            Layout.rightMargin: 14 * root.d
            Layout.fillWidth: true
            text: Translation.tr("Already used by “%1”").arg(editor.conflict)
            color: AtollStyle.danger
            font.pixelSize: AtollStyle.typeMeta
            wrapMode: Text.WordWrap
        }
        EditorField { id: actionField; label: Translation.tr("Action"); text: editor.action; placeholder: "toggle-overview" }
        EditorField { id: optionsField; label: Translation.tr("Options"); text: editor.options; placeholder: "repeat=false" }
        RowLayout {
            Layout.leftMargin: root.markInset
            Layout.rightMargin: 14 * root.d
            Layout.bottomMargin: 12 * root.d
            spacing: 8 * root.d
            Item { Layout.fillWidth: true }
            AtollButton { text: Translation.tr("Cancel"); quiet: true; onClicked: editor.done() }
            AtollButton {
                text: Translation.tr("Save")
                emphasized: true
                enabled: comboField.text.trim().length > 0 && actionField.text.trim().length > 0
                onClicked: {
                    NiriKeybinds.setBind(comboField.text.trim(), actionField.text.trim(), optionsField.text.trim())
                    editor.done()
                }
            }
        }
    }

    component EditorField: RowLayout {
        id: field
        property string label: ""
        property alias text: input.text
        property string placeholder: ""
        Layout.fillWidth: true
        Layout.leftMargin: root.markInset
        Layout.rightMargin: 14 * root.d
        spacing: 12 * root.d
        AtollText {
            Layout.preferredWidth: Math.round(64 * root.d)
            text: field.label
            color: AtollStyle.muted
            font.pixelSize: AtollStyle.typeLabel
        }
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: Math.round(32 * root.d)
            radius: AtollStyle.radiusRow
            color: AtollStyle.fill
            border.width: input.activeFocus ? 1 : 0
            border.color: AtollStyle.tintBorder(AtollStyle.accent)
            TextInput {
                id: input
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: 10 * root.d
                anchors.rightMargin: 10 * root.d
                anchors.verticalCenter: parent.verticalCenter
                color: AtollStyle.text
                selectionColor: AtollStyle.accentContainer
                font.family: AtollStyle.fontMain
                font.pixelSize: AtollStyle.typeLabel
                clip: true
                AtollText {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: input.text.length === 0
                    text: field.placeholder
                    color: AtollStyle.textTertiary
                    font.pixelSize: input.font.pixelSize
                }
            }
        }
    }

    component KeyCap: Rectangle {
        property string keyText: ""
        implicitWidth: Math.max(capLabel.width + Math.round(12 * root.d), Math.round(24 * root.d))
        implicitHeight: Math.round(22 * root.d)
        radius: AtollStyle.radiusMicro
        color: AtollStyle.fill
        border.width: 1
        border.color: AtollStyle.hairlineStrong
        AtollText {
            id: capLabel
            anchors.centerIn: parent
            text: root.keySubstitutions[parent.keyText] ?? parent.keyText
            font.pixelSize: AtollStyle.typeMeta
            font.weight: AtollStyle.weight(Font.Medium)
        }
    }
}
