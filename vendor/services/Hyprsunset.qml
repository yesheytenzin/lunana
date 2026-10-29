pragma Singleton
import QtQuick
import Quickshell

// LUNANA STUB (not vendored from inir) — R4 load stub.
// Night-light toggle state; hyprsunset integration is out of scope, so it
// stays off and toggle/fetch are no-ops.
Singleton {
    property bool active: false

    function fetchState() {}
    function toggle(on) {}
}
