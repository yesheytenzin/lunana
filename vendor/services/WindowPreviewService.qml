pragma Singleton
import QtQuick
import Quickshell

// LUNANA SHIM (not vendored from inir) — Wave-A 2a load stub.
// Live window thumbnails stay empty until backed by Hyprland captures.
Singleton {
    function initialize() {}
    function getPreviewUrl(windowId) { return "" }
    function captureForTaskView(windowIds, timeoutMs) {}
}
