import QtQuick
import Quickshell
import Quickshell.Io
import "../lunana-vendor/" as Inir
import "../lunana-vendor/modules/bar" as LnBar

// lunana.bar — exact ii bar host (kind: bar).
//
// Mounts inir's exact bar Scope from the shared lunana-vendor/ tree (installed
// once by lunana-suite). Selected via shell.json -> bar.id = "lunana.bar".
//
// Family coherence: ii and iRiS share this host. While the iRiS family is
// active the island alone owns the top edge, so the exact tree stands down
// whenever the switcher has lunana.iris enabled and returns the moment it is
// disabled. Fail-visible: an unreadable shell.json keeps today's bar.
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

    readonly property bool yieldToIris: {
        try {
            var plugins = JSON.parse(shellFile.text()).plugins;
            if (!Array.isArray(plugins))
                return false;
            for (var i = 0; i < plugins.length; ++i)
                if (plugins[i] && plugins[i].id === "lunana.iris")
                    return true;
        } catch (err) {}
        return false;
    }

    Loader {
        active: !root.yieldToIris
        sourceComponent: LnBar.Bar {}
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
