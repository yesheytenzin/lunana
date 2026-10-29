pragma Singleton
import QtQuick
import Quickshell

// LUNANA SHIM (not vendored from inir).
// inir's real GlobalStates is a 161-prop open/close bus for every panel. lunana
// grows this shim wave by wave: each family surface declares the members it
// reads, and only those exist. Wave-A ii dock members only; everything else
// lands with its surface. toggleOverview is a no-op until Wave-A wires it to
// lunana.overview's ShellIpc toggle.
Singleton {
    id: root

    property bool coverflowSelectorOpen: false
    property bool screenLocked: false
    property bool shellEntryReady: true
    // Wave-C: iRiS token family reads the focused screen for place output.
    property var focusedScreen: null
    property bool wallpaperLauncherOpen: false
    property bool widgetEditMode: false

    function toggleOverview(outputName) {}
}
