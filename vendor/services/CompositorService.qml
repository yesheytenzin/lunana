pragma Singleton
import QtQuick
import Quickshell
// LUNANA SHIM — inir's compositor facade. lunana targets Hyprland (Omarchy).
// The real inir CompositorService already has Hyprland paths and will be vendored
// when surfaces need live window/workspace data; this covers Appearance's probe.
Singleton {
    readonly property bool isHyprland: true
    readonly property bool isNiri: false
}
