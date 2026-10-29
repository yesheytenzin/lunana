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
    // Wave-C R5: the exact members the iRiS Island/Stage closure reads, with
    // inir's defaults. Orbit needs Hyprland rewrite: irisOrbitOpen exists so
    // the Island loads, but nothing Niri-backed opens it on Omarchy.

    function openEqualizer(outputName) {}
    function openOverview(outputName) {}
    function openRegionScreenshot() {}
    function openSidebarRight(outputName) {}
    function openSidebarLeft(outputName) {}
    function openSettingsPage(index, section) {}
    function toggleOverview(outputName) {}
    function toggleSettings() {}
    function closeSidebarLeft() { sidebarLeftOpen = false }
    function closeSidebarRight() { sidebarRightOpen = false }
    function setWidgetEditMode(enabled) { if (!enabled) irisEdit = false }
    function quietIrisLevels() { irisLevelQuietUntil = Date.now() + 700 }

    property real irisLevelQuietUntil: 0
    property var irisMorphOrigin: null
    property string irisMorphOwner: ""
    property string irisIslandPageRequest: ""
    property var irisBubbleCard: null
    property string irisBubbleCardRequest: ""
    property string irisBubbleMenuRequest: ""
    property bool irisArrange: false
    property var irisDockBody: ({})
    property var irisDockHome: null
    property bool irisControlEdit: false
    property string irisControlTab: "controls"
    property string irisControlPickerRequest: ""
    property bool irisEdit: false
    property string irisEditSelection: ""
    property string irisEditTarget: ""
    property var irisBubbleDrag: null
    property var irisBubbleKinds: ({})
    property var irisIslandGeometry: ({})
    property var irisAbsorbed: ({})
    property bool irisIslandExpanded: false
    property bool irisOrbitOpen: false
    property bool irisControlsWarm: false
    property bool irisSettingsWarm: false
    property string irisIslandShape: ""
    property string irisIslandPage: ""
    property bool osdMicOpen: false
    property bool osdMediaOpen: false
    property bool osdKeyboardLayoutOpen: false
    property bool settingsOverlayOpen: false
    property bool regionSelectorOpen: false
    property string wallpaperSelectorTargetMonitor: ""
    property bool wallpaperSelectorOpen: false
}
