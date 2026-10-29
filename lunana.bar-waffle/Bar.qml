import QtQuick
import Quickshell
import Quickshell.Io
import "vendor/modules/waffle/bar" as LnBar

// lunana.bar-waffle — exact Waffle wBar host (kind: bar).
//
// Mounts inir's exact WaffleBar Scope (vendored) directly; the suite
// materializes its import-closure subset under the installed plugin's vendor/.
// Selected via shell.json -> bar.id = "lunana.bar-waffle" by family-cycle's
// waffle entry. Fail-visible: an unreadable shell.json keeps today's bar.
Scope {
  id: root

  FileView {
    id: shellFile
    path: Quickshell.env("HOME") + "/.config/omarchy/shell.json"
    blockLoading: true
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
  }

  readonly property bool selected: {
    try {
      return (JSON.parse(shellFile.text()).bar || {}).id === "lunana.bar-waffle";
    } catch (err) {}
    return false;
  }

  Loader {
    active: root.selected
    sourceComponent: LnBar.WaffleBar {}
  }
}
