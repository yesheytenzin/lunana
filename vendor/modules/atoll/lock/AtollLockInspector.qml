pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import "../../.."
import "../../../services"
import "../../common"
import "../../common/widgets"
import "../components"
import "../settings"
import "../style"
import "../widgets"

Item {
    id: root
    property string screenName: ""
    // The lock widget tapped on the stage: its Look opens here, written to the lock's own scope.
    property var widget: null
    property rect avoid: Qt.rect(0, 0, 0, 0)
    property bool peeking: false
    // The inspector steps aside rather than sitting on the block you are editing.
    readonly property bool onRight: root.avoid.width > 0
        && root.avoid.x < panel.width + Math.round(56 * root.d)
        && root.avoid.y + root.avoid.height > root.height - panel.height - Math.round(56 * root.d)
    // Drawn by the field like every other Atoll body, melting into the edge it rests
    // on, instead of a rectangle floating over the wallpaper.
    readonly property var fieldShapes: [{
        x: panel.x, y: panel.y, width: panel.width, height: panel.height,
        radius: panel.radius, fuse: AtollStyle.fuseEdge, paints: true,
        id: "lockinspector", joins: "edge"
    }]
    readonly property real d: AtollStyle.density
    readonly property string sceneStill: {
        Config.revision
        const scene = AtollLockOptions.scene
        const path = String(scene?.source ?? "desktop") === "custom" && String(scene?.path ?? "").length > 0
            ? String(scene.path) : String(Config.options?.background?.wallpaperPath ?? "")
        return String(scene?.source ?? "desktop") === "colour" ? "" : Wallpapers.stillUrlFor(path)
    }
    readonly property string group: {
        const wanted = GlobalStates.atollLockPage
        return AtollLockOptions.groups.includes(wanted) ? wanted : "Scene"
    }
    readonly property var rows: {
        Config.revision
        return AtollOptions.settings.filter(spec => spec.section === "lock" && spec.group === root.group
            && AtollOptions.shown(spec))
    }

    Connections {
        target: GlobalStates
        function onAtollLockSelectionChanged(): void {
            const id = GlobalStates.atollLockSelection
            if (id.length > 0) GlobalStates.atollLockPage = AtollLockOptions.groupOf(id)
        }
    }

    Item {
        id: panel
        readonly property real radius: AtollStyle.radiusSheet
        anchors.verticalCenter: parent.verticalCenter
        // Anchors that flip at runtime leave stale ones behind, so x is bound instead.
        x: Math.round(root.onRight ? root.width - panel.width : 0) - panel.radius
        Behavior on x { NumberAnimation { duration: AtollStyle.duration(220); easing.type: Easing.BezierSpline; easing.bezierCurve: AtollStyle.morphCurve } }
        width: Math.round(392 * root.d) + panel.radius
        // Querying the list's contentHeight here would size the list from itself.
        readonly property real chrome: Math.round(56 * root.d) + header.implicitHeight + chips.implicitHeight
        height: Math.min(Math.round(root.height * 0.82), panel.chrome + rowColumn.implicitHeight)
        opacity: root.peeking ? 0 : 1
        visible: panel.opacity > 0.01
        Behavior on opacity { NumberAnimation { duration: AtollStyle.duration(160); easing.type: AtollStyle.feedbackEasing } }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Math.round(18 * root.d)
            anchors.leftMargin: Math.round(18 * root.d) + (root.onRight ? 0 : panel.radius)
            anchors.rightMargin: Math.round(18 * root.d) + (root.onRight ? panel.radius : 0)
            spacing: Math.round(12 * root.d)

            RowLayout {
                id: header
                Layout.fillWidth: true
                spacing: Math.round(8 * root.d)
                AtollMark {
                    Layout.alignment: Qt.AlignVCenter
                    implicitSize: Math.round(22 * root.d)
                    color: AtollStyle.accent
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    AtollText {
                        text: Translation.tr("Lock screen")
                        color: AtollStyle.text
                        font.pixelSize: AtollStyle.typeTitle
                        font.weight: AtollStyle.weight(Font.Bold)
                    }
                    AtollText {
                        Layout.fillWidth: true
                        text: GlobalStates.atollLockSelection.length > 0
                            ? Translation.tr("Arrows nudge it, Shift ignores the edges")
                            : Translation.tr("Drag a block, or pick one below")
                        color: AtollStyle.muted
                        font.pixelSize: AtollStyle.typeFootnote
                        elide: Text.ElideRight
                    }
                }
                AtollIconButton {
                    id: peekButton
                    materialIcon: "visibility"
                    selected: root.peeking
                    Accessible.name: Translation.tr("Hold to see it without the handles")
                    // Held, not toggled: a preview you have to keep asking for cannot
                    // strand you outside the editor.
                    onPressedChanged: root.peeking = peekButton.pressed
                }
                AtollButton {
                    text: Translation.tr("Done")
                    emphasized: true
                    buttonRadius: height / 2
                    onClicked: GlobalStates.atollLockEdit = false
                }
            }

            Flow {
                id: chips
                Layout.fillWidth: true
                spacing: Math.round(6 * root.d)
                Repeater {
                    model: AtollLockOptions.groups
                    // The chip carries the state itself: a block that is off reads as
                    // quiet and muted. A badge on top of a label is noise twice over.
                    delegate: AtollButton {
                        id: chip
                        required property string modelData
                        readonly property string blockId: AtollLockOptions.blockForGroup(chip.modelData)
                        readonly property bool current: root.group === chip.modelData
                        readonly property bool off: {
                            Config.revision
                            return chip.blockId.length > 0 && !AtollLockOptions.enabled(chip.blockId)
                        }
                        text: Translation.tr(chip.modelData)
                        quiet: chip.off && !chip.current
                        emphasized: chip.current
                        implicitHeight: Math.round(30 * root.d)
                        buttonRadius: height / 2
                        opacity: chip.off && !chip.current ? 0.55 : 1
                        onClicked: {
                            GlobalStates.atollLockPage = chip.modelData
                            GlobalStates.atollLockSelection = chip.blockId
                        }
                    }
                }
            }

            // A Column inside a Flickable, not a ListView: the panel is sized from the
            // rows' own height, and a list that fills the panel cannot report that.
            Flickable {
                id: rowList
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                contentHeight: rowColumn.implicitHeight
                contentWidth: width
                boundsBehavior: Flickable.StopAtBounds
                ScrollBar.vertical: AtollScrollBar {}
                Column {
                    id: rowColumn
                    width: rowList.width
                    spacing: root.group === "Layouts" ? Math.round(8 * root.d) : 0
                    Repeater {
                        model: root.group === "Layouts" ? AtollLockOptions.presets : []
                        delegate: LayoutCard {}
                    }
                    Loader {
                        active: root.group === "Widgets" && root.widget !== null
                        visible: active
                        width: rowColumn.width
                        // Room for the last slider's thumb, which rides past its row.
                        height: active ? (item?.implicitHeight ?? 0) + Math.round(10 * root.d) : 0
                        sourceComponent: AtollWidgetControls {
                            width: rowColumn.width
                            widget: root.widget
                            onLock: true
                            onCloseRequested: GlobalStates.atollLockSelection = ""
                        }
                    }
                    AtollText {
                        visible: root.group === "Widgets" && root.widget === null
                        width: rowColumn.width
                        text: Translation.tr("Your desktop widgets, as they look there. Tap one on the lock to give it a shape and material of its own.")
                        color: AtollStyle.muted
                        wrapMode: Text.WordWrap
                        font.pixelSize: AtollStyle.typeMeta
                    }
                    Flow {
                        visible: root.group === "Widgets" && root.widget === null
                        width: rowColumn.width
                        spacing: Math.round(4 * root.d)
                        Repeater {
                            model: root.group === "Widgets" ? AtollFaceData.galleryEntries : []
                            delegate: WidgetTile {}
                        }
                    }
                    Repeater {
                        model: ScriptModel { objectProp: "modelKey"; values: root.rows }
                        delegate: AtollSetting {
                            required property var modelData
                            required property int index
                            width: rowColumn.width
                            spec: modelData
                            last: index === root.rows.length - 1
                        }
                    }
                }
            }
        }
    }

    component LayoutCard: Rectangle {
        id: card
        required property var modelData
        readonly property bool current: AtollLockOptions.presetId === card.modelData.id
        readonly property real miniWidth: Math.round(112 * root.d)
        readonly property real miniHeight: Math.round(card.miniWidth * 9 / 16)
        readonly property real unit: card.miniWidth / 112
        width: rowColumn.width
        height: Math.max(cardText.implicitHeight, card.miniHeight) + Math.round(24 * root.d)
        radius: AtollStyle.radiusTile
        color: card.current ? AtollStyle.tintFill(AtollStyle.accent) : cardArea.containsMouse ? AtollStyle.fillHover : AtollStyle.fillQuiet
        border.width: card.current ? Math.max(1, Math.round(1.5 * root.d)) : 0
        border.color: AtollStyle.tintBorder(AtollStyle.accent)
        Behavior on color { ColorAnimation { duration: AtollStyle.duration(120); easing.type: AtollStyle.feedbackEasing } }

        Rectangle {
            id: mini
            x: Math.round(12 * root.d)
            anchors.verticalCenter: parent.verticalCenter
            width: card.miniWidth
            height: card.miniHeight
            radius: AtollStyle.radiusMicro
            color: AtollStyle.surfaceOpaque
            clip: true
            AtollImage {
                anchors.fill: parent
                source: root.sceneStill
            }
            Rectangle {
                anchors.fill: parent
                color: AtollStyle.mediaScrim
            }
            Repeater {
                model: AtollLockOptions.blockIds.filter(id => card.modelData.blocks[id]?.enable)
                Rectangle {
                    id: mark
                    required property string modelData
                    required property int index
                    readonly property string zone: card.modelData.blocks[mark.modelData].zone
                    readonly property var anchor: AtollLockOptions.zoneAnchor(mark.zone, mini.width, mini.height, Math.round(8 * card.unit))
                    readonly property var mates: AtollLockOptions.blockIds.filter(id => card.modelData.blocks[id]?.enable
                        && card.modelData.blocks[id].zone === mark.zone)
                    readonly property int order: mark.mates.indexOf(mark.modelData)
                    readonly property real clockHeight: card.modelData.type.clockSize / 112 * 11 * card.unit
                    readonly property var sizes: ({
                        clock: [card.modelData.type.clockSize / 112 * 30 * card.unit, mark.clockHeight],
                        glance: [30 * card.unit, 3 * card.unit],
                        media: [26 * card.unit, 7 * card.unit],
                        activity: [14 * card.unit, 4 * card.unit],
                        session: [20 * card.unit, 5 * card.unit],
                        status: [14 * card.unit, 3 * card.unit]
                    })
                    readonly property real above: {
                        let sum = 0
                        for (let i = 0; i < mark.order; i++) sum += mark.sizes[mark.mates[i]][1] + 2 * card.unit
                        return sum
                    }
                    readonly property real stack: {
                        let sum = 0
                        for (const id of mark.mates) sum += mark.sizes[id][1] + 2 * card.unit
                        return sum - 2 * card.unit
                    }
                    width: Math.round(mark.sizes[mark.modelData][0])
                    height: Math.max(2, Math.round(mark.sizes[mark.modelData][1]))
                    x: Math.round(mark.anchor.align === Qt.AlignLeft ? mark.anchor.x
                        : mark.anchor.align === Qt.AlignRight ? mark.anchor.x - width : mark.anchor.x - width / 2)
                    y: Math.round(mark.anchor.up ? mark.anchor.y - mark.stack + mark.above
                        : mark.zone === "center" || mark.zone === "left" || mark.zone === "right" ? mark.anchor.y - mark.stack / 2 + mark.above
                        : mark.anchor.y + mark.above)
                    radius: ["session", "activity", "status", "glance"].includes(mark.modelData) ? height / 2
                        : Math.max(1, Math.round(2 * card.unit))
                    color: mark.modelData === "clock" && card.modelData.type.clockWeight >= 600 ? AtollStyle.onMedia
                        : AtollStyle.onMediaSecondary
                }
            }
        }

        ColumnLayout {
            id: cardText
            anchors.left: mini.right
            anchors.leftMargin: Math.round(12 * root.d)
            anchors.right: parent.right
            anchors.rightMargin: Math.round(12 * root.d)
            anchors.verticalCenter: parent.verticalCenter
            spacing: Math.round(2 * root.d)
            AtollText {
                Layout.fillWidth: true
                text: Translation.tr(card.modelData.label)
                font.pixelSize: AtollStyle.typeLabel
                font.weight: AtollStyle.weight(Font.DemiBold)
                color: card.current ? AtollStyle.accent : AtollStyle.text
                elide: Text.ElideRight
            }
            AtollText {
                Layout.fillWidth: true
                text: Translation.tr(card.modelData.description)
                color: AtollStyle.muted
                wrapMode: Text.WordWrap
                maximumLineCount: 3
                elide: Text.ElideRight
                font.pixelSize: AtollStyle.typeMeta
            }
        }

        MouseArea {
            id: cardArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            Accessible.role: Accessible.RadioButton
            Accessible.name: Translation.tr(card.modelData.label)
            Accessible.checked: card.current
            onClicked: AtollLockOptions.applyPreset(card.modelData.id)
        }
    }

    component WidgetTile: Item {
        id: tile
        required property var modelData
        readonly property bool on: AtollLockOptions.widgetShown(root.screenName, tile.modelData.key)
        width: Math.floor((rowColumn.width - 3 * Math.round(4 * root.d)) / 4)
        height: Math.round(68 * root.d)
        Rectangle {
            id: face
            anchors.horizontalCenter: parent.horizontalCenter
            y: Math.round(4 * root.d)
            width: Math.round(40 * root.d)
            height: width
            radius: AtollStyle.iconRadius(width)
            color: tile.on ? AtollStyle.tintFill(tile.modelData.tint) : tileArea.containsMouse ? AtollStyle.fillHover : AtollStyle.fillQuiet
            border.width: tile.on ? 0 : 1
            border.color: AtollStyle.border
            scale: tileArea.pressed ? AtollStyle.pressScale(0.92) : 1
            Behavior on color { ColorAnimation { duration: AtollStyle.duration(120); easing.type: AtollStyle.feedbackEasing } }
            Behavior on scale { NumberAnimation { duration: AtollStyle.feedbackDuration; easing.type: AtollStyle.feedbackEasing } }
            MaterialSymbol {
                anchors.centerIn: parent
                text: tile.modelData.glyph
                fill: tile.on ? 1 : 0
                iconSize: Math.round(20 * root.d)
                color: tile.on ? tile.modelData.tint : AtollStyle.text
            }
        }
        Rectangle {
            anchors.right: face.right
            anchors.top: face.top
            anchors.rightMargin: -Math.round(4 * root.d)
            anchors.topMargin: -Math.round(4 * root.d)
            width: Math.round(15 * root.d)
            height: width
            radius: width / 2
            color: tile.on ? (tileArea.containsMouse ? AtollStyle.danger : AtollStyle.surfaceHighestOpaque)
                : (tileArea.containsMouse ? AtollStyle.accent : AtollStyle.surfaceHighestOpaque)
            MaterialSymbol {
                anchors.centerIn: parent
                text: tile.on ? "remove" : "add"
                fill: 1
                iconSize: Math.round(11 * root.d)
                color: tileArea.containsMouse ? AtollStyle.onTint : AtollStyle.text
            }
        }
        AtollText {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: face.bottom
            anchors.topMargin: Math.round(4 * root.d)
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: tile.modelData.label
            color: tile.on ? AtollStyle.text : AtollStyle.subtext
            font.pixelSize: AtollStyle.typeCaption
            elide: Text.ElideRight
        }
        MouseArea {
            id: tileArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            Accessible.role: Accessible.CheckBox
            Accessible.name: tile.modelData.label
            Accessible.checked: tile.on
            onClicked: AtollLockOptions.toggleWidget(root.screenName, tile.modelData.key)
        }
    }
}
