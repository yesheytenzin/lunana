pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../../../common/widgets"
import "../../style"
import "../../components"

// The line a scene ends on. It sits directly in its PreviewScene, and its text also titles the Settings hero that
// shows the preview in compact form.
Rectangle {
    id: caption
    property string text: ""
    property string glyph: "info"
    readonly property Item preview: caption.parent?.preview ?? null
    anchors.left: parent.left
    anchors.bottom: parent.bottom
    anchors.margins: Math.round(14 * AtollStyle.density)
    implicitWidth: captionRow.implicitWidth + Math.round(22 * AtollStyle.density)
    implicitHeight: Math.round(28 * AtollStyle.density)
    radius: height / 2
    color: AtollStyle.veilHeavy
    visible: caption.text.length > 0 && !(caption.preview?.compact ?? false)
    Binding { target: caption.preview; property: "caption"; value: caption.text }
    RowLayout {
        id: captionRow
        anchors.centerIn: parent
        spacing: Math.round(6 * AtollStyle.density)
        MaterialSymbol { text: caption.glyph; iconSize: Math.round(14 * AtollStyle.density); color: AtollStyle.subtext }
        AtollText { text: caption.text; font.pixelSize: AtollStyle.typeMeta; color: AtollStyle.text }
    }
}
