pragma Singleton
import QtQuick
import Quickshell

// LUNANA SHIM (not vendored from inir) — Wave-A 2a load stub.
// Badge counts stay zero until wired to Omarchy's notification service.
Singleton {
    function countForApp(appIds) { return 0 }
    function markReadForApp(appIds) {}
}
