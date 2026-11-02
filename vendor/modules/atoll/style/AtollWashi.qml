pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import "../../common"
import "../../../services"

// Atoll's palette, solved once for the shell and the apps it themes. `scripts/colors/washi` turns what the person
// chose and the seeds of the wallpaper and the colour theme into every role of every scheme (paper, ink, accent,
// highlight, status, identity, widget data, app roles), each held to its contrast on every ground. This asks it
// again when a choice or a seed changes and keeps the last answer on disk, so a start shows it at once.
Singleton {
    id: root

    // The solver's version (scripts/colors/washi Version): a newer solver answers the same request again.
    readonly property int version: 23
    readonly property string cachePath: `${Directories.stateUserPath}/generated/atoll-washi.json`
    readonly property var appearance: Config.options?.atoll?.appearance ?? ({})
    readonly property bool followsTheme: String(ThemeService.currentTheme ?? "auto") !== "auto" && Boolean(root.appearance?.followTheme ?? true)
    // Omarchy's palette, stashed by the lunana theme-set hook in a sidecar
    // file beside the lunana config (a file of its own, so no FileView
    // contends with Config's own writes to config.json). Absent everywhere
    // except a lunana-managed Omarchy install, so standalone lunana never
    // sees it.
    readonly property var omarchyTheme: {
        try {
            return JSON.parse(omarchyThemeFile.text())
        } catch (e) {
            return ({})
        }
    }
    readonly property string omarchyThemePath: Directories.shellConfig + "/omarchy-theme.json"
    FileView {
        id: omarchyThemeFile
        path: root.omarchyThemePath
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
    }
    function omarchyThemeId(slug: string): string {
        switch (String(slug ?? "")) {
        case "catppuccin": return "catppuccin-mocha"
        case "catppuccin-latte": return "catppuccin-latte"
        case "everforest": return "everforest"
        case "gruvbox": return "gruvbox-material"
        case "kanagawa": return "kanagawa"
        case "nord": return "nord"
        case "rose-pine": return "rose-pine"
        case "tokyo-night": return "tokyo-night"
        case "dracula": return "dracula"
        default: return "auto"
        }
    }
    // True only while the lunana theme is the one Omarchy just set: a theme the
    // person picked by hand in settings keeps its own seeds.
    readonly property bool omarchySeedsLive: root.followsTheme
        && String(root.omarchyTheme.slug ?? "").length > 0
        && root.omarchyThemeId(root.omarchyTheme.slug) === String(ThemeService.currentTheme ?? "auto")
        && String(root.omarchyTheme.background ?? "").length > 0
        && String(root.omarchyTheme.accent ?? "").length > 0

    function hex(c: color): string {
        const part = v => ("0" + Math.round(Math.max(0, Math.min(1, v)) * 255).toString(16)).slice(-2)
        return "#" + part(c.r) + part(c.g) + part(c.b)
    }
    // Primitives only: a config write that changes none of these asks nothing.
    readonly property string requestJson: JSON.stringify({
        language: String(root.appearance?.language ?? "atoll"),
        variant: String(root.appearance?.variant ?? "tonalSpot"),
        material: root.followsTheme ? "theme" : String(root.appearance?.theme?.surface ?? "black"),
        glass: ["wallpaper", "compositor"].includes(String(root.appearance?.glass?.mode ?? "off")),
        inkStyle: String(root.appearance?.inkStyle ?? "washi"),
        darkStyle: String(root.appearance?.darkStyle ?? "style"),
        accent: root.followsTheme ? "theme" : String(root.appearance?.accent ?? "blue"),
        accentHue: Number(root.appearance?.theme?.accentHue ?? 212),
        highlight: root.followsTheme ? "theme" : String(root.appearance?.highlight ?? "orange"),
        highlightHue: Number(root.appearance?.theme?.highlightHue ?? 32),
        vibrance: Math.max(0, Math.min(100, Number(Config.options?.atoll?.widgets?.vibrance ?? 85))) / 100,
        tune: ["dark", "ink", "light"].reduce((out, name) => {
            const t = root.appearance?.tune?.[name]
            out[name] = { tone: Number(t?.tone ?? 0), colour: Number(t?.colour ?? 100), widgets: t?.widgets === undefined ? null : Number(t.widgets),
                warmth: t?.warmth === undefined ? null : Number(t.warmth) }
            return out
        }, ({})),
        seeds: {
            wallpaper: root.hex(Appearance.wallpaperDominantColor),
            primary: root.omarchySeedsLive ? String(root.omarchyTheme.accent) : (root.appsWearPalette ? String(root.wallpaperSeeds?.primary ?? "") : root.hex(Appearance.colors.colPrimary)),
            secondary: root.omarchySeedsLive && String(root.omarchyTheme.blue ?? "").length > 0 ? String(root.omarchyTheme.blue) : (root.appsWearPalette ? String(root.wallpaperSeeds?.secondary ?? "") : root.hex(Appearance.colors.colSecondary)),
            tertiary: root.omarchySeedsLive && String(root.omarchyTheme.magenta ?? "").length > 0 ? String(root.omarchyTheme.magenta) : (root.appsWearPalette ? String(root.wallpaperSeeds?.tertiary ?? "") : root.hex(Appearance.colors.colTertiary)),
            background: root.omarchySeedsLive ? String(root.omarchyTheme.background) : (root.appsWearPalette ? String(root.wallpaperSeeds?.background ?? root.hex(Appearance.m3colors.m3background))
                : root.hex(Appearance.m3colors.m3background))
        }
    })
    // While the apps wear this palette, the Material colours are its own output: the wallpaper's seeds come from the
    // generator's record of them (atoll-seeds.json), or "theme" would read back the accent it handed over.
    readonly property bool appsWearPalette: !root.followsTheme && String(ThemeService.currentTheme ?? "auto") === "auto"
        && Boolean(root.appearance?.materialForApps ?? true)
    readonly property var wallpaperSeeds: {
        try { return JSON.parse(root.seedsFile.text()) } catch (e) { return null }
    }
    readonly property FileView seedsFile: FileView {
        path: `${Directories.stateUserPath}/generated/atoll-seeds.json`
        watchChanges: true
        printErrors: false
        onFileChanged: this.reload()
    }

    function parse(text: string): var {
        try {
            const out = JSON.parse(text)
            return out?.schemes?.dark && out?.schemes?.ink && out?.schemes?.light ? out : null
        } catch (e) { return null }
    }
    // The last answer, or a fresh install's palette until the first one lands.
    property var data: root.parse(root.cache.text()) ?? root.parse(root.fallback.text())
    function palette(scheme: string): var {
        return root.data?.schemes?.[scheme] ?? root.data?.schemes?.dark ?? ({})
    }

    property bool again: false
    property bool warned: false
    function run(): void {
        if (root.data?.request === root.requestJson && root.data?.version === root.version) return
        if (solver.running) { root.again = true; return }
        solver.command = ["/usr/bin/bash", ((Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")) + "/omarchy/lunana-vendor/" + ("scripts/colors/washi.sh")), "--request", root.requestJson, "--out", root.cachePath]
        solver.running = true
    }
    // A slider's steps settle into one solve.
    readonly property Timer settle: Timer { interval: 60; onTriggered: root.run() }
    onRequestJsonChanged: root.settle.restart()
    Component.onCompleted: root.settle.restart()

    readonly property FileView cache: FileView { path: root.cachePath; blockLoading: true; printErrors: false }
    readonly property FileView fallback: FileView { path: ((Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")) + "/omarchy/lunana-vendor/" + ("defaults/atoll-washi.json")); blockLoading: true }
    readonly property Process solver: Process {
        stdout: StdioCollector {
            onStreamFinished: {
                const out = root.parse(this.text)
                if (out) root.data = out
            }
        }
        stderr: StdioCollector {
            onStreamFinished: if (this.text.trim().length > 0 && !root.warned) {
                root.warned = true
                console.warn("[AtollWashi]", this.text.trim())
            }
        }
        onExited: if (root.again) { root.again = false; root.settle.restart() }
    }
}
