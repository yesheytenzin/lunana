pragma Singleton
import QtQuick
import Quickshell

// LUNANA SHIM (not vendored from inir).
// inir's real GlobalStates is a 161-prop open/close bus for every panel. lunana
// grows this shim wave by wave: each family surface declares the members it
// reads, and only those exist. Wave-A ii dock/bar + Wave-B Waffle members;
// everything else lands with its surface. Toggles are no-ops until wired to
// lunana's ShellIpc.
Singleton {
    id: root

    property int activeContextMenuCount: 0
    // Defaults mirror inir (barOpen true so the exact bar loader activates;
    // screens stay null until live backing lands).
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
    property bool searchOpen: false
    property bool sessionOpen: false
    property bool shellEntryReady: true
    property bool shellLayoutEditMode: false
    property bool sidebarLeftOpen: false
    property string sidebarLeftPresentationOutput: ""
    property bool sidebarRightOpen: false
    property string sidebarRightPresentationOutput: ""
    property string sidebarRightRequestedWidget: ""
    property bool superDown: false
    property bool wallpaperLauncherOpen: false
    property bool waffleActionCenterOpen: false
    property bool waffleAltSwitcherOpen: false
    property bool waffleClipboardOpen: false
    property bool waffleNotificationCenterOpen: false
    property bool waffleTaskViewOpen: false
    property bool waffleWidgetsOpen: false
    property bool widgetEditMode: false

    function openEqualizer(outputName) {}
    function openOverview(outputName) {}
    function openRegionScreenshot() {}
    function openSidebarRight(outputName) {}
    function toggleOverview(outputName) {}
    function toggleSettings() {}
}
