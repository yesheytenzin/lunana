import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import "../../lunana-vendor/" as Inir
import "../../lunana-vendor/modules/common" as LnCommon

// lunana.state — shared state service (kind: service).
//
// Owns the Omarchy-facing `lunana` subtree in shell.json:
//
//   "lunana": { "family": "ii", "themeSource": "omarchy-tokens" }
//
// `themeSource` selects the token pipeline feeding the vendored Appearance /
// Looks / IrisStyle modules:
// - `omarchy-tokens` (default): Omarchy's hue owns the palette. This service
//   never touches inir Config — today's behavior preserved exactly.
// - `material-you` (opt-in): arms the vendored pipeline by ensuring inir
//   Config `appearance.theme` is "auto", then `generateMaterialYou(path)`
//   runs the vendored switchwall.sh color pipeline for that wallpaper;
//   MaterialThemeLoader applies the generated colors.json live. Side effects
//   (GTK/terminal themes) stay inside $HOME like the rest of the suite.
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

    readonly property string switchwallPath: Quickshell.env("HOME")
        + "/.config/omarchy/lunana-vendor/scripts/colors/switchwall.sh"

    FileView {
        id: shellFile
        path: Quickshell.env("HOME") + "/.config/omarchy/shell.json"
        blockLoading: true
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
    }

    function armMaterialYou(): void {
        if (!root.materialYou || !LnCommon.Config.ready)
            return
        try {
            LnCommon.Config.setNestedValue(["appearance", "theme"], "auto")
            console.log("[lunana.state] material-you armed (inir theme=auto)")
        } catch (err) {
            console.warn("[lunana.state] material-you arm failed: " + err)
        }
    }

    // family-cycle owns shell.json.lunana.family; the vendored tree gates its
    // panels on Config.options.panelFamily instead. Mirror the choice into the
    // vendored config whenever the family or Config readiness changes, so a
    // switch made from any surface (IPC, keybind, settings) reaches the
    // vendored panels. "stock" is outside the vendored domain and disables
    // every lunana panel anyway; keep the last real family there.
    function syncPanelFamily(): void {
        if (!LnCommon.Config.ready)
            return
        const want = root.family === "stock" ? "ii" : root.family
        if (String(LnCommon.Config.options.panelFamily ?? "") === want)
            return
        try {
            LnCommon.Config.setNestedValue(["panelFamily"], want)
            console.log("[lunana.state] panelFamily -> " + want)
        } catch (err) {
            console.warn("[lunana.state] panelFamily sync failed: " + err)
        }
    }

    function generateMaterialYou(wallpaperPath): void {
        const img = String(wallpaperPath ?? "")
        if (!root.materialYou) {
            console.log("[lunana.state] generateMaterialYou refused (themeSource is not material-you)")
            return
        }
        if (!img) {
            console.warn("[lunana.state] generateMaterialYou needs a wallpaper path")
            return
        }
        matugenProcess.command = ["/usr/bin/bash", root.switchwallPath, img]
        matugenProcess.running = true
    }

    Process {
        id: matugenProcess
        onExited: (code, status) => console.log("[lunana.state] switchwall exited", code, status)
    }

    ShellIpc {
        target: "lunana.state"
        function generateMaterialYou(wallpaperPath: string): void { root.generateMaterialYou(wallpaperPath) }
    }

    Connections {
        target: LnCommon.Config
        function onReadyChanged() {
            root.armMaterialYou()
            root.syncPanelFamily()
        }
    }
    onMaterialYouChanged: root.armMaterialYou()
    onFamilyChanged: root.syncPanelFamily()

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

    Component.onCompleted: {
        console.log("[lunana.state] family=" + root.family + " themeSource=" + root.themeSource)
        root.armMaterialYou()
        root.syncPanelFamily()
    }
}
