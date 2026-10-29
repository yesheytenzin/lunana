pragma Singleton
import QtQuick
import Quickshell

// LUNANA SHIM (not vendored from inir) — Wave-C R5 load stub.
// Screen-time stats for iRiS pieces; live tracking lands with its unit.
Singleton {
    property bool enabled: false
    function getAppList(days) { return [] }
    function requestDays(days) {}
}
