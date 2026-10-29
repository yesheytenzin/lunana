pragma Singleton
import QtQuick
import Quickshell

// LUNANA STUB (not vendored from inir) — R4 load stub.
// The Waffle taskbar counts/restores minimized windows per app; live window
// tracking is out of scope, so counts stay zero and actions are no-ops.
Singleton {
    function countMinimizedForApp(appId) { return 0 }
    function minimize(id) {}
    function restoreLatestForApp(appId) {}
}
