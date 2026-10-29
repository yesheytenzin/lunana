pragma Singleton
import QtQuick
import Quickshell

// LUNANA SHIM (not vendored from inir) — Wave-A load stub.
// The exact ii bar reads the active workspace and per-workspace windows
// here; empty until the live-windows unit backs this with Hyprland IPC.
Singleton {
    property var activeWorkspace: null
    property var monitors: []
    function biggestWindowForWorkspace(workspace) { return null }
}
