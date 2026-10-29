import QtQuick
import Quickshell
import "../lunana-vendor/" as Inir
import Quickshell.Io
import "../lunana-vendor/modules/waffle/bar" as LnBar

// lunana.bar-waffle — exact Waffle wBar host (kind: bar).
//
// Mounts inir's exact WaffleBar Scope from the shared lunana-vendor/ tree.
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
