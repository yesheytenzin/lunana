pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// LUNANA SHIM (not vendored from inir).
// inir's real GlobalStates is a 161-prop open/close bus for every panel. lunana
// grows this shim wave by wave: each family surface declares the members it
// reads, and only those exist. Wave-A ii dock/bar + Wave-B Waffle members;
// everything else lands with its surface.
//
// R3: the four toggles the exact ii bar/dock/media tree actually calls are
// wired to the real lunana overlay surfaces through the host summon path
// (`omarchy-shell shell toggle <id>`, same pattern as
// scripts/keybinds/lunana.lua). Fire-and-forget: one Process per summon,
// destroyed on exit, output ignored. The lunana overlays own their
// open/close state, so the mirrored bools below stay for tree compat only.
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

    function openEqualizer(outputName) { root._summon("lunana.control-center"); }
    function openOverview(outputName) { root._summon("lunana.overview"); }
    function openRegionScreenshot() {}
    function openSidebarRight(outputName) { root._summon("lunana.control-center"); }
    function toggleOverview(outputName) { root._summon("lunana.overview"); }
    // No lunana settings surface exists; Control Center hosts the Settings
    // quick action, so it is the summon target here too.
    function toggleSettings() { root._summon("lunana.control-center"); }

    // Mapping: inir overview -> lunana.overview (workspace columns, live);
    // inir right sidebar / equalizer / settings -> lunana.control-center
    // (right-docked panel; volume/mute/Settings live there). Left sidebar
    // keeps its own keybind summon; nothing in the bar tree calls it.
    Component {
        id: summonerFactory
        Process {}
    }
    function _summon(id) {
        const proc = summonerFactory.createObject(root, {
            command: ["omarchy-shell", "shell", "toggle", String(id)]
        });
        if (!proc) return;
        proc.exited.connect(function () { proc.destroy(); });
        proc.running = true;
    }
}
