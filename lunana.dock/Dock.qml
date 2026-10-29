import QtQuick
import Quickshell
import "../lunana-vendor/" as Inir
import Quickshell.Io
import "../lunana-vendor/modules/dock" as LnDock

// lunana.dock — exact ii dock host (kind: service).
//
// Mounts inir's exact dock Scope from the shared lunana-vendor/ tree.
//
// Family coherence: the iRiS family owns its own dock (lunana.iris-dock), so
// this host stands down whenever the switcher has lunana.iris-dock enabled
// and returns the moment it is disabled — mirroring lunana.bar/Bar.qml's
// yield to lunana.iris. Fail-visible: an unreadable shell.json keeps today's
// dock.
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

    readonly property bool yieldToIrisDock: {
        try {
            var plugins = JSON.parse(shellFile.text()).plugins;
            if (!Array.isArray(plugins))
                return false;
            for (var i = 0; i < plugins.length; ++i)
                if (plugins[i] && plugins[i].id === "lunana.iris-dock")
                    return true;
        } catch (err) {}
        return false;
    }

    Loader {
        active: !root.yieldToIrisDock
        sourceComponent: LnDock.Dock {}
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
