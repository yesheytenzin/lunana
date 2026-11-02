pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../../../../services"
import "../../style"
import "../../components"
import "../parts"

PreviewScene {
    id: typeRoot
    readonly property real naturalWidth: Math.round(560 * typeRoot.d)
    readonly property real naturalHeight: Math.round(280 * typeRoot.d)
    Plate {
        anchors.centerIn: parent
        width: Math.round(480 * typeRoot.d)
        height: Math.round(216 * typeRoot.d)
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Math.round(24 * typeRoot.d)
            spacing: Math.round(6 * typeRoot.d)
            AtollText { text: Translation.tr("A little room to breathe"); font.family: AtollStyle.fontTitle; font.pixelSize: AtollStyle.typeTitleLarge; font.weight: AtollStyle.weight(Font.Medium) }
            AtollClock { pixelSize: 56 * AtollStyle.typeScale; separatorColor: AtollStyle.secondaryAccent }
            Rectangle { Layout.fillWidth: true; height: 1; color: AtollStyle.hairline }
            RowLayout {
                Layout.fillWidth: true
                AtollText { text: Translation.tr("Words, figures, one family"); color: AtollStyle.subtext }
                Item { Layout.fillWidth: true }
                AtollText { text: "Aa 0123"; color: AtollStyle.accent; font.pixelSize: AtollStyle.typeTitle }
            }
        }
    }
    Caption { glyph: "text_fields"; text: Translation.tr("Your typefaces, weight and text size") }
}
