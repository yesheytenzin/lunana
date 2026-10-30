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
// Window actions (close/focus/move) still route through NiriService's
// socket functions, so listings on Hyprland are browse-only until the
// dispatcher call-sites are ported (see PORTING.md). Previews stay off:
// Hyprland has no per-window capture path.
Item {
  id: root

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

  function rebuild(): void {
    if (!root.active)
      return
    try { Hyprland.refreshToplevels() } catch (e) {}
    try {
      const tls = Array.from(Hyprland.toplevels?.values ?? [])
      const wins = []
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
        try { addr = String(t.address ?? "") } catch (e) { addr = "" }
        // Orbit (and Niri itself) keys windows by int id. Derive one stably
        // from the Hyprland address hex; unparseable addresses become -1,
        // which the orbit treats as "no window" and ignores.
        let wid = -1
        try {
          const num = parseInt(String(addr).replace(/^0x/, ""), 16)
          wid = isNaN(num) ? -1 : num
        } catch (e) { wid = -1 }
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

      // Same int-id space as window.id above (parsed address hex).
      try {
        const keys = LnServ.CompositorService.mruWindowKeys ?? []
        const ids = []
        for (let i = 0; i < keys.length; i++) {
          const num = parseInt(String(keys[i] ?? "").replace(/^0x/, ""), 16)
          if (!isNaN(num))
            ids.push(num)
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
