import QtQuick
import Quickshell
import Quickshell.Io

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
// Fail-visible: an unreadable shell.json keeps the defaults.
Scope {
    id: root

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

    readonly property var lunanaConfig: {
        try {
            return JSON.parse(shellFile.text()).lunana ?? {};
        } catch (err) {}
        return {};
    }

    Component.onCompleted: console.log("[lunana.state] family=" + root.family
        + " themeSource=" + root.themeSource)
}
