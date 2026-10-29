pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland

// LUNANA LIVE (R3) — backed by Quickshell.Hyprland.
//
// Replaces the Wave-A load stub. The exact ii bar reads the active workspace
// and per-workspace windows here (ActiveWindow.qml, Workspaces.qml:546);
// shapes mirror `hyprctl monitors -j` / `clients -j` entries the way inir's
// HyprlandData exposes them, but sourced from live Quickshell objects — the
// same ones lunana.bar/Bar.qml already uses live (monitorFor, focusedMonitor,
// toplevels, ToplevelManager).
//
// `_rev` is poked on every compositor rawEvent so these bindings re-evaluate
// on workspace/focus changes. Pure in-process reads — no hyprctl re-poll.
Singleton {
    id: root

    property int _rev: 0
    Connections {
        target: Hyprland
        function onRawEvent(): void { root._rev++; }
    }

    // Keyed by Hyprland monitor id: { id, name, activeWorkspace: { id } }.
    // ActiveWindow.qml indexes it as monitors[monitor.id].activeWorkspace.id.
    readonly property var monitors: {
        const _poke = root._rev;
        const out = ({});
        const screens = Quickshell.screens ?? [];
        for (let i = 0; i < screens.length; ++i) {
            const m = Hyprland.monitorFor(screens[i]);
            if (!m) continue;
            out[m.id] = {
                id: m.id,
                name: m.name,
                activeWorkspace: { id: m.activeWorkspace ? m.activeWorkspace.id : 1 }
            };
        }
        return out;
    }

    // { id, monitor: <monitor name> }; compared against monitor.name by
    // ActiveWindow.qml (focusingThisMonitor).
    readonly property var activeWorkspace: {
        const _poke = root._rev;
        const m = Hyprland.focusedMonitor;
        return {
            id: m && m.activeWorkspace ? m.activeWorkspace.id : 1,
            monitor: m ? String(m.name ?? "") : ""
        };
    }

    // Quickshell exposes no window geometry, so "biggest" prefers the
    // activated window, else the first on the workspace. Wrapped in the
    // { class, title } shape inir's hyprctl objects carry for the fallbacks.
    function biggestWindowForWorkspace(workspaceId): var {
        const _poke = root._rev;
        const wsNum = Number(workspaceId);
        if (!isFinite(wsNum)) return null;
        const tls = Hyprland.toplevels ? (Hyprland.toplevels.values ?? []) : [];
        let best = null;
        for (let i = 0; i < tls.length; ++i) {
            const tl = tls[i];
            if (!tl || !tl.workspace || Number(tl.workspace.id) !== wsNum) continue;
            if (tl.activated) { best = tl; break; }
            if (!best) best = tl;
        }
        if (!best) return null;
        const w = best.wayland;
        return {
            address: best.address,
            class: String(w ? (w.appId ?? "") : ""),
            title: String(w ? (w.title ?? "") : ""),
            workspace: { id: wsNum }
        };
    }
}
