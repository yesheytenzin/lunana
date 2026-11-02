import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import "../../lunana-vendor/" as Lunana

// lunana.atoll — the consolidated Atoll shell (kind: service, on by default).
//
// Faithful mount of lunana's real Atoll composition in ONE plugin (so every
// surface shares one GlobalStates):
//   Chassis.qml  mirrors modules/atoll/critical/ShellIrisCriticalPanels.qml
//                (AtollReservations + the AtollBar chassis: island, dock, control,
//                 spotlight, gallery, orbit, edit, stage, banners — with the
//                 full input regions, piece hit-rects and gating).
//   Panels.qml   mirrors modules/atoll/ShellIrisPanelsImpl.qml (sidebars,
//                settings, OSD, session, lock, background, studio, OSK, region,
//                wallpaper, recording, tiling, cheatsheet, polkit, …).
//
// Mounted directly because omarchy-shell is not lunana's host, so
// AtollGate.official is false and lunana's own loaders would gate everything off.
// Config must set panelFamily="atoll" and enabledPanels to the atoll set (the
// chassis reads enabledPanels.includes("atollBar")) — lunana.state/family-cycle.
Scope {
    id: root

    property var shell: null
    property var manifest: null

    Chassis {}
    Panels {}

    // The island is always shown; expose its actions so keybinds can summon any
    // Atoll surface, driving the same shared GlobalStates the island's own
    // buttons use.
    ShellIpc {
        target: "lunana.atoll"
        function toggle(): void {}
        function open(): void {}
        function close(): void {}
        function settings(): void { Lunana.GlobalStates.openSettings() }
        function session(): void { Lunana.GlobalStates.sessionOpen = !Lunana.GlobalStates.sessionOpen }
        function focus(): void { Lunana.GlobalStates.toggleSidebarLeft("") }
        function today(): void { Lunana.GlobalStates.toggleSidebarRight("") }
        function controls(): void { Lunana.GlobalStates.controlPanelOpen = !Lunana.GlobalStates.controlPanelOpen }
        function spotlight(): void { Lunana.GlobalStates.searchOpen = !Lunana.GlobalStates.searchOpen }
        function orbit(): void { Lunana.GlobalStates.atollOrbitOpen = !Lunana.GlobalStates.atollOrbitOpen }
    }

    // Shell-entry handshake: the vendored tree gates first paint on
    // shellEntryReady/deferredPanelsReady, which only lunana's shell.qml boot
    // sets. One sequence for the whole consolidated plugin.
    Timer {
        interval: 200; repeat: false; running: true
        onTriggered: {
            Lunana.GlobalStates.shellEntryReady = true;
            Lunana.GlobalStates.deferredPanelsReady = true;
        }
    }
}
