import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Commons as Commons
import "../../lunana-vendor/" as Lunana

// lunana.family — bar-family switcher (kind: service).
//
// Cycles the live bar-family set drift -> slate -> atoll -> stock: selects the
// family's bar host via shell.json bar.id and enables exactly that family's
// owned plugin set. drift and atoll share the lunana.bar host; while atoll is
// active the bar yields so the island alone owns the top edge, and the drift
// dock yields to the atoll dock. Only lunana.state is shared (never touched).
// Bound to Super+Shift+W; the result lands in the journal so the switch is
// provable.
//
// Reachable as `omarchy-shell lunana.family cycle`.
Scope {
  id: root
  property var shell: null
  property var manifest: null

  readonly property string helper: Quickshell.env("HOME")
    + "/.config/omarchy/plugins/lunana.family/family-cycle"
  readonly property string family: {
    try {
      return JSON.parse(shellFile.text()).lunana?.family ?? "drift"
    } catch (err) {}
    return "drift"
  }

  FileView {
    id: shellFile
    path: Quickshell.env("HOME") + "/.config/omarchy/shell.json"
    blockLoading: true
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
  }

  Process {
    id: cycler
    command: ["python3", root.helper, "cycle"]
    stdout: StdioCollector {
      onStreamFinished: console.log("[lunana.family] " + String(text).trim())
    }
    stderr: StdioCollector {
      onStreamFinished: {
        var msg = String(text).trim()
        if (msg.length > 0) console.warn("[lunana.family] " + msg)
      }
    }
  }

  Process {
    id: setter
    stdout: StdioCollector {
      onStreamFinished: console.log("[lunana.family] " + String(text).trim())
    }
    stderr: StdioCollector {
      onStreamFinished: {
        var msg = String(text).trim()
        if (msg.length > 0) console.warn("[lunana.family] " + msg)
      }
    }
  }

  function setFamily(name: string): void {
    setter.command = ["python3", root.helper, "set", name]
    setter.running = true
  }

  Process {
    id: legacyAction
  }

  function runLegacy(action: string): void {
    const legacyTargets = ({
      overview: "lunana.overview",
      focus: "lunana.sidebar-left",
      today: "lunana.sidebar-right",
      controls: "lunana.control-center",
      cheatsheet: "lunana.cheatsheet",
      region: "lunana.region",
      settings: "lunana.settings"
    })
    const target = legacyTargets[action]
    if (!target)
      return
    legacyAction.command = ["omarchy-shell", "shell", "toggle", target]
    legacyAction.running = true
  }

  function route(action: string): void {
    if (root.family !== "atoll") {
      runLegacy(action)
      return
    }

    switch (action) {
    case "focus": Lunana.GlobalStates.toggleSidebarLeft(""); break
    case "today": Lunana.GlobalStates.toggleSidebarRight(""); break
    case "controls": Lunana.GlobalStates.controlPanelOpen = !Lunana.GlobalStates.controlPanelOpen; break
    case "overview": Lunana.GlobalStates.searchOpen = !Lunana.GlobalStates.searchOpen; break
    case "cheatsheet": Lunana.GlobalStates.cheatsheetOpen = !Lunana.GlobalStates.cheatsheetOpen; break
    case "region": Lunana.GlobalStates.regionSelectorOpen = !Lunana.GlobalStates.regionSelectorOpen; break
    case "settings": Lunana.GlobalStates.settingsOverlayOpen = !Lunana.GlobalStates.settingsOverlayOpen; break
    default: return
    }
  }

  ShellIpc {
    target: "lunana.family"
    function cycle(): void { cycler.running = true }
    function set(name: string): void { root.setFamily(name) }
    function overview(): void { root.route("overview") }
    function focus(): void { root.route("focus") }
    function today(): void { root.route("today") }
    function controls(): void { root.route("controls") }
    function cheatsheet(): void { root.route("cheatsheet") }
    function region(): void { root.route("region") }
    function settings(): void { root.route("settings") }
  }

  Component.onCompleted: console.log("[lunana.family] family switcher loaded (drift -> slate -> atoll -> stock)")
}
