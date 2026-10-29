pragma Singleton
import QtQuick
import Quickshell

// LUNANA SHIM (not vendored from inir) — Wave-A + Wave-B load stub union.
// Wave-A: the exact ii bar toggles sidebars through slot addresses; no-op
// until the sidebar waves wire lunana.sidebar-left/right into these slots.
// Wave-B: ShellEditSession (vendored exact) drives surfaces through the family
// layout members during shell-edit gestures; results keep the .ok/.message
// shape callers check.
Singleton {
    property string activeFamily: ""

    function sidebarOpenAtSlot(slot, output) { return false }
    function toggleSidebarAtSlot(slot, output) {}

    function descriptor(surfaceId) { return null }
    function surfacesForFamily(family) { return [] }
    function currentState(surfaceId, outputName) { return ({}) }
    function validatePlacement(surfaceId, slot, outputName) {
        return ({ ok: false, message: "load stub: no layout backing" })
    }
    function moveSurface(surfaceId, slot, outputName) {
        return ({ ok: false, message: "load stub: no layout backing" })
    }
    function resetSurface(surfaceId, outputName) {
        return ({ ok: false, message: "load stub: no layout backing" })
    }
    function setProperty(surfaceId, key, value, outputName) {
        return ({ ok: false, message: "load stub: no layout backing" })
    }
    function diagnosticState(outputName) { return ({}) }
}
