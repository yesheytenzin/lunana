pragma Singleton
import QtQuick
import Quickshell

// LUNANA SHIM (not vendored from inir) — Wave-A 2a load stub.
// Icon-name resolution is identity until backed by the real theme lookup;
// candidates are empty so callers fall through to their defaults.
Singleton {
    function smartIconName(icon, appId) { return icon || appId || "" }
    function dockIconCandidates(iconName) { return [] }
}
