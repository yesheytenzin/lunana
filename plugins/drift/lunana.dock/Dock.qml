import QtQuick
import Quickshell
import "../../lunana-vendor/" as Lunana
import Quickshell.Io
import "../../lunana-vendor/modules/dock" as LnDock

// lunana.dock — exact drift dock host (kind: service).
//
// Mounts lunana's exact dock Scope from the shared lunana-vendor/ tree.
//
// Family coherence: the Atoll family owns its own dock inside the consolidated
// lunana.atoll chassis, so this host stands down whenever the switcher has
// lunana.atoll enabled and returns the moment it is disabled — mirroring
// lunana.bar/Bar.qml's yield to lunana.atoll. Fail-visible: an unreadable
// shell.json keeps today's dock.
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
        sourceComponent: LnDock.Dock {}
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
