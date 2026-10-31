import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import "../../lunana-vendor/" as Inir

// lunana.iris — the consolidated iRiS shell (kind: service, on by default).
//
// Faithful mount of inir's real iRiS composition in ONE plugin (so every
// surface shares one GlobalStates):
//   Chassis.qml  mirrors modules/iris/critical/ShellIrisCriticalPanels.qml
//                (IrisReservations + the IrisBar chassis: island, dock, control,
//                 spotlight, gallery, orbit, edit, stage, banners — with the
//                 full input regions, piece hit-rects and gating).
//   Panels.qml   mirrors modules/iris/ShellIrisPanelsImpl.qml (sidebars,
//                settings, OSD, session, lock, background, studio, OSK, region,
//                wallpaper, recording, tiling, cheatsheet, polkit, …).
//
// Mounted directly because omarchy-shell is not inir's host, so
// IrisGate.official is false and inir's own loaders would gate everything off.
// Config must set panelFamily="iris" and enabledPanels to the iris set (the
// chassis reads enabledPanels.includes("irisBar")) — lunana.state/family-cycle.
Scope {
    id: root

    property var shell: null
    property var manifest: null

    Chassis {}
    Panels {}

    // The island is always shown; expose its actions so keybinds can summon any
    // iRiS surface, driving the same shared GlobalStates the island's own
    // buttons use.
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
