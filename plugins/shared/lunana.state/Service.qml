import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import "../../lunana-vendor/" as Lunana
import "../../lunana-vendor/modules/common" as LnCommon

// lunana.state — shared state service (kind: service).
//
// Owns the Omarchy-facing `lunana` subtree in shell.json:
//
//   "lunana": { "family": "drift", "themeSource": "omarchy-tokens" }
//
// `themeSource` selects the token pipeline feeding the vendored Appearance /
// Looks / AtollStyle modules:
// - `omarchy-tokens` (default): Omarchy's hue owns the palette. This service
//   never touches lunana Config — today's behavior preserved exactly.
// - `material-you` (opt-in): arms the vendored pipeline by ensuring lunana
//   Config `appearance.theme` is "auto", then `generateMaterialYou(path)`
//   runs the vendored switchwall.sh color pipeline for that wallpaper;
//   MaterialThemeLoader applies the generated colors.json live. Side effects
//   (GTK/terminal themes) stay inside $HOME like the rest of the suite.
//
// It also performs the shell-entry handshake the vendored tree expects from
// lunana's shell.qml boot sequence: panels start gated on
// GlobalStates.shellEntryReady (bar slides in, on-demand loaders arm) and
// later on deferredPanelsReady. Omarchy owns theming/icons/compositor — the
// lunana ThemeService/IconThemeService boot calls are deliberately NOT
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
    readonly property string family: root.normalizeFamily(lunanaConfig.family ?? "drift")
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
            console.log("[lunana.state] material-you armed (lunana theme=auto)")
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
    // Mirrors lunana shell.qml `panelFamilies`: which vendored panels each family
    // enables. The vendored tree gates internal behavior on
    // Config.options.enabledPanels (e.g. AtollReservations/the chassis read
    // enabledPanels.includes("atollBar") for chassisPresent, OSD gating), so this
    // must track the family alongside panelFamily.
    readonly property var panelFamilies: ({
        "drift": ["driftBar", "driftBackground", "driftBackdrop", "driftBootGreeting", "driftCheatsheet",
            "driftControlPanel", "driftDock", "driftLock", "driftMediaControls", "driftNotificationPopup",
            "driftOnScreenDisplay", "driftOnScreenKeyboard", "driftOverlay", "driftOverview", "driftPolkit",
            "driftRegionSelector", "driftScreenCorners", "driftSessionScreen", "driftSidebarLeft",
            "driftSidebarRight", "driftTilingOverlay", "driftVerticalBar", "driftWallpaperSelector",
            "driftWallpaperLauncher", "driftCoverflowSelector", "driftClipboard", "driftShellUpdate",
            "driftRecordingOsd", "driftDashboard", "driftMascotCompanion"],
        "slate": ["slateBar", "slateBackground", "slateBackdrop", "slateStartMenu", "slateActionCenter",
            "slateNotificationCenter", "slateNotificationPopup", "slateOnScreenDisplay", "slateWidgets",
            "slateTaskView", "slateLock", "slatePolkit", "slateSessionScreen", "driftBootGreeting", "driftCheatsheet",
            "driftOnScreenKeyboard", "driftOverlay", "driftOverview", "driftRegionSelector", "driftScreenCorners",
            "driftWallpaperSelector", "driftWallpaperLauncher", "driftCoverflowSelector", "driftClipboard",
            "driftShellUpdate", "driftMascotCompanion"],
        "atoll": ["atollBar", "atollBackground", "atollPalette", "atollControlCenter",
            "atollNotificationPopup", "atollOnScreenDisplay", "atollSessionScreen",
            "atollLock", "atollPolkit"]
    })

    // One-time brand migration (pre-rename installs): old family names,
    // panel ids and config subtrees map onto the new ones. New installs never
    // hit these branches; they exist so an update does not orphan settings.
    readonly property var legacyFamilies: ({ "drift": "drift", "slate": "slate", "atoll": "atoll" })
    function normalizeFamily(name: string): string {
        return root.legacyFamilies[name] ?? name
    }
    function normalizePanelId(id: string): string {
        return String(id).replace(/^drift(?=[A-Z])/, "drift").replace(/^w(?=[A-Z])/, "slate").replace(/^atoll(?=[A-Z])/, "atoll")
    }
    function migrateLegacyConfig(): void {
        if (!LnCommon.Config.ready)
            return
        try {
            const opts = LnCommon.Config.options ?? ({})
            const fam = String(opts.panelFamily ?? "")
            if (root.legacyFamilies[fam])
                LnCommon.Config.setNestedValue(["panelFamily"], root.legacyFamilies[fam])
            const panels = opts.enabledPanels
            if (Array.isArray(panels)) {
                const mapped = panels.map(p => root.normalizePanelId(p))
                if (mapped.some((p, i) => p !== panels[i]))
                    LnCommon.Config.setNestedValue(["enabledPanels"], mapped)
            }
            if (opts.atoll === undefined && opts.atoll !== undefined)
                LnCommon.Config.setNestedValue(["atoll"], opts.atoll)
            if (opts.slate === undefined && opts.slate !== undefined)
                LnCommon.Config.setNestedValue(["slate"], opts.slate)
        } catch (err) {
            console.warn("[lunana.state] brand migration failed: " + err)
        }
    }
    function syncPanelFamily(): void {
        if (!LnCommon.Config.ready)
            return
        root.migrateLegacyConfig()
        const want = root.family === "stock" ? "drift" : root.family
        const panels = root.panelFamilies[want] ?? []
        const curFamily = String(LnCommon.Config.options.panelFamily ?? "")
        const curPanels = LnCommon.Config.options.enabledPanels ?? []
        const panelsMatch = Array.isArray(curPanels) && curPanels.length === panels.length
            && panels.every(p => curPanels.includes(p))
        if (curFamily === want && panelsMatch)
            return
        try {
            LnCommon.Config.setNestedValue(["panelFamily"], want)
            LnCommon.Config.setNestedValue(["enabledPanels"], panels)
            console.log("[lunana.state] panelFamily -> " + want + " (" + panels.length + " panels)")
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
        running: LnCommon.Config.ready && !Lunana.GlobalStates.shellEntryReady
        onTriggered: {
            Lunana.GlobalStates.shellEntryReady = true;
            deferredTimer.start();
        }
    }
    Timer {
        id: deferredTimer
        interval: 500
        repeat: false
        onTriggered: Lunana.GlobalStates.deferredPanelsReady = true
    }

    Component.onCompleted: {
        console.log("[lunana.state] family=" + root.family + " themeSource=" + root.themeSource)
        root.armMaterialYou()
        root.syncPanelFamily()
    }

    // Hyprland window-model mirror for Niri-shaped consumers (orbit et al).
    // Dormant unless the compositor is Hyprland without Niri. See file.
    HyprWindows {
    }
}
