import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.Commons
import "../../lunana-vendor/" as Inir
import "../../lunana-vendor/modules/common" as LnCommon
import "../../lunana-vendor/modules/closeConfirm" as LnMod
import "../../lunana-vendor/modules/iris/closeConfirm" as LnIrisMod

// lunana.closeconfirm — Hyprland-native close-confirm host (kind: overlay).
//
// The vendored inir CloseConfirm is niri-only (NiriService.activeWindow +
// `niri msg` trigger/close), so it cannot open on Hyprland. This host keeps
// the vendored dialog *content* (ii/waffle/iris variants) and re-implements
// only the trigger/close path on Hyprland: snapshot the focused toplevel
// at trigger time (Hyprland.activeToplevel, with a direct `hyprctl
// activewindow` query as fallback), show the dialog, and close via
// Omarchy's Lua dispatcher dialect (Hyprland.dispatch hl.dsp.window.close).
//
// Toggled via `omarchy-shell lunana.closeconfirm toggle`. When
// Config.options.closeConfirm.enabled is false the focused window closes
// immediately with no dialog, matching the vendored fast path.
Item {
  id: root

  property var shell: null
  property var manifest: null

  // Window captured at trigger time (prevents race with focus changes).
  // Shape matches what the vendored content reads: app_id + title.
  property var targetWindow: null
  property var dialogScreen: null
  property bool dialogVisible: false
  readonly property bool opened: root.dialogVisible

  readonly property bool confirmEnabled: LnCommon.Config.options?.closeConfirm?.enabled ?? false

  // Debounce to prevent double-trigger
  property bool _busy: false
  Timer {
    id: debounce
    interval: 200
    onTriggered: root._busy = false
  }

  // Hyprland IPC populates activeToplevel asynchronously; right after a shell
  // restart it can still be null while the compositor already has focus.
  // Refresh and retry a few times, and ask the compositor directly (below)
  // before giving up.
  property int _openAttempt: 0
  // Generation guard: a late hyprctl answer must not open the dialog after
  // an explicit close (or a newer open) superseded its query.
  property int _openGen: 0
  property int _queryGen: -1
  Timer {
    id: openRetry
    interval: 250
    onTriggered: root._attemptOpen()
  }

  // Quickshell's cached activeToplevel/activated flags can go stale (e.g.
  // right after a shell restart with no new focus events). Ask the
  // compositor directly, mirroring the vendored niri focused-window query.
  property string _hyprBuf: ""
  Process {
    id: hyprActiveProc
    command: ["hyprctl", "activewindow", "-j"]
    stdout: SplitParser {
      onRead: line => {
        root._hyprBuf += line
        let info = null
        try { info = JSON.parse(root._hyprBuf) } catch (e) { return }
        if (!info || typeof info !== "object")
          return
        const addr = String(info.address ?? "")
        if (!addr)
          return
        openRetry.stop()
        if (root.dialogVisible)
          return
        if (root._queryGen !== root._openGen)
          return
        root._queryGen = -1
        const snap = {
          "address": addr,
          "app_id": String(info.class ?? ""),
          "title": String(info.title ?? "")
        }
        if (!root.confirmEnabled) {
          root._closeAddressFast(snap.address, snap.app_id)
          return
        }
        root.targetWindow = snap
        root.dialogScreen = root._focusedScreen()
        root.dialogVisible = true
      }
    }
  }

  function _snapshotToplevel(toplevel): var {
    if (!toplevel)
      return null
    let address = ""
    let appId = ""
    let title = ""
    try { address = String(toplevel.address ?? "") } catch (e) { address = "" }
    try { title = String(toplevel.title ?? "") } catch (e) { title = "" }
    try { appId = String(toplevel.wayland?.appId ?? "") } catch (e) { appId = "" }
    if (!appId) {
      try { appId = String(toplevel.lastIpcObject?.class ?? "") } catch (e) { appId = "" }
    }
    if (!address && !appId && !title)
      return null
    return { "address": address, "app_id": appId, "title": title }
  }

  function _focusedScreen(): var {
    try {
      const s = Inir.GlobalStates.focusedScreen
      if (s)
        return s
    } catch (e) {}
    if (Quickshell.screens.length > 0)
      return Quickshell.screens[0]
    return null
  }

  function _fallbackToplevel(): var {
    try {
      const vals = Array.from(Hyprland.toplevels?.values ?? [])
      for (let i = 0; i < vals.length; i++) {
        if (vals[i]?.activated)
          return vals[i]
      }
    } catch (e) {}
    return null
  }

  function _attemptOpen(): void {
    let toplevel = null
    try { toplevel = Hyprland.activeToplevel } catch (e) { toplevel = null }
    let snap = root._snapshotToplevel(toplevel)
    if (!snap)
      snap = root._snapshotToplevel(root._fallbackToplevel())
    if (snap) {
      if (!root.confirmEnabled) {
        root._closeAddressFast(snap.address, snap.app_id)
        return
      }
      root.targetWindow = snap
      root.dialogScreen = root._focusedScreen()
      root.dialogVisible = true
      return
    }
    if (root._openAttempt < 5) {
      root._openAttempt++
      if (root._openAttempt === 1) {
        // First miss: ask the compositor for ground truth in parallel with
        // the Quickshell IPC refresh below.
        root._hyprBuf = ""
        root._queryGen = root._openGen
        try { hyprActiveProc.running = true } catch (e) {}
      }
      try { Hyprland.refreshToplevels() } catch (e) {}
      openRetry.restart()
      return
    }
    console.warn("[lunana.closeconfirm] no focused window to confirm")
  }

  function _closeAddressFast(address: string, appId: string): void {
    // Quickshell exposes the toplevel address without the 0x prefix while
    // the window selector needs it (cf. WorkspaceStrip, which prepends 0x
    // before dispatching).
    let addr = String(address ?? "").replace(/^0x/, "")
    if (!addr)
      return
    addr = "0x" + addr
    // Omarchy's Hyprland speaks the Lua dispatcher dialect on its socket:
    // `dispatch <dispatcher> <params>` is shorthand for hl.dispatch(...),
    // so the upstream `closewindow address:…` form is a Lua syntax error
    // here. (Verified against the nested compositor: the upstream form
    // errors, the dsp form below replies ok and closes the window.)
    // No Spotify minimize parity: that staging is niri-specific; on
    // Hyprland Spotify closes like any other window.
    try {
      Hyprland.dispatch('hl.dsp.window.close({ window = "address:' + addr + '" })')
    } catch (e) {
      console.warn("[lunana.closeconfirm] close failed: " + e)
    }
  }

  function open(payloadJson) {
    if (root._busy)
      return
    root._busy = true
    debounce.restart()
    root._openGen++
    root._openAttempt = 0
    openRetry.stop()
    root._attemptOpen()
  }

  function close() {
    root._openGen++
    openRetry.stop()
    root.dialogVisible = false
    root.targetWindow = null
    root.dialogScreen = null
  }

  function cancel() { root.close() }

  function confirmClose() {
    const win = root.targetWindow
    root.close()
    if (win)
      root._closeAddressFast(win.address ?? "", win.app_id ?? "")
  }

  function toggle() { root.opened ? root.close() : root.open("") }

  ShellIpc {
    target: "lunana.closeconfirm"
    function toggle(): void { root.toggle() }
    function open(): void { root.open("") }
    function close(): void { root.close() }
  }

  // Dialog UI — mirrors the vendored CloseConfirm layer (fullscreen
  // keyboard-exclusive overlay), with the content variant chosen by
  // panelFamily like the original.
  Loader {
    active: root.dialogVisible

    sourceComponent: PanelWindow {
      screen: root.dialogScreen ?? Inir.GlobalStates.focusedScreen ?? (Quickshell.screens.length > 0 ? Quickshell.screens[0] : null)

      anchors {
        top: true
        left: true
        right: true
        bottom: true
      }

      color: "transparent"
      WlrLayershell.namespace: "quickshell:closeConfirm"
      WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
      WlrLayershell.layer: WlrLayer.Overlay
      exclusionMode: ExclusionMode.Ignore

      Loader {
        id: contentLoader
        anchors.fill: parent
        focus: true
        // Both contents declare targetWindow as required, so they must be
        // instantiated from an inline Component. A Loader source URL cannot
        // initialize required properties and fails to Loader.Error, leaving
        // this keyboard-exclusive fullscreen window with no way out.
        sourceComponent: LnCommon.Config.options?.panelFamily === "waffle" ? waffleContent
          : LnCommon.Config.options?.panelFamily === "iris" ? irisContent : iiContent
        onLoaded: if (item) item.forceActiveFocus()

        Component {
          id: iiContent
          LnMod.CloseConfirmContent {
            targetWindow: root.targetWindow
            onConfirm: root.confirmClose()
            onCancel: root.cancel()
          }
        }

        Component {
          id: waffleContent
          LnMod.WCloseConfirmContent {
            targetWindow: root.targetWindow
            onConfirm: root.confirmClose()
            onCancel: root.cancel()
          }
        }

        Component {
          id: irisContent
          LnIrisMod.IrisCloseConfirmContent {
            targetWindow: root.targetWindow
            onConfirm: root.confirmClose()
            onCancel: root.cancel()
          }
        }
      }
    }
  }

  // Shell-entry handshake in this plugin's singleton universe (each
  // installed plugin carries its own vendor/ copy, hence its own
  // GlobalStates): the vendored tree gates first paint on
  // shellEntryReady/deferredPanelsReady, which only inir's shell.qml boot
  // sets. Mirror the minimal sequence here.
  Timer {
    interval: 200; repeat: false; running: true
    onTriggered: {
      Inir.GlobalStates.shellEntryReady = true;
      Inir.GlobalStates.deferredPanelsReady = true;
    }
  }
}
