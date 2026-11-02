import QtQuick
import Quickshell
import Quickshell.Io
import "../../lunana-vendor/" as Lunana
import "../../lunana-vendor/modules/bar" as LnBar

// lunana.bar — exact drift bar host (kind: bar).
//
// Mounts lunana's exact bar Scope from the shared lunana-vendor/ tree (installed
// once by lunana-suite). Selected via shell.json -> bar.id = "lunana.bar".
//
// Family coherence: drift and Atoll share this host. While the Atoll family is
// active the island alone owns the top edge, so the exact tree stands down
// whenever the switcher has lunana.atoll enabled and returns the moment it is
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

    readonly property bool yieldToAtoll: {
        try {
            var plugins = JSON.parse(shellFile.text()).plugins;
            if (!Array.isArray(plugins))
                return false;
            for (var i = 0; i < plugins.length; ++i)
                if (plugins[i] && plugins[i].id === "lunana.atoll")
                    return true;
        } catch (err) {}
        return false;
    }

    Loader {
        active: !root.yieldToAtoll
        sourceComponent: LnBar.Bar {}
    }

    // Shell-entry handshake against the shared lunana-vendor/ tree (one
    // GlobalStates universe for all hosts): the vendored tree gates first paint on
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
