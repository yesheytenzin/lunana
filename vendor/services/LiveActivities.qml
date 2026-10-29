pragma Singleton
import QtQuick
import Quickshell

// LUNANA SHIM (not vendored from inir) — Wave-C R5 load stub.
// The iRiS bubble face reads `latest` for the task ring/glyph; live activity
// tracking lands with the activities service unit.
Singleton {
    property var list: []
    readonly property var latest: null
    // inir parity: fired when a live activity ends. The shim tracks
    // nothing yet, so it never fires — but the island's Connections needs it.
    signal finished(activity: var)
}
