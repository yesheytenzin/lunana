pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import "../../common"
import "../../common/functions"
import "../style"
import "../../background/widgets"

Singleton {
    id: root

    readonly property string folder: FileUtils.trimFileProtocol(`${Directories.shellConfig}/atoll/themes`)
    readonly property var excludedPaths: ["atoll.bar.position", "atoll.dock.launcher", "atoll.appearance.surfaces.cards.header",
        "atoll.appearance.surfaces.cards.devices", "atoll.appearance.surfaces.cards.mixer",
        "atoll.dock.magnifySize",
        "atoll.bubbles.extras.anime.enable", "atoll.anime.shows"]
    readonly property var extraPaths: [
        { path: "atoll.appearance.preset", fallback: "atoll" },
        { path: "atoll.bar.composition", fallback: "cluster" },
        { path: "atoll.appearance.motionDuration", fallback: 220 },
        { path: "atoll.lock.material", fallback: "glass" },
        { path: "atoll.lock.type.clockWeight", fallback: 700 },
        { path: "atoll.lock.type.clockTracking", fallback: -2 },
        { path: "atoll.lock.type.accent", fallback: "plain" }
    ]
    readonly property var paths: {
        const seen = new Set()
        const out = []
        for (const entry of root.extraPaths) { seen.add(entry.path); out.push(entry) }
        for (const spec of AtollOptions.studio) {
            const path = String(spec.path ?? "")
            if (!path.startsWith("atoll.") || spec.kind === "pieces" || spec.fallback === undefined) continue
            if (seen.has(path) || root.excludedPaths.includes(path)) continue
            seen.add(path)
            out.push({ path: path, fallback: spec.fallback })
        }
        return out
    }
    readonly property var pathSet: new Set(root.paths.map(entry => entry.path))
    function owns(path: string): bool { return root.pathSet.has(path) }

    function resolved(values: var): var {
        const out = {}
        for (const entry of root.paths)
            out[entry.path] = Object.prototype.hasOwnProperty.call(values ?? {}, entry.path) ? values[entry.path] : entry.fallback
        return out
    }
    function current(): var {
        const out = {}
        for (const entry of root.paths) out[entry.path] = AtollOptions.plain(Config.getNestedValue(entry.path, entry.fallback))
        return out
    }
    function differences(values: var): var {
        const out = {}
        for (const entry of root.paths)
            if (!AtollOptions.same(values[entry.path], entry.fallback)) out[entry.path] = values[entry.path]
        return out
    }
    function apply(theme: var): void {
        if (!theme) return
        const updates = root.resolved(theme.values)
        // The widget design goes through its owner so every widget follows the theme and the looks
        // it replaces can be undone.
        const design = String(updates["atoll.widgets.design"] ?? "atoll")
        delete updates["atoll.widgets.design"]
        updates["atoll.appearance.themeId"] = String(theme.id ?? "")
        Config.setNestedValues(updates)
        DesktopWidgetDesign.apply(design)
    }
    // A theme's palette alone: what it colours, never how anything is shaped, laid out or moves.
    readonly property var colourPaths: ["atoll.appearance.accent", "atoll.appearance.highlight", "atoll.appearance.theme.accentHue",
        "atoll.appearance.theme.highlightHue", "atoll.appearance.theme.surface", "atoll.appearance.theme.badge", "atoll.appearance.aura",
        "atoll.appearance.theme.lightReach", "atoll.appearance.theme.glow", "atoll.appearance.tint", "atoll.appearance.theme.rimTint",
        "atoll.appearance.glass.edgeColour", "atoll.bar.clockAccent", "atoll.controlCenter.accent", "atoll.controlCenter.sliders",
        "atoll.lock.type.accent", "atoll.appearance.anime.enabled", "atoll.appearance.anime.palette", "atoll.appearance.anime.strength",
        "atoll.appearance.anime.highlight", "atoll.widgets.tint"]
    function applyColours(theme: var): void {
        if (!theme) return
        const all = root.resolved(theme.values)
        const updates = {}
        for (const path of root.colourPaths) if (Object.prototype.hasOwnProperty.call(all, path)) updates[path] = all[path]
        Config.setNestedValues(updates)
    }
    readonly property bool coloursOnly: Boolean(Config.options?.atoll?.appearance?.themeColoursOnly ?? false)
    // What choosing a theme does, as the person set it: the whole theme, or its colours.
    function choose(theme: var): void {
        if (root.coloursOnly) root.applyColours(theme)
        else root.apply(theme)
    }
    function find(id: string): var {
        return root.all.find(theme => theme.id === id) ?? null
    }
    readonly property string activeId: String(Config.options?.atoll?.appearance?.themeId ?? "atoll")
    readonly property var active: root.find(root.activeId)
    readonly property bool modified: {
        void Config.revision
        if (!root.active) return true
        const wanted = root.resolved(root.active.values)
        for (const entry of root.paths)
            if (!AtollOptions.same(Config.getNestedValue(entry.path, entry.fallback), wanted[entry.path])) return true
        return false
    }

    function slug(name: string): string {
        const base = String(name).toLowerCase().normalize("NFD").replace(/[\u0300-\u036f]/g, "")
            .replace(/[^a-z0-9]+/g, "-").replace(/^-+|-+$/g, "")
        return base.length > 0 ? base.slice(0, 48) : "theme"
    }
    function document(theme: var): var {
        return { atoll: "theme", version: 1, id: theme.id, name: theme.name, author: theme.author ?? "",
            description: theme.description ?? "", values: root.differences(root.resolved(theme.values)) }
    }
    function exportText(theme: var): string { return JSON.stringify(root.document(theme), null, 2) }
    function parse(text: string, fallbackId: string): var {
        let data = null
        try { data = JSON.parse(String(text).trim()) } catch (error) { return null }
        if (!data || (data.atoll !== "theme" && data.atoll !== "look") || typeof data.values !== "object") return null
        const values = {}
        for (const path of Object.keys(data.values)) if (root.owns(path)) values[path] = data.values[path]
        const name = String(data.name ?? "").trim() || Translation.tr("Imported theme")
        return { id: fallbackId.length > 0 ? fallbackId : root.slug(String(data.id ?? name)), name: name,
            author: String(data.author ?? ""), description: String(data.description ?? ""), values: values, user: true }
    }
    function uniqueId(base: string): string {
        let id = base
        let n = 2
        while (root.curated.some(theme => theme.id === id) || root.user.some(theme => theme.id === id && theme.id !== base)) id = `${base}-${n++}`
        return root.curated.some(theme => theme.id === id) ? `${base}-mine` : id
    }
    function save(name: string, description: string): string {
        const clean = String(name).trim() || Translation.tr("My theme %1").arg(root.user.length + 1)
        const id = root.uniqueId(root.slug(clean))
        const theme = { id: id, name: clean, author: Quickshell.env("USER") ?? "", description: String(description ?? "").trim(),
            values: root.differences(root.current()) }
        root.write(theme)
        Config.setNestedValue("atoll.appearance.themeId", id)
        return id
    }
    function importText(text: string): var {
        const theme = root.parse(text, "")
        if (!theme) return null
        theme.id = root.uniqueId(theme.id)
        root.write(theme)
        return theme
    }
    function importFile(path: string): void {
        importer.command = ["cat", FileUtils.trimFileProtocol(path)]
        importer.running = true
    }
    function remove(id: string): void {
        if (!root.user.some(theme => theme.id === id)) return
        writer.exec(["rm", "-f", `${root.folder}/${id}.json`])
    }
    function reveal(): void {
        Quickshell.execDetached(["bash", "-c", 'mkdir -p "$1" && xdg-open "$1"', "reveal", root.folder])
    }
    function write(theme: var): void { root.writeAll([theme]) }
    function writeAll(themes: var): void {
        const args = []
        for (const theme of themes) args.push(theme.id, root.exportText(theme))
        writer.exec(["python3", "-c", "import os,sys\nd=sys.argv[1]\nos.makedirs(d,exist_ok=True)\na=sys.argv[2:]\nfor i in range(0,len(a),2): open(os.path.join(d,a[i]+'.json'),'w',encoding='utf-8').write(a[i+1]+'\\n')",
            root.folder].concat(args))
    }
    signal imported(var theme)
    Process {
        id: importer
        stdout: StdioCollector {
            id: importedText
            onStreamFinished: {
                const theme = root.importText(importedText.text)
                root.imported(theme)
            }
        }
    }
    Process {
        id: writer
        onExited: root.reload()
    }

    property var user: []
    function reload(): void {
        loader.running = false
        loader.running = true
    }
    Process {
        id: loader
        command: ["python3", "-c", "import os,sys,json\nd=sys.argv[1]\nout=[]\nfor f in sorted(os.listdir(d)) if os.path.isdir(d) else []:\n  if f.endswith('.json'):\n    try: out.append([f[:-5], open(os.path.join(d,f),encoding='utf-8').read()])\n    except Exception: pass\nprint(json.dumps(out))",
            root.folder]
        stdout: StdioCollector {
            id: listing
            onStreamFinished: {
                let rows = []
                try { rows = JSON.parse(listing.text) } catch (error) { rows = [] }
                root.user = rows.map(row => root.parse(row[1], row[0])).filter(theme => theme !== null)
            }
        }
    }
    FolderListModel {
        id: watcher
        folder: `file://${root.folder}`
        nameFilters: ["*.json"]
        showDirs: false
        onCountChanged: root.reload()
    }
    Component.onCompleted: {
        root.reload()
        root.migrateSaved()
    }
    function migrateSaved(): void {
        const saved = Array.from(Config.options?.atoll?.appearance?.saved ?? [])
        if (saved.length === 0) return
        const themes = []
        for (const entry of saved) {
            const theme = root.parse(JSON.stringify({ atoll: "look", name: entry?.name, values: entry?.values ?? {} }), "")
            if (!theme) continue
            theme.id = root.uniqueId(theme.id)
            if (!themes.some(other => other.id === theme.id)) themes.push(theme)
        }
        if (themes.length > 0) root.writeAll(themes)
        Config.setNestedValue("atoll.appearance.saved", [])
    }

    readonly property var all: root.curated.concat(root.user)

    function swatch(theme: var): var {
        const v = root.resolved(theme?.values ?? {})
        const baseAccent = AtollStyle.accentFrom(String(v["atoll.appearance.accent"] ?? "blue"), v["atoll.appearance.theme.accentHue"])
        const animeOn = Boolean(v["atoll.appearance.anime.enabled"] ?? false)
        const animePalette = String(v["atoll.appearance.anime.palette"] ?? "sakura")
        const animeStrength = Number(v["atoll.appearance.anime.strength"] ?? 0) / 100
        const accent = animeOn ? AtollStyle.animeAccent(baseAccent, animePalette, animeStrength) : baseAccent
        const baseHighlight = AtollStyle.highlightFrom(String(v["atoll.appearance.highlight"] ?? "orange"), v["atoll.appearance.theme.highlightHue"], baseAccent)
        const highlight = animeOn && Boolean(v["atoll.appearance.anime.highlight"] ?? false)
            ? AtollStyle.animeHighlight(baseHighlight, animePalette, animeStrength) : baseHighlight
        const preset = AtollStyle.presets[v["atoll.appearance.preset"]] ?? AtollStyle.presets.atoll
        return {
            surface: AtollStyle.materialSwatch(String(v["atoll.appearance.theme.surface"])),
            accent: accent,
            highlight: highlight,
            glass: v["atoll.appearance.glass.mode"] !== "off",
            tint: Number(v["atoll.appearance.glass.tint"]) / 100,
            shape: preset.shape * Number(v["atoll.appearance.theme.shape"]) / 100,
            pieceShape: String(v["atoll.appearance.theme.pieceShape"]),
            lines: Number(v["atoll.appearance.theme.lines"]) / 100,
            rim: Boolean(v["atoll.appearance.theme.rim"]),
            titleFont: AtollStyle.face("atoll.appearance.titleFontFamily", v["atoll.appearance.titleFontFamily"]),
            numbersFont: AtollStyle.face("atoll.appearance.numbersFontFamily", v["atoll.appearance.numbersFontFamily"]),
            figureWeight: ({ light: Font.Light, regular: Font.Normal })[v["atoll.appearance.figureWeight"]] ?? Font.Bold,
            framed: Boolean(v["atoll.surround.enable"]),
            notch: Boolean(v["atoll.bar.notch"]),
            dockNotch: Boolean(v["atoll.dock.notch"]),
            dockPosition: String(v["atoll.dock.position"] ?? "auto"),
            layout: String(v["atoll.bar.layout"]),
            clearStrip: String(v["atoll.bar.strip"] ?? "clear") === "clear",
            clockAccent: String(v["atoll.bar.clockAccent"])
        }
    }

    readonly property string a: "atoll.appearance."
    readonly property string t: "atoll.appearance.theme."
    function values(pairs: var): var {
        const out = {}
        for (const key of Object.keys(pairs)) {
            const path = key.startsWith("atoll.") ? key : key.startsWith("theme.") ? root.a + key : key.startsWith("glass.") || key.startsWith("surfaces.") ? root.a + key : key
            out[path] = pairs[key]
        }
        return out
    }
    readonly property var curated: [
        { id: "atoll", name: "Atoll", author: "Lunana", tags: ["dark", "direct"],
            values: ({}) },
        { id: "liquid-glass", name: "Liquid Glass", author: "Lunana", tags: ["glass", "round", "springy"],
            values: root.values({ "atoll.lock.material": "glass", "atoll.lock.type.clockWeight": 300, "atoll.lock.type.clockTracking": -2, "atoll.lock.type.accent": "plain", "atoll.controlCenter.accent": "accent", "atoll.controlCenter.sliders": "neutral", "glass.mode": "wallpaper", "glass.tint": 42, "glass.blur": 100, "theme.rim": false, "atoll.appearance.preset": "round",
                "theme.shape": 115, "theme.melt": 55, "theme.lines": 0, "theme.shadow": 110, "theme.glow": 20, "atoll.appearance.aura": "vivid",
                "theme.lightReach": 170, "atoll.appearance.accent": "wallpaper", "atoll.appearance.highlight": "wallpaper",
                "atoll.appearance.fontFamily": "Roboto Flex", "atoll.appearance.numbersFontFamily": "Roboto Flex", "atoll.appearance.figureWeight": "light",
                "atoll.appearance.morph": "liquid", "theme.bounce": 120, "atoll.bar.notch": true, "atoll.bar.height": 44, "atoll.bar.satelliteGap": 8,
                "atoll.bubbles.scale": 108, "atoll.surround.thickness": 8, "atoll.surround.radius": 30, "atoll.palette.opens": "island",
                "atoll.controlCenter.controls": "round", "atoll.widgets.material": "glass", "atoll.widgets.radius": 30, "atoll.widgets.weight": "light",
                "atoll.dock.material": "inherit", "atoll.dock.magnification": false, "atoll.dock.iconSize": 44 }) },
        { id: "frost", name: "Frost", author: "Lunana", tags: ["glass", "bar", "calm"],
            values: root.values({ "atoll.lock.material": "glass", "atoll.lock.type.clockWeight": 300, "atoll.lock.type.clockTracking": -1, "atoll.lock.type.accent": "accent", "atoll.controlCenter.accent": "accent", "atoll.controlCenter.sliders": "accent", "glass.mode": "wallpaper", "glass.tint": 56, "glass.blur": 100, "theme.surface": "graphite", "theme.rim": false,
                "atoll.appearance.preset": "soft", "theme.lines": 35, "theme.shadow": 80, "theme.melt": 15, "atoll.appearance.accent": "custom",
                "theme.accentHue": 196, "atoll.appearance.highlight": "custom", "theme.highlightHue": 188, "atoll.appearance.aura": "subtle",
                "atoll.appearance.morph": "glide", "theme.curve": "gentle", "theme.openTime": 115, "atoll.appearance.figureWeight": "light",
                "atoll.appearance.fontFamily": "Roboto Flex", "atoll.appearance.numbersFontFamily": "Roboto Flex", "atoll.appearance.titleFontFamily": "Roboto Flex",
                "atoll.bar.layout": "full", "atoll.bar.notch": true, "atoll.bar.height": 38, "atoll.bar.composition": "unified", "atoll.bar.clockStyle": "time",
                "atoll.bar.clockAccent": "accent", "atoll.surround.enable": false, "atoll.widgets.material": "glass", "atoll.widgets.radius": 18,
                "atoll.widgets.weight": "light", "atoll.dock.notch": false, "atoll.dock.iconSize": 38, "atoll.dock.magnification": false,
                "atoll.controlCenter.controls": "round" }) },
        { id: "obsidian", name: "Obsidian", author: "Lunana", tags: ["sharp", "technical"],
            values: root.values({ "atoll.lock.material": "tint", "atoll.lock.type.clockWeight": 600, "atoll.lock.type.clockTracking": -4, "atoll.lock.type.accent": "plain", "atoll.controlCenter.accent": "accent", "atoll.controlCenter.sliders": "neutral", "atoll.appearance.preset": "angular", "theme.shape": 70, "theme.pieceShape": "squircle", "theme.surface": "black",
                "theme.lines": 130, "theme.rim": false, "theme.shadow": 150, "theme.fill": 115, "atoll.dock.notch": false,
                "atoll.appearance.aura": "off", "atoll.appearance.accent": "lilac", "atoll.appearance.highlight": "accent",
                "theme.badge": "accent", "atoll.appearance.morph": "snap", "theme.curve": "swift", "theme.openTime": 80, "theme.press": 60,
                "atoll.appearance.fontFamily": "Space Grotesk", "atoll.appearance.titleFontFamily": "Space Grotesk", "atoll.appearance.numbersFontFamily": "Space Grotesk",
                "atoll.appearance.figureWeight": "regular", "atoll.surround.thickness": 14, "atoll.surround.radius": 8, "atoll.bar.layout": "left",
                "atoll.bar.margin": 12, "atoll.bar.notchCurve": 55, "atoll.bar.clockAccent": "plain", "atoll.bar.clockStyle": "time", "atoll.bar.blockStyle": "grouped",
                "atoll.controlCenter.controls": "tiles", "atoll.widgets.material": "solid", "atoll.widgets.radius": 6, "atoll.widgets.weight": "regular",
                "atoll.dock.material": "solid", "atoll.dock.iconSize": 40 , "atoll.appearance.expandedRadius": 16}) },
        { id: "aurora", name: "Aurora", author: "Lunana", tags: ["wallpaper", "vivid", "soft"],
            values: root.values({ "atoll.lock.material": "glass", "atoll.lock.type.clockWeight": 200, "atoll.lock.type.clockTracking": -2, "atoll.lock.type.accent": "accent", "atoll.controlCenter.accent": "colourful", "atoll.controlCenter.sliders": "accent", "theme.surface": "wallpaper", "theme.rim": false, "glass.mode": "wallpaper", "glass.tint": 44, "atoll.appearance.tint": 60,
                "atoll.appearance.aura": "vivid", "theme.lightReach": 260, "theme.glow": 20, "atoll.appearance.accent": "wallpaper",
                "atoll.appearance.highlight": "wallpaper", "atoll.appearance.preset": "soft", "theme.shape": 125, "theme.melt": 60, "theme.lines": 0,
                "atoll.appearance.morph": "glide", "theme.curve": "gentle", "theme.openTime": 130, "atoll.appearance.titleFontFamily": "Gabarito",
                "atoll.appearance.figureWeight": "light", "atoll.bar.clockScale": 118, "atoll.bar.height": 46, "atoll.bar.desktopBanner": "wallpaper",
                "atoll.surround.thickness": 12, "atoll.surround.radius": 34, "atoll.widgets.material": "clear", "atoll.widgets.weight": "light",
                "atoll.widgets.radius": 34, "atoll.dock.magnification": false, "atoll.palette.opens": "island" }) },
        { id: "terminal", name: "Terminal", author: "Lunana", tags: ["mono", "brutalist", "bar"],
            values: root.values({ "atoll.lock.material": "none", "atoll.lock.type.clockWeight": 400, "atoll.lock.type.clockTracking": 0, "atoll.lock.type.accent": "accent", "atoll.controlCenter.accent": "accent", "atoll.controlCenter.sliders": "accent", "atoll.appearance.fontFamily": "JetBrainsMono Nerd Font", "atoll.appearance.titleFontFamily": "JetBrainsMono Nerd Font",
                "atoll.appearance.numbersFontFamily": "JetBrainsMono Nerd Font", "atoll.appearance.figureWeight": "regular",
                "atoll.appearance.preset": "angular", "theme.shape": 35, "theme.pieceShape": "square", "theme.lines": 200,
                "theme.fill": 70, "theme.shadow": 0, "theme.rim": false, "atoll.bubbles.join": "weld", "atoll.appearance.aura": "off",
                "atoll.appearance.accent": "custom", "theme.accentHue": 135, "atoll.appearance.highlight": "green", "theme.badge": "highlight",
                "atoll.appearance.morph": "snap", "theme.bounce": 0, "theme.curve": "standard", "theme.openTime": 65,
                "theme.moveTime": 70, "theme.press": 30, "theme.text": 95, "theme.contrast": 125,
                "atoll.bar.layout": "full", "atoll.bar.notch": false, "atoll.bar.composition": "unified", "atoll.bar.clockStyle": "time",
                "atoll.bar.clockAccent": "accent", "atoll.bar.height": 34, "atoll.surround.thickness": 4, "atoll.surround.radius": 0,
                "atoll.widgets.material": "solid", "atoll.widgets.weight": "regular", "atoll.widgets.radius": 0, "atoll.dock.material": "solid",
                "atoll.dock.notch": false, "atoll.dock.iconSize": 34, "atoll.controlCenter.controls": "tiles", "atoll.palette.opens": "floating",
                "atoll.wallpaper.layout": "wall" , "atoll.appearance.expandedRadius": 16}) },
        { id: "neo-tokyo", name: "Neo Tokyo", author: "Lunana", tags: ["anime", "neon", "glass", "sci-fi"],
            values: root.values({ "atoll.lock.material": "glass", "atoll.lock.type.clockWeight": 600, "atoll.lock.type.clockTracking": -1, "atoll.lock.type.accent": "accent", "atoll.controlCenter.accent": "colourful", "atoll.controlCenter.sliders": "accent", "theme.surface": "midnight", "glass.mode": "wallpaper", "glass.tint": 58, "atoll.appearance.preset": "crisp",
                "theme.shape": 90, "theme.pieceShape": "squircle", "theme.lines": 120, "theme.shadow": 160, "theme.glow": 55,
                "atoll.appearance.accent": "custom", "theme.accentHue": 186, "atoll.appearance.highlight": "custom", "theme.highlightHue": 312,
                "atoll.appearance.aura": "vivid", "theme.lightReach": 210, "theme.badge": "highlight", "atoll.appearance.titleFontFamily": "Oxanium",
                "atoll.appearance.numbersFontFamily": "Oxanium", "atoll.appearance.morph": "elastic", "theme.bounce": 80, "atoll.bar.clockScale": 110,
                "atoll.appearance.glass.edgeColour": "accent", "atoll.appearance.glass.edgeLight": 70, "atoll.appearance.glass.edgeLine": 22, "atoll.surround.thickness": 12, "atoll.surround.radius": 16,
                "atoll.widgets.material": "tinted", "atoll.widgets.radius": 14, "atoll.widgets.weight": "bold", "theme.rim": false,
                "atoll.dock.notch": false, "atoll.dock.material": "glass", "atoll.dock.magnification": false }) },
        { id: "afterglow", name: "Afterglow", author: "Lunana", tags: ["retro", "amber", "chrome", "bloom", "crt"],
            values: root.values({ "atoll.appearance.texture": "afterglow", "atoll.appearance.afterglow.grade": "dusk", "atoll.appearance.afterglow.atmosphere": 75,
                "atoll.appearance.afterglow.chrome": 70, "atoll.appearance.afterglow.bloom": 60, "atoll.appearance.afterglow.signal": 40, "atoll.appearance.afterglow.wallpaper": true,
                "atoll.lock.material": "tint", "atoll.lock.type.clockWeight": 700, "atoll.lock.type.clockTracking": -1, "atoll.lock.type.accent": "accent",
                "atoll.controlCenter.accent": "accent", "atoll.controlCenter.sliders": "accent", "theme.surface": "black", "glass.mode": "off",
                "atoll.appearance.preset": "crisp", "theme.shape": 85, "theme.pieceShape": "squircle", "theme.lines": 60, "theme.glow": 40, "theme.shadow": 120,
                "atoll.appearance.accent": "custom", "theme.accentHue": 32, "atoll.appearance.highlight": "custom", "theme.highlightHue": 170, "theme.badge": "highlight",
                "atoll.appearance.aura": "vivid", "theme.lightReach": 190, "atoll.appearance.titleFontFamily": "Oxanium", "atoll.appearance.numbersFontFamily": "Oxanium",
                "atoll.appearance.figureWeight": "bold", "atoll.appearance.morph": "snap", "theme.openTime": 90, "atoll.bar.clockAccent": "accent", "atoll.bar.clockScale": 110,
                "atoll.surround.thickness": 10, "atoll.surround.radius": 18, "atoll.widgets.material": "tinted", "atoll.widgets.radius": 14, "atoll.widgets.weight": "bold",
                "atoll.dock.material": "inherit", "atoll.dock.magnification": false, "atoll.controlCenter.controls": "tiles" }) },
        { id: "y2k", name: "Y2K", author: "Lunana", tags: ["retro", "ice", "lime", "chrome", "glass"],
            values: root.values({ "atoll.appearance.texture": "afterglow", "atoll.appearance.afterglow.grade": "cyber", "atoll.appearance.afterglow.atmosphere": 65,
                "atoll.appearance.afterglow.chrome": 90, "atoll.appearance.afterglow.bloom": 55, "atoll.appearance.afterglow.signal": 25, "atoll.appearance.afterglow.wallpaper": true,
                "atoll.lock.material": "glass", "atoll.lock.type.clockWeight": 600, "atoll.lock.type.clockTracking": -1, "atoll.lock.type.accent": "highlight",
                "atoll.controlCenter.accent": "accent", "atoll.controlCenter.sliders": "accent", "theme.surface": "midnight", "glass.mode": "wallpaper", "glass.tint": 64,
                "atoll.appearance.preset": "round", "theme.shape": 120, "theme.pieceShape": "circle", "theme.lines": 40, "theme.glow": 50,
                "atoll.appearance.accent": "custom", "theme.accentHue": 198, "atoll.appearance.highlight": "custom", "theme.highlightHue": 86, "theme.badge": "highlight",
                "atoll.appearance.aura": "subtle", "theme.lightReach": 160, "atoll.appearance.titleFontFamily": "Oxanium", "atoll.appearance.numbersFontFamily": "Oxanium",
                "atoll.appearance.figureWeight": "regular", "atoll.appearance.morph": "liquid", "theme.bounce": 90, "atoll.bar.clockAccent": "highlight",
                "atoll.surround.thickness": 10, "atoll.surround.radius": 30, "atoll.widgets.material": "glass", "atoll.widgets.radius": 26, "atoll.widgets.weight": "regular",
                "atoll.dock.material": "inherit", "atoll.dock.magnification": false, "atoll.controlCenter.controls": "round" }) },
        { id: "twilight", name: "Twilight", author: "Lunana", tags: ["anime", "dusk", "glass", "menu bar"],
            values: root.values({ "atoll.lock.material": "glass", "atoll.lock.type.clockWeight": 300, "atoll.lock.type.clockTracking": -2, "atoll.lock.type.accent": "highlight", "atoll.controlCenter.accent": "accent", "atoll.controlCenter.sliders": "accent", "theme.surface": "midnight", "glass.mode": "wallpaper", "glass.tint": 52, "glass.blur": 100, "theme.rim": false,
                "atoll.appearance.preset": "soft", "theme.shape": 115, "theme.melt": 70, "theme.lines": 25, "theme.shadow": 110, "theme.glow": 35,
                "atoll.appearance.accent": "custom", "theme.accentHue": 24, "atoll.appearance.highlight": "custom", "theme.highlightHue": 262,
                "atoll.appearance.aura": "vivid", "theme.lightReach": 170, "atoll.appearance.morph": "glide", "theme.curve": "gentle", "theme.openTime": 115,
                "atoll.appearance.figureWeight": "light", "atoll.bar.layout": "menubar", "atoll.bar.strip": "clear", "atoll.bar.notch": true, "atoll.bar.height": 40,
                "atoll.bar.composition": "unified", "atoll.bar.clockAccent": "accent", "atoll.surround.enable": false,
                "atoll.widgets.material": "glass", "atoll.widgets.radius": 24, "atoll.widgets.weight": "light",
                "atoll.dock.notch": false, "atoll.dock.material": "glass", "atoll.dock.iconSize": 42, "atoll.dock.magnification": false,
                "atoll.controlCenter.controls": "round" }) },
        { id: "daybreak", name: "Daybreak", author: "Lunana", tags: ["glass", "calm", "menu bar"],
            values: root.values({ "atoll.lock.material": "glass", "atoll.lock.type.clockWeight": 300, "atoll.lock.type.clockTracking": -2, "atoll.lock.type.accent": "accent", "atoll.controlCenter.accent": "accent", "atoll.controlCenter.sliders": "accent", "theme.surface": "graphite", "glass.mode": "wallpaper", "glass.tint": 66, "glass.blur": 100, "theme.rim": false,
                "atoll.appearance.preset": "soft", "theme.lines": 20, "theme.shadow": 90, "theme.melt": 40, "atoll.appearance.accent": "custom",
                "theme.accentHue": 205, "atoll.appearance.highlight": "custom", "theme.highlightHue": 38, "atoll.appearance.aura": "subtle",
                "atoll.appearance.morph": "glide", "theme.curve": "gentle", "theme.openTime": 105, "atoll.appearance.figureWeight": "regular",
                "atoll.bar.layout": "menubar", "atoll.bar.strip": "clear", "atoll.bar.notch": true, "atoll.bar.height": 38, "atoll.bar.composition": "unified",
                "atoll.bar.clockStyle": "dateTime", "atoll.bar.clockAccent": "highlight", "atoll.surround.enable": false,
                "atoll.widgets.material": "glass", "atoll.widgets.radius": 22, "atoll.widgets.weight": "regular",
                "atoll.dock.notch": false, "atoll.dock.material": "glass", "atoll.dock.iconSize": 44, "atoll.dock.magnification": false,
                "atoll.controlCenter.controls": "round" }) },
        { id: "horizon", name: "Horizon", author: "Lunana", tags: ["dark", "bar", "direct"],
            values: root.values({ "atoll.lock.material": "tint", "atoll.lock.type.clockWeight": 600, "atoll.lock.type.clockTracking": -3, "atoll.lock.type.accent": "highlight", "atoll.controlCenter.accent": "system", "atoll.controlCenter.sliders": "neutral", "theme.surface": "black", "glass.mode": "off", "theme.rim": false,
                "atoll.appearance.preset": "atoll", "atoll.appearance.accent": "blue", "atoll.appearance.highlight": "orange", "theme.badge": "alert", "atoll.appearance.aura": "subtle",
                "atoll.bar.layout": "full", "atoll.bar.notch": true, "atoll.bar.height": 40, "atoll.bar.composition": "unified",
                "atoll.bar.clockStyle": "dateTime", "atoll.bar.clockAccent": "highlight", "atoll.surround.enable": true, "atoll.surround.thickness": 10,
                "atoll.surround.radius": 22, "atoll.widgets.material": "solid", "atoll.widgets.radius": 22, "atoll.widgets.weight": "regular",
                "atoll.dock.notch": true, "atoll.dock.material": "solid", "atoll.dock.iconSize": 44, "atoll.dock.magnification": false,
                "atoll.controlCenter.controls": "tiles" }) },
        { id: "monolith", name: "Monolith", author: "Lunana", tags: ["minimal", "quiet"],
            values: root.values({ "atoll.lock.material": "none", "atoll.lock.type.clockWeight": 200, "atoll.lock.type.clockTracking": -3, "atoll.lock.type.accent": "plain", "atoll.controlCenter.accent": "mono", "atoll.controlCenter.sliders": "neutral", "atoll.surround.enable": false, "theme.lines": 0, "theme.rim": false, "theme.fill": 70,
                "theme.shadow": 60, "atoll.appearance.aura": "off", "atoll.appearance.accent": "custom", "theme.accentHue": 220,
                "atoll.appearance.highlight": "accent", "theme.badge": "neutral", "atoll.bar.clockAccent": "plain",
                "atoll.bar.composition": "unified", "atoll.bar.clockStyle": "time", "atoll.appearance.figureWeight": "light",
                "atoll.appearance.titleFontFamily": "Roboto Flex", "atoll.appearance.numbersFontFamily": "Roboto Flex",
                "atoll.appearance.fontFamily": "Roboto Flex", "atoll.appearance.morph": "glide", "theme.openTime": 120,
                "atoll.bar.notch": true, "atoll.bar.height": 36, "atoll.bar.clockScale": 108, "atoll.bar.satelliteScale": 90,
                "atoll.dock.notch": true, "atoll.dock.iconSize": 36, "atoll.dock.magnification": false,
                "atoll.widgets.material": "clear", "atoll.widgets.weight": "light", "atoll.widgets.radius": 0 }) },
        { id: "sakura", name: "Sakura", author: "Lunana", tags: ["anime", "pink", "round", "playful"],
            values: root.values({ "atoll.lock.material": "glass", "atoll.lock.type.clockWeight": 300, "atoll.lock.type.clockTracking": -2, "atoll.lock.type.accent": "accent", "atoll.controlCenter.accent": "accent", "atoll.controlCenter.sliders": "accent", "theme.surface": "graphite", "theme.rim": false, "glass.mode": "wallpaper", "glass.tint": 60,
                "atoll.appearance.preset": "round", "theme.shape": 140, "theme.melt": 90, "theme.lines": 30, "theme.glow": 45,
                "atoll.appearance.accent": "custom", "theme.accentHue": 334, "atoll.appearance.highlight": "pink",
                "atoll.appearance.aura": "vivid", "theme.lightReach": 180, "atoll.appearance.morph": "liquid", "theme.bounce": 150,
                "atoll.appearance.titleFontFamily": "Gabarito", "atoll.bar.satelliteGap": 10, "atoll.bubbles.scale": 112, "atoll.bar.notch": true,
                "atoll.appearance.glass.edgeColour": "accent", "atoll.appearance.glass.edgeLight": 50, "atoll.appearance.glass.edgeLine": 14,
                "atoll.surround.thickness": 12, "atoll.surround.radius": 36, "atoll.widgets.material": "glass", "atoll.widgets.radius": 32,
                "atoll.dock.magnification": false, "atoll.dock.iconSize": 44, "atoll.controlCenter.controls": "round" }) },
        { id: "meadow", name: "Meadow", author: "Lunana", tags: ["warm", "soft", "organic"],
            values: root.values({ "atoll.lock.material": "glass", "atoll.lock.type.clockWeight": 400, "atoll.lock.type.clockTracking": -2, "atoll.lock.type.accent": "highlight", "atoll.controlCenter.accent": "colourful", "atoll.controlCenter.sliders": "accent", "theme.surface": "graphite", "theme.rim": false, "glass.mode": "wallpaper", "glass.tint": 58,
                "atoll.appearance.preset": "round", "theme.shape": 150, "theme.melt": 110, "atoll.appearance.accent": "mint",
                "atoll.appearance.highlight": "custom", "theme.highlightHue": 40, "theme.lines": 35, "theme.contrast": 95,
                "atoll.appearance.aura": "subtle", "atoll.appearance.morph": "liquid", "theme.bounce": 160, "theme.curve": "gentle",
                "atoll.appearance.titleFontFamily": "Gabarito", "atoll.appearance.fontFamily": "Rubik", "atoll.bubbles.scale": 115, "atoll.bar.padding": 115,
                "atoll.bar.clockStyle": "weather", "atoll.bar.height": 46, "atoll.surround.thickness": 12, "atoll.surround.radius": 32, "atoll.widgets.material": "tinted", "atoll.widgets.radius": 28,
                "atoll.widgets.tint": "system", "atoll.dock.iconSize": 46, "atoll.dock.magnification": false, "atoll.controlCenter.controls": "round" }) },
        { id: "unit-01", name: "Unit-01", author: "Lunana", tags: ["anime", "mecha", "hard", "violet"],
            values: root.values({ "atoll.lock.material": "tint", "atoll.lock.type.clockWeight": 700, "atoll.lock.type.clockTracking": -1, "atoll.lock.type.accent": "highlight", "atoll.controlCenter.accent": "accent", "atoll.controlCenter.sliders": "accent", "theme.surface": "midnight", "atoll.appearance.preset": "contrast", "theme.shape": 75,
                "theme.pieceShape": "squircle", "atoll.appearance.accent": "custom", "theme.accentHue": 275,
                "atoll.appearance.highlight": "custom", "theme.highlightHue": 95, "theme.badge": "highlight",
                "theme.lines": 170, "theme.shadow": 150, "theme.glow": 30, "atoll.appearance.titleFontFamily": "Oxanium",
                "atoll.appearance.numbersFontFamily": "JetBrainsMono Nerd Font", "atoll.appearance.morph": "snap",
                "theme.curve": "swift", "atoll.bar.clockAccent": "highlight", "atoll.bar.clockStyle": "time", "atoll.bar.height": 44,
                "atoll.bar.clockScale": 112, "atoll.surround.thickness": 18, "atoll.surround.radius": 6, "atoll.bar.notchCurve": 60,
                "atoll.widgets.material": "solid", "atoll.widgets.radius": 4, "atoll.widgets.weight": "bold", "atoll.dock.material": "solid",
                "atoll.dock.iconSize": 42, "atoll.controlCenter.controls": "tiles", "theme.rim": false,
                "atoll.dock.notch": false, "atoll.appearance.expandedRadius": 16 }) },
        { id: "magical-girl", name: "Magical Girl", author: "Lunana", tags: ["anime", "rose", "gold", "playful"],
            values: root.values({ "atoll.lock.material": "glass", "atoll.lock.type.clockWeight": 300, "atoll.lock.type.clockTracking": -2, "atoll.lock.type.accent": "accent", "atoll.controlCenter.accent": "colourful", "atoll.controlCenter.sliders": "accent", "theme.surface": "graphite", "theme.rim": false, "glass.mode": "wallpaper", "glass.tint": 58,
                "atoll.appearance.preset": "round", "theme.shape": 138, "theme.melt": 85, "theme.lines": 35, "theme.glow": 45,
                "atoll.appearance.accent": "custom", "theme.accentHue": 338, "atoll.appearance.highlight": "custom", "theme.highlightHue": 44,
                "atoll.appearance.anime.enabled": true, "atoll.appearance.anime.palette": "magical-girl", "atoll.appearance.anime.strength": 100, "atoll.appearance.anime.highlight": true,
                "atoll.appearance.aura": "vivid", "theme.lightReach": 185, "atoll.appearance.morph": "liquid", "theme.bounce": 145,
                "atoll.appearance.titleFontFamily": "Gabarito", "atoll.appearance.fontFamily": "Gabarito",
                "atoll.bubbles.scale": 112, "atoll.bar.notch": true, "atoll.bar.clockStyle": "dateTime", "atoll.bar.clockAccent": "highlight",
                "atoll.appearance.glass.edgeColour": "accent", "atoll.appearance.glass.edgeLight": 55, "atoll.appearance.glass.edgeLine": 16,
                "atoll.surround.thickness": 12, "atoll.surround.radius": 34, "atoll.widgets.material": "glass", "atoll.widgets.radius": 30,
                "atoll.dock.magnification": false, "atoll.dock.iconSize": 44, "atoll.controlCenter.controls": "round" }) },
        { id: "spirit-forest", name: "Spirit Forest", author: "Lunana", tags: ["anime", "green", "amber", "organic"],
            values: root.values({ "atoll.lock.material": "glass", "atoll.lock.type.clockWeight": 400, "atoll.lock.type.clockTracking": -2, "atoll.lock.type.accent": "highlight", "atoll.controlCenter.accent": "colourful", "atoll.controlCenter.sliders": "accent", "theme.surface": "graphite", "theme.rim": false, "glass.mode": "wallpaper", "glass.tint": 56,
                "atoll.appearance.preset": "round", "theme.shape": 145, "theme.melt": 105, "theme.lines": 30, "theme.glow": 30,
                "atoll.appearance.accent": "mint", "atoll.appearance.highlight": "custom", "theme.highlightHue": 40,
                "atoll.appearance.anime.enabled": true, "atoll.appearance.anime.palette": "spirit-forest", "atoll.appearance.anime.strength": 100, "atoll.appearance.anime.highlight": true,
                "atoll.appearance.aura": "subtle", "atoll.appearance.morph": "glide", "theme.curve": "gentle", "theme.openTime": 120,
                "atoll.appearance.titleFontFamily": "Space Grotesk", "atoll.appearance.fontFamily": "Rubik",
                "atoll.bubbles.scale": 114, "atoll.bar.padding": 112, "atoll.bar.clockStyle": "weather", "atoll.bar.clockAccent": "highlight",
                "atoll.appearance.glass.edgeColour": "highlight", "atoll.appearance.glass.edgeLight": 50, "atoll.appearance.glass.edgeLine": 14,
                "atoll.bar.height": 46, "atoll.surround.thickness": 12, "atoll.surround.radius": 32, "atoll.widgets.material": "tinted", "atoll.widgets.radius": 28,
                "atoll.widgets.tint": "system", "atoll.dock.iconSize": 46, "atoll.dock.magnification": false, "atoll.controlCenter.controls": "round" }) },
        { id: "signal", name: "Signal", author: "Lunana", tags: ["contrast", "legible"],
            values: root.values({ "atoll.lock.material": "tint", "atoll.lock.type.clockWeight": 800, "atoll.lock.type.clockTracking": -2, "atoll.lock.type.accent": "accent", "atoll.controlCenter.accent": "accent", "atoll.controlCenter.sliders": "accent", "atoll.appearance.preset": "contrast", "theme.fill": 130, "theme.text": 110, "theme.lines": 160,
                "theme.contrast": 130, "atoll.appearance.aura": "off", "atoll.appearance.highlight": "yellow",
                "atoll.appearance.accent": "custom", "theme.accentHue": 52, "atoll.appearance.figureWeight": "bold",
                "theme.openTime": 80, "atoll.bar.height": 50, "atoll.bar.clockScale": 122, "atoll.dock.iconSize": 50,
                "atoll.dock.magnification": false, "atoll.widgets.material": "solid", "atoll.widgets.weight": "bold", "atoll.widgets.radius": 16,
                "atoll.widgets.tint": "system" }) },
        { id: "lunana", name: "Lunana Theme", author: "Lunana", tags: ["system"],
            values: root.values({ "theme.surface": "theme", "atoll.appearance.accent": "theme", "atoll.appearance.highlight": "theme",
                "atoll.widgets.design": "material", "atoll.widgets.tint": "system", "atoll.controlCenter.controls": "tiles" }) },
        { id: "lume", name: "Lume", author: "Lunana", tags: ["wallpaper", "clear", "instrument", "menu bar"],
            values: root.values({ "atoll.lock.material": "glass", "atoll.lock.type.clockWeight": 300, "atoll.lock.type.clockTracking": -2, "atoll.lock.type.accent": "accent", "atoll.controlCenter.accent": "accent", "atoll.controlCenter.sliders": "accent",
                "atoll.appearance.adaptive": 60, "theme.surface": "wallpaper", "atoll.appearance.accent": "wallpaper", "atoll.appearance.highlight": "wallpaper",
                "atoll.appearance.aura": "subtle", "atoll.appearance.tint": 20, "theme.rim": false, "theme.lines": 20, "glass.mode": "wallpaper", "glass.tint": 40, "glass.blur": 100,
                "atoll.appearance.preset": "soft", "atoll.appearance.morph": "glide", "theme.curve": "gentle", "atoll.appearance.figureWeight": "light",
                "atoll.bar.layout": "menubar", "atoll.bar.strip": "clear", "atoll.bar.notch": true, "atoll.bar.height": 38, "atoll.bar.composition": "unified",
                "atoll.bar.clockStyle": "dateTime", "atoll.bar.clockAccent": "accent", "atoll.surround.enable": false,
                "atoll.widgets.design": "instrument", "atoll.widgets.tint": "wallpaper", "atoll.widgets.material": "clear", "atoll.widgets.weight": "light",
                "atoll.dock.notch": false, "atoll.dock.material": "glass", "atoll.dock.magnification": false, "atoll.controlCenter.controls": "round" }) },
        { id: "adaptive", name: "Adaptive", author: "Lunana", tags: ["wallpaper", "automatic"],
            values: root.values({ "atoll.lock.material": "glass", "atoll.lock.type.clockWeight": 400, "atoll.lock.type.clockTracking": -2, "atoll.lock.type.accent": "plain", "atoll.controlCenter.accent": "system", "atoll.controlCenter.sliders": "neutral", "atoll.appearance.adaptive": 80, "theme.surface": "wallpaper", "atoll.appearance.accent": "wallpaper",
                "atoll.appearance.highlight": "wallpaper", "atoll.appearance.aura": "subtle", "atoll.appearance.tint": 25,
                "theme.rim": false, "glass.mode": "wallpaper", "glass.tint": 52, "atoll.surround.thickness": 10, "atoll.surround.radius": 28,
                "atoll.widgets.material": "clear", "atoll.widgets.weight": "regular" }) }
    ]
}
