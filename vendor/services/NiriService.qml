pragma Singleton
import QtQuick
import Quickshell

// LUNANA SHIM (not vendored from inir) — Wave-A 2a load stub.
// The exact ii dock reads Niri windows behind `CompositorService.isNiri`
// (false on Omarchy/Hyprland), so these members only need to exist for the
// tree to load. Real Hyprland backing (focus/close via hyprctl) lands with
// the live-windows unit.
Singleton {
    property var windows: []
    property var activeWindow: null
    function focusWindow(windowId) {}
    function closeWindow(windowId) {}
}
