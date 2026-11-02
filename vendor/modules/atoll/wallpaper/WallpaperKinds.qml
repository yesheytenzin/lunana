pragma ComponentBehavior: Bound

import QtQuick
import "../components"
import "../style"

AtollSegmented {
    id: root
    required property var picker
    readonly property bool wanted: (root.picker?.kindsPresent ?? []).length > 2

    glyphOnly: true
    implicitHeight: Math.round(34 * AtollStyle.density)
    accessibleName: "Kind"
    options: (root.picker?.kindsPresent ?? []).map(entry => ({ value: entry.id, label: entry.label, glyph: entry.glyph }))
    current: String(root.picker?.kind ?? "all")
    onPicked: value => root.picker.kind = value
}
