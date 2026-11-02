pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../../.."
import "../../common"
import "../../common/widgets"
import "../../atoll/style"

// A titled group inside a widget's quick controls: one quiet caption, then its controls.
ColumnLayout {
    id: root

    property string title: ""
    property string detail: ""
    default property alias content: body.data

    readonly property bool atoll: (Config.options?.panelFamily ?? "drift") === "atoll"
    readonly property real d: root.atoll ? AtollStyle.density : 1

    Layout.fillWidth: true
    spacing: Math.round(7 * root.d)

    RowLayout {
        visible: root.title.length > 0
        Layout.fillWidth: true
        spacing: Math.round(6 * root.d)

        StyledText {
            Layout.fillWidth: true
            text: root.title
            elide: Text.ElideRight
            color: root.atoll ? AtollStyle.textSecondary : Appearance.colors.colSubtext
            font.family: root.atoll ? AtollStyle.fontMain : Appearance.font.family.main
            font.pixelSize: root.atoll ? AtollStyle.typeMeta : Appearance.font.pixelSize.smallest
            font.weight: root.atoll ? AtollStyle.weight(Font.DemiBold) : Font.DemiBold
            font.capitalization: root.atoll || Appearance.editorialEverywhere ? Font.MixedCase : Font.AllUppercase
            font.letterSpacing: root.atoll ? 0 : 1
        }
        StyledText {
            visible: root.detail.length > 0
            text: root.detail
            color: root.atoll ? AtollStyle.textTertiary : Appearance.colors.colSubtext
            font.family: root.atoll ? AtollStyle.fontNumbers : Appearance.font.family.numbers
            font.features: ({ "tnum": 1 })
            font.pixelSize: root.atoll ? AtollStyle.typeMeta : Appearance.font.pixelSize.smallest
        }
    }

    ColumnLayout {
        id: body
        Layout.fillWidth: true
        spacing: Math.round(4 * root.d)
    }
}
