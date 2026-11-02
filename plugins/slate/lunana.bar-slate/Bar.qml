import QtQuick
import Quickshell
import "../../lunana-vendor/" as Lunana
import Quickshell.Io
import "../../lunana-vendor/modules/slate/bar" as LnBar

// lunana.bar-slate — exact Slate wBar host (kind: bar).
//
// Mounts lunana's exact SlateBar Scope from the shared lunana-vendor/ tree.
// Selected via shell.json -> bar.id = "lunana.bar-slate" by family-cycle's
// slate entry. Fail-visible: an unreadable shell.json keeps today's bar.
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
      return (JSON.parse(shellFile.text()).bar || {}).id === "lunana.bar-slate";
    } catch (err) {}
    return false;
  }

  Loader {
    active: root.selected
    sourceComponent: LnBar.SlateBar {}
  }

    // Shell-entry handshake in this plugin's singleton universe (each
    // installed plugin carries its own vendor/ copy, hence its own
    // GlobalStates): the vendored tree gates first paint on
    // shellEntryReady/deferredPanelsReady, which only lunana's shell.qml boot
    // sets. Mirror the minimal sequence here.
    Timer {
        interval: 200; repeat: false; running: true
        onTriggered: {
            Lunana.GlobalStates.shellEntryReady = true;
            Lunana.GlobalStates.deferredPanelsReady = true;
        }
    }
}
