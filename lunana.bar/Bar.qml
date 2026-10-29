import QtQuick
import Quickshell
import Quickshell.Io
import "vendor/modules/bar" as LnBar

// lunana.bar — exact ii bar host (kind: bar).
//
// Full cutover: the M0-M4 approximation is gone. This entry point mounts inir's
// exact bar Scope (vendored) directly; the suite materializes its
// import-closure subset under the installed plugin's vendor/ (see
// lunana-suite VENDOR_ROOTS). Selected via shell.json -> bar.id = "lunana.bar".
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
}
