pragma Singleton
import QtQuick
import Quickshell

// LUNANA SHIM (not vendored from inir).
// inir's real GlobalStates is a 161-prop open/close bus for every panel. lunana
// grows this shim wave by wave: each family surface declares the members it
// reads, and only those exist. Wave-A ii dock members plus Wave-A step 3 ii
// bar members; everything else lands with its surface. toggleOverview is a
// no-op until Wave-A wires it to lunana.overview's ShellIpc toggle.
Singleton {
    id: root

    property int activeContextMenuCount: 0
    // Wave-A step 3 load stub: defaults mirror inir (barOpen true so the exact
    // bar loader activates; screens stay null until live backing lands).
    property bool barOpen: true
    property bool controlPanelOpen: false
    property bool coverflowSelectorOpen: false
    property var focusedScreen: null
    property bool mediaControlsOpen: false
    property bool osdBrightnessOpen: false
    property bool osdVolumeOpen: false
    property bool oskOpen: false
    property bool overviewOpen: false
    property var primaryScreen: null
    property bool screenLocked: false
    property bool shellEntryReady: true
    property bool shellLayoutEditMode: false
    property bool sidebarLeftOpen: false
    property string sidebarLeftPresentationOutput: ""
    property bool sidebarRightOpen: false
    property string sidebarRightPresentationOutput: ""
    property string sidebarRightRequestedWidget: ""
    property bool superDown: false
    property bool wallpaperLauncherOpen: false
    property bool widgetEditMode: false

    function openEqualizer(outputName) {}
    function openSidebarRight(outputName) {}
    function toggleOverview(outputName) {}
    function toggleSettings() {}
}
