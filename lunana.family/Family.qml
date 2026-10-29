import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Commons as Commons

// lunana.family — R6 bar-family switcher (kind: service).
//
// Cycles the live bar-family set ii -> stock today (waffle/iRiS plug in as
// one-line FAMILIES additions in family-cycle once their bar hosts land):
// selects the family's bar host via shell.json bar.id and enables exactly
// that family's overlay set. Shared data services (lunana.state,
// lunana.dock) are never touched. Bound to Super+Shift+W; the result lands in
// the journal so the switch is provable.
//
// Reachable as `omarchy-shell lunana.family cycle`.
Scope {
  id: root
  property var shell: null
  property var manifest: null

  readonly property string helper: Quickshell.env("HOME")
    + "/.config/omarchy/plugins/lunana.family/family-cycle"

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

  ShellIpc {
    target: "lunana.family"
    function cycle(): void { cycler.running = true }
  }

  Component.onCompleted: console.log("[lunana.family] family switcher loaded (ii <-> stock)")
}
