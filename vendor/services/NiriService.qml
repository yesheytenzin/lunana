pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// LUNANA shim backed for Hyprland (R1).
// The exact ii dock reads Niri windows behind `CompositorService.isNiri`
// (false on Omarchy/Hyprland), so `windows`/`activeWindow` stay empty and the
// Niri call sites are unreachable — but focusWindow/closeWindow are real: they
// dispatch through hyprctl via a Quickshell.Io Process, the same fire-and-forget
// pattern ControlCenter uses for wpctl/brightnessctl writes.
Singleton {
    id: root
    property var windows: []
    property var activeWindow: null
    property var currentOutput: null

    Process {
        id: hyprDispatch
        running: false
    }

    function _dispatch(args) {
        if (!args || args.length === 0) return
        hyprDispatch.running = false
        hyprDispatch.command = ["hyprctl", "dispatch"].concat(args)
        hyprDispatch.running = true
    }

    // Niri window ids are numeric; Hyprland dispatch wants address:class:title.
    // Accept "address:0x…" directly, otherwise focus by the given token.
    function focusWindow(windowId) {
        if (windowId === undefined || windowId === null || String(windowId).length === 0) return
        const token = String(windowId)
        if (token.startsWith("address:"))
            _dispatch(["focuswindow", token])
        else
            _dispatch(["focuswindow", "address:" + token])
    }

    function closeWindow(windowId) {
        if (windowId === undefined || windowId === null || String(windowId).length === 0) return
        const token = String(windowId)
        if (token.startsWith("address:"))
            _dispatch(["closewindow", token])
        else
            _dispatch(["closewindow", "address:" + token])
    }
}
