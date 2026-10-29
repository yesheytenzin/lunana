pragma Singleton
import QtQuick
import Quickshell

// LUNANA SHIM (not vendored from inir) — Wave-C R5 load stub.
// Screen-time stats for iRiS pieces; live tracking lands with its unit.
Singleton {
    property bool enabled: false
    // inir parity: fired when a day-range finishes loading. The shim has no
    // tracker yet, so it never fires — but the signal must exist for the
    // island's focus-time Connections to attach.
    signal rangeLoaded(days: int, data: var)
    function getAppList(days) { return [] }
    function requestDays(days) {}
}
