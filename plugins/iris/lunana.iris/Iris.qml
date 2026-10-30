import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import "../../lunana-vendor/" as Inir

// lunana.iris — the consolidated iRiS shell (kind: service, on by default).
//
// Every iRiS surface lives in THIS one plugin, so they share ONE GlobalStates.
// That is what makes the island's own buttons work: the island writes
// GlobalStates.settingsOverlayOpen / sessionOpen / sidebarLeftOpen / etc., and
// the settings/session/sidebar/control surfaces — mounted here beside it — see
// the write. (Split across separate plugins each had its own GlobalStates, so
// the island could not reach them.) It also lets one IrisField fuse the island,
// dock and surround frame, and lets the edge reservations react to live sidebar
// and dock state.
//
// Each surface is a sibling .qml in this directory; Qt resolves them by name.
Scope {
    id: root

    property var shell: null
    property var manifest: null

    // Always-present chrome.
    Background {}
    SurroundFrame {}
    Reservations {}
    Dock {}
    Island {}

    // On-demand surfaces (self-gate on the GlobalStates flag the island sets).
    Settings {}
    Session {}
    Sidebars {}
    Control {}
    Orbit {}
    Palette {}
    EditMode {}
    Wallpaper {}

    // Ambient.
    Osd {}
    Notifications {}
    LockHost {}

    // The island is always shown. These drive the shared GlobalStates the same
    // way the island's own buttons do — so keybinds can summon any iRiS surface,
    // and the handoff is the same one the buttons use (one GlobalStates).
    ShellIpc {
        target: "lunana.iris"
        function toggle(): void {}
        function open(): void {}
        function close(): void {}
        function settings(): void { Inir.GlobalStates.openSettings() }
        function session(): void { Inir.GlobalStates.sessionOpen = !Inir.GlobalStates.sessionOpen }
        function focus(): void { Inir.GlobalStates.toggleSidebarLeft("") }
        function today(): void { Inir.GlobalStates.toggleSidebarRight("") }
        function controls(): void { Inir.GlobalStates.controlPanelOpen = !Inir.GlobalStates.controlPanelOpen }
        function spotlight(): void { Inir.GlobalStates.searchOpen = !Inir.GlobalStates.searchOpen }
        function orbit(): void { Inir.GlobalStates.irisOrbitOpen = !Inir.GlobalStates.irisOrbitOpen }
    }

    // Shell-entry handshake: the vendored tree gates first paint on
    // shellEntryReady/deferredPanelsReady, which only inir's shell.qml boot
    // sets. One sequence for the whole consolidated plugin.
    Timer {
        interval: 200; repeat: false; running: true
        onTriggered: {
            Inir.GlobalStates.shellEntryReady = true;
            Inir.GlobalStates.deferredPanelsReady = true;
        }
    }
}
