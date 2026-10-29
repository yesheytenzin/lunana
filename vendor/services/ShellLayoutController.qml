pragma Singleton
import QtQuick
import Quickshell

// LUNANA SHIM (not vendored from inir) — Wave-A load stub.
// The exact ii bar toggles sidebars through slot addresses; no-op until the
// sidebar waves wire lunana.sidebar-left/right into these slots.
Singleton {
    function sidebarOpenAtSlot(slot, output) { return false }
    function toggleSidebarAtSlot(slot, output) {}
}
