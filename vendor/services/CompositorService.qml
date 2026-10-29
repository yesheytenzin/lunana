pragma Singleton
import QtQuick
import Quickshell
// LUNANA SHIM — inir's compositor facade. lunana targets Hyprland (Omarchy).
// The real inir CompositorService already has Hyprland paths and will be vendored
// when surfaces need live window/workspace data; this covers Appearance's probe.
Singleton {
    readonly property bool isHyprland: true
    readonly property bool isNiri: false

    // Wave-A 2a load stubs: the ii dock sorts/registers through these.
    // Null-safe callers render empty until the live-windows unit backs them.
    property var sortedToplevels: []
    function acquireSortingConsumer() {}
    function releaseSortingConsumer() {}
    function setSortingConsumer(name, active) {}
}
