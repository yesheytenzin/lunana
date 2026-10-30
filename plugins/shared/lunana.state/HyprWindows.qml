import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../../lunana-vendor/services" as LnServ

// HyprWindows — Hyprland window-model mirror for Niri-shaped consumers.
//
// Inir's NiriService publishes `windows` / `allWorkspaces` / `mruWindowIds`
// from the Niri socket; on Hyprland those stay empty and Niri-shaped
// consumers (orbit, and anything else reading the Niri model) see nothing.
// This mirror translates Hyprland's toplevel/workspace models into the exact
// shapes those consumers read, but ONLY while the compositor is Hyprland
// without Niri — when a Niri socket exists, NiriService owns its fields and
// this stays dormant.
//
// Window ids are small stable ints keyed by Hyprland address (NOT the raw
// address parsed as a number): QML `int`-typed consumers — the orbit's
// cursorId, card ids, NiriService action args — truncate 64-bit values to
// 32 bits on assignment, silently corrupting the lookup. Small ints match
// Niri's own id shape and survive every int round-trip. Ids are stable per
// address for the session; dead addresses are pruned so the table stays
// bounded (a pruned id simply stops resolving, and closes become no-ops).
// Window actions (close/focus/move) route through NiriService's socket
// functions, which the vendor patch redirects to hl.dsp.* on Hyprland.
// Previews stay off: Hyprland has no per-window capture path.
Item {
  id: root

  // address -> small stable int id.
  property var _addrToId: ({})
  property int _nextWinId: 1

  function _windowIdFor(address: string): int {
    const key = String(address ?? "")
    if (!key)
      return -1
    let id = -1
    try { id = Number(root._addrToId[key] ?? -1) } catch (e) { id = -1 }
    if (!(id >= 1)) {
      id = root._nextWinId
      root._nextWinId = root._nextWinId + 1
      const next = Object.assign({}, root._addrToId)
      next[key] = id
      root._addrToId = next
    }
    return id
  }

  function _pruneIds(live: var): void {
    try {
      const keep = {}
      for (const addr of live) keep[String(addr)] = true
      const next = {}
      let dropped = false
      for (const addr in root._addrToId) {
        if (keep[addr]) next[addr] = root._addrToId[addr]
        else dropped = true
      }
      if (dropped) root._addrToId = next
    } catch (e) {}
  }

  readonly property bool active: {
    try {
      return LnServ.CompositorService.isHyprland && !LnServ.CompositorService.isNiri
    } catch (e) {
      return false
    }
  }

  function _monName(mon): string {
    try {
      if (typeof mon === "string")
        return mon
      return String(mon?.name ?? "")
    } catch (e) {
      return ""
    }
  }

  // Last published population, for the shell log (quiet unless it changes).
  property string _lastReport: ""
  function _report(wins, aws): void {
    try {
      const ids = wins.map(w => String(w.id));
      const key = wins.length + ":" + aws.length + ":" + ids.join(",");
      if (key !== root._lastReport) {
        root._lastReport = key;
        console.info("[lunana.hypr-windows] mirroring " + wins.length + " windows: [" + ids.join(", ") + "]");
      }
    } catch (e) {}
  }

  function rebuild(): void {
    if (!root.active)
      return
    try { Hyprland.refreshToplevels() } catch (e) {}
    try {
      const tls = Array.from(Hyprland.toplevels?.values ?? [])
      const wins = []
      const liveAddrs = []
      for (let i = 0; i < tls.length; i++) {
        const t = tls[i]
        if (!t)
          continue
        let li = null
        try { li = t.lastIpcObject ?? null } catch (e) { li = null }
        let wsId = -1
        try { wsId = li?.workspace?.id ?? t.workspace?.id ?? -1 } catch (e) { wsId = -1 }
        let appId = ""
        try { appId = String(t.wayland?.appId ?? "") } catch (e) { appId = "" }
        if (!appId) {
          try { appId = String(li?.class ?? "") } catch (e) { appId = "" }
        }
        let title = ""
        try { title = String(t.title ?? "") } catch (e) { title = "" }
        let addr = ""
        try { addr = String(t.address ?? "").replace(/^0x/, "") } catch (e) { addr = "" }
        // Small stable int id (see _windowIdFor): raw address hex does not
        // fit QML's 32-bit int consumers. Unmapped addresses stay -1, which
        // the orbit treats as "no window" and ignores.
        const wid = root._windowIdFor(addr)
        if (addr !== "")
          liveAddrs.push(addr)
        let active = false
        try { active = !!t.activated } catch (e) { active = false }
        wins.push({
          id: wid,
          address: addr,
          app_id: appId,
          title: title,
          workspace_id: wsId,
          is_active: active,
          is_focused: active
        })
      }
      root._pruneIds(liveAddrs)
      LnServ.NiriService.windows = wins

      const focusedWsId = (() => {
        try { return Hyprland.focusedWorkspace?.id ?? null } catch (e) { return null }
      })()
      const wss = Array.from(Hyprland.workspaces?.values ?? [])
      const aws = []
      for (let i = 0; i < wss.length; i++) {
        const w = wss[i]
        if (!w)
          continue
        let id = -1
        try { id = w.id ?? -1 } catch (e) { id = -1 }
        let name = ""
        try { name = String(w.name ?? "") } catch (e) { name = "" }
        const output = root._monName(w.monitor)
        const isActive = focusedWsId !== null && id === focusedWsId
        // The focused toplevel on this workspace, else anything on it.
        let activeWin = null
        for (let j = 0; j < wins.length; j++) {
          if (wins[j].workspace_id === id && (activeWin === null || wins[j].is_active))
            activeWin = wins[j].id
          if (activeWin !== null && wins[j].workspace_id === id && wins[j].is_active)
            break
        }
        aws.push({
          id: id,
          idx: id,
          name: name,
          output: output,
          is_active: isActive,
          active_window_id: activeWin
        })
      }
      LnServ.NiriService.allWorkspaces = aws
      root._report(wins, aws)

      // Same small-int id space as window.id above; skip addresses with
      // no live mapping (closed windows).
      try {
        const keys = LnServ.CompositorService.mruWindowKeys ?? []
        const ids = []
        for (let i = 0; i < keys.length; i++) {
          const addr = String(keys[i] ?? "").replace(/^0x/, "")
          const id = Number(root._addrToId[addr] ?? -1)
          if (id >= 1)
            ids.push(id)
        }
        LnServ.NiriService.mruWindowIds = ids
      } catch (e) {}
    } catch (e) {
      console.warn("[lunana.hypr-windows] rebuild failed: " + e)
    }
  }

  Timer {
    id: rebuildTimer
    interval: 120
    onTriggered: root.rebuild()
  }

  function schedule(): void {
    if (!root.active)
      return
    rebuildTimer.restart()
  }

  Connections {
    target: LnServ.CompositorService
    function onIsHyprlandChanged(): void { root.schedule() }
    function onIsNiriChanged(): void { root.schedule() }
  }
  Connections {
    target: Hyprland.toplevels
    function onValuesChanged(): void { root.schedule() }
  }
  Connections {
    target: Hyprland.workspaces
    function onValuesChanged(): void { root.schedule() }
  }
  Connections {
    target: Hyprland
    function onActiveToplevelChanged(): void { root.schedule() }
    function onFocusedWorkspaceChanged(): void { root.schedule() }
  }

  Component.onCompleted: {
    // The initial IPC dump lands asynchronously; rebuild now and twice
    // more to catch it without polling forever.
    root.schedule()
    warmTimer.start()
  }
  Timer {
    id: warmTimer
    interval: 600
    repeat: false
    onTriggered: {
      root.rebuild()
      warmTimer2.start()
    }
  }
  Timer {
    id: warmTimer2
    interval: 1500
    repeat: false
    onTriggered: root.rebuild()
  }
}
