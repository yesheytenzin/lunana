import QtQuick
import Quickshell
import Quickshell.Io
import "../lunana-vendor/" as Inir
import "../lunana-vendor/modules/common" as LnCommon

// lunana.state — shared state service (kind: service).
//
// Owns the Omarchy-facing `lunana` subtree in shell.json:
//
//   "lunana": { "family": "ii", "themeSource": "omarchy-tokens" }
//
// `themeSource` selects the token pipeline feeding the vendored Appearance /
// Looks / IrisStyle modules: `omarchy-tokens` (default, Omarchy's hue owns
// the palette) or `material-you` (wallpaper-derived via the vendored
// scripts/colors pipeline + MaterialThemeLoader — Wave 5 opt-in).
//
// It also performs the shell-entry handshake the vendored tree expects from
// inir's shell.qml boot sequence: panels start gated on
// GlobalStates.shellEntryReady (bar slides in, on-demand loaders arm) and
// later on deferredPanelsReady. Omarchy owns theming/icons/compositor — the
// inir ThemeService/IconThemeService boot calls are deliberately NOT
// mirrored here.
// Fail-visible: an unreadable shell.json keeps the defaults; flags stay false.
Scope {
    id: root

    readonly property var lunanaConfig: {
        try {
            return JSON.parse(shellFile.text()).lunana ?? {};
        } catch (err) {}
        return {};
    }
    readonly property string family: lunanaConfig.family ?? "ii"
    readonly property string themeSource: lunanaConfig.themeSource ?? "omarchy-tokens"
    readonly property bool materialYou: root.themeSource === "material-you"

    FileView {
        id: shellFile
        path: Quickshell.env("HOME") + "/.config/omarchy/shell.json"
        blockLoading: true
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
    }

    // Mirror of shell.qml's boot timers (entry animation delay, then
    // deferred tier). Run once per session; hot-reload reuses the flags.
    Timer {
        id: entryTimer
        interval: 200
        repeat: false
        running: LnCommon.Config.ready && !Inir.GlobalStates.shellEntryReady
        onTriggered: {
            Inir.GlobalStates.shellEntryReady = true;
            deferredTimer.start();
        }
    }
    Timer {
        id: deferredTimer
        interval: 500
        repeat: false
        onTriggered: Inir.GlobalStates.deferredPanelsReady = true
    }

    Component.onCompleted: console.log("[lunana.state] family=" + root.family
        + " themeSource=" + root.themeSource)
}
