pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.SystemTray
import Quickshell.Wayland
import "../../.."
import "../../../services"
import "../../../services/deferred"
import "../../common"
import "../../settings"
import "../background"
import "../control"
import "../field"
import "../frame"
import "../stage"
import "../lock"
import "../widgets"
import "../dock"
import "../edit"
import "../notificationPopup"
import "../palette"
import "../orbit"
import "../wallpaper"
import "../style"
import "../components" as AtollParts
import "../pieces"
import "../settings"

Scope {
    id: root

    readonly property var options: Config.options?.atoll?.bar ?? ({})
    readonly property string edge: AtollFrame.islandEdge
    readonly property int barHeight: Math.max(32, Math.round(Number(root.options?.height ?? 42) * AtollStyle.density))
    readonly property int restMargin: Math.max(0, Math.round(Number(root.options?.margin ?? 8) * AtollStyle.density))
    readonly property int outerMargin: (root.options?.notch ?? false) ? 0 : root.restMargin
    signal islandRequested(bool expanded, string page)
    signal pieceTapRequested(string kind)
    property bool pieceTapped: false
    property string editScreen: ""
    // The update overlay is Material's; under Atoll its details live in the New Lunana card.
    Connections {
        target: ShellUpdates
        function onOverlayOpenChanged(): void {
            if (!ShellUpdates.overlayOpen) return
            ShellUpdates.closeOverlay()
            if (!ShellUpdates.hasUpdate && !ShellUpdates.isUpdating) {
                const page = SettingsPageRegistry.pages.findIndex(entry => entry.key === "about")
                if (page >= 0) GlobalStates.openSettingsPage(page, "")
                return
            }
            GlobalStates.atollBubbleCardRequest = ""
            GlobalStates.atollBubbleCardRequest = "shellUpdate"
        }
    }
    Connections {
        target: GlobalStates
        function onIrisEditChanged(): void {
            if (GlobalStates.atollEdit) root.editScreen = GlobalStates.focusedScreen?.name ?? ""
        }
    }

    IpcHandler {
        target: "atoll"
        function open(): void { GlobalStates.barOpen = true; root.islandRequested(true, "") }
        function page(name: string): void {
            if (!["media", "activity", "desktop", "tray", "tools", "next", "prev"].includes(name)) return
            GlobalStates.barOpen = true
            root.islandRequested(true, name)
        }
        function close(): void { root.islandRequested(false, "") }
        function toggle(): void {
            if (GlobalStates.atollIslandExpanded) root.islandRequested(false, "")
            else { GlobalStates.barOpen = true; root.islandRequested(true, "") }
        }
        function card(action: string): void {
            if (action === "pin") {
                Config.setNestedValue("atoll.player.cardPinned", !(Config.options?.atoll?.player?.cardPinned ?? false))
                return
            }
            const open = GlobalStates.atollBubbleCard?.kind === "media"
            if (action === "close" || (open && action !== "open")) { GlobalStates.atollBubbleCard = null; return }
            if (open) return
            GlobalStates.atollBubbleCardRequest = ""
            GlobalStates.atollBubbleCardRequest = "media"
        }
        function theme(action: string): string {
            const verb = String(action).split(":")[0]
            const arg = String(action).slice(verb.length + 1)
            switch (verb) {
            case "list":
                return AtollThemes.all.map(entry => `${entry.id}\t${entry.name}${entry.id === AtollThemes.activeId ? (AtollThemes.modified ? "  (active, changed)" : "  (active)") : ""}`).join("\n")
            case "apply": {
                const found = AtollThemes.find(arg)
                if (!found) return "Unknown theme: see `lunana atoll theme list`"
                AtollThemes.apply(found)
                return found.name
            }
            case "colours": {
                const found = AtollThemes.find(arg)
                if (!found) return "Unknown theme: see `lunana atoll theme list`"
                AtollThemes.applyColours(found)
                return found.name
            }
            case "save":
                return AtollThemes.save(arg, "")
            case "import":
                if (arg.length === 0) return "import:<path to a theme .json>"
                AtollThemes.importFile(arg)
                return "Importing into " + AtollThemes.folder
            case "export": {
                const found = arg.length > 0 ? AtollThemes.find(arg)
                    : { id: AtollThemes.activeId, name: AtollThemes.active?.name ?? "My theme", values: AtollThemes.differences(AtollThemes.current()) }
                return found ? AtollThemes.exportText(found) : "Unknown theme"
            }
            case "folder":
                return AtollThemes.folder
            default:
                return "list | apply:<id> | colours:<id> | save:<name> | import:<path> | export[:<id>] | folder"
            }
        }
        function settings(section: string): void {
            const page = SettingsPageRegistry.pages.findIndex(entry => entry.key === "atoll")
            if (page >= 0) GlobalStates.openSettingsPage(page, section)
            else GlobalStates.openSettings()
        }
        function bubble(slot: string, place: string): string {
            const extra = AtollPieces.extraIds.includes(slot)
            if (!extra && !AtollPieces.slotIds.includes(slot)) return "Unknown bubble"
            const zones = AtollPieces.zones
            const path = AtollPieces.configPath(slot)
            const updates = {}
            if ((extra && place === "off") || (!extra && place === "island")) {
                updates[path + (extra ? ".enable" : ".place")] = extra ? false : "island"
            } else if (zones.includes(place)) {
                updates[path + ".place"] = place
            } else if (/^edge:(top|bottom|left|right)(:\d*\.?\d+)?$/.test(place)) {
                const parts = place.split(":")
                updates[path + ".place"] = "edge:" + parts[1]
                const along = Math.min(1, Number(parts[2] ?? 0.5))
                updates[path + (parts[1] === "top" || parts[1] === "bottom" ? ".fx" : ".fy")] = along
            } else {
                const m = String(place).match(/^(\d*\.?\d+),(\d*\.?\d+)$/)
                if (!m) return "Unknown place: a zone, x,y fractions, or island/off"
                updates[path + ".fx"] = Math.min(1, Number(m[1]))
                updates[path + ".fy"] = Math.min(1, Number(m[2]))
                updates[path + ".place"] = "free"
            }
            if (extra && place !== "off") updates[path + ".enable"] = true
            Config.setNestedValues(updates)
            return place
        }
        function dock(action: string): void {
            GlobalStates.atollDockShown = action === "reveal" ? true : action === "hide" ? false : !GlobalStates.atollDockShown
        }
        function dockApp(appId: string, mode: string): string {
            if (mode === "close") { GlobalStates.atollDockMenuRequest = { appId: "", mode: "close" }; GlobalStates.atollDockShown = false; return "closed" }
            if (mode === "pin") {
                TaskbarApps.togglePin(appId)
                const lower = appId.toLowerCase()
                return (Config.options?.dock?.pinnedApps ?? []).some(p => String(p).toLowerCase() === lower) ? "pinned" : "unpinned"
            }
            if (mode !== "windows" && mode !== "menu") return "Unknown mode: windows, menu, pin or close"
            GlobalStates.atollDockMenuRequest = { appId: appId, mode: mode }
            return appId
        }
        // `position` counts the Dock's icons from 1, the separator included: landing before it pins, after it unpins.
        function dockMove(appId: string, position: int): string {
            const ids = AtollDockOrder.entries.map(entry => entry.appId)
            const id = appId.toLowerCase()
            if (!ids.includes(id)) return "Not in the Dock: " + ids.filter(i => i !== "SEPARATOR").join(", ")
            const rest = ids.filter(i => i !== id)
            rest.splice(Math.max(0, Math.min(rest.length, position - 1)), 0, id)
            if (!AtollDockOrder.drop(id, rest)) return "Stays where it was: a pinned app with no window has no place among the open ones"
            return rest.join(" ")
        }
        function appBubble(appId: string, place: string): string {
            if (appId.length === 0) return "Unknown app"
            if (place === "dock" || place === "off") { AtollPieces.removeApp(appId); return "docked" }
            if (AtollPieces.zones.includes(place)) { AtollPieces.placeApp(appId, place, 0.5, 0.5); return place }
            const m = String(place).match(/^(\d*\.?\d+),(\d*\.?\d+)$/)
            if (!m) return "Unknown place: a zone, x,y fractions, or dock"
            AtollPieces.placeApp(appId, "free", Math.min(1, Number(m[1])), Math.min(1, Number(m[2])))
            return place
        }
        // The side panels and the Control Center by their Atoll names (the same paths as sidebarLeft,
        // sidebarRight and controlPanel), for keybinds that read as what they open.
        function focus(action: string): string {
            if (action === "open") GlobalStates.openSidebarLeft("")
            else if (action === "close") GlobalStates.closeSidebarLeft()
            else if (action === "toggle" || action === "") GlobalStates.toggleSidebarLeft("")
            else return "Choose open, close or toggle"
            return GlobalStates.sidebarLeftOpen ? "open" : "closed"
        }
        function today(action: string): string {
            if (action === "open") GlobalStates.openSidebarRight("")
            else if (action === "close") GlobalStates.closeSidebarRight()
            else if (action === "toggle" || action === "") GlobalStates.toggleSidebarRight("")
            else return "Choose open, close or toggle"
            return GlobalStates.sidebarRightOpen ? "open" : "closed"
        }
        function controlCenter(action: string): string {
            if (action === "open") GlobalStates.controlPanelOpen = true
            else if (action === "close") GlobalStates.controlPanelOpen = false
            else if (action === "toggle" || action === "") GlobalStates.controlPanelOpen = !GlobalStates.controlPanelOpen
            else return "Choose open, close or toggle"
            return GlobalStates.controlPanelOpen ? "open" : "closed"
        }
        function pin(side: string): void {
            if (side !== "left" && side !== "right") return
            const path = "atoll.sidebars." + side + ".pinned"
            Config.setNestedValue(path, !(Config.getNestedValue(path, false)))
        }
        function layout(name: string): string {
            if (!["island", "left", "right", "full", "menubar"].includes(name)) return "Unknown layout: island, left, right, full or menubar"
            Config.setNestedValue("atoll.bar.layout", name)
            return name
        }
        function strip(name: string): string {
            const value = name === "transparent" ? "clear" : name
            if (!["clear", "band"].includes(value)) return "Unknown strip: transparent or band"
            Config.setNestedValue("atoll.bar.strip", value)
            return value === "clear" ? "transparent" : "band"
        }
        function edge(name: string): string {
            if (!AtollFrame.edges.includes(name)) return "Unknown edge: top, bottom, left or right"
            Config.setNestedValue("atoll.bar.position", name)
            return name
        }
        function dockEdge(name: string): string {
            if (name !== "auto" && !AtollFrame.edges.includes(name)) return "Unknown edge: auto, top, bottom, left or right"
            Config.setNestedValue("atoll.dock.position", name)
            return AtollFrame.dockEdge
        }
        function zone(name: string, kinds: string): string {
            const path = ({ start: "atoll.bar.fullStart", center: "atoll.bar.fullCenter", end: "atoll.bar.fullEnd" })[name]
            if (!path) return "Unknown zone: start, center or end"
            const list = String(kinds).split(/[+\s]+/).filter(kind => kind.length > 0 && kind !== "none")
            Config.setNestedValue(path, list)
            return JSON.stringify(list)
        }
        function barPiece(kind: string, action: string): string {
            if (!AtollPieces.extraIds.includes(kind)) return "Unknown piece"
            const current = Array.from(Config.options?.atoll?.bar?.pieces ?? [])
            const on = current.includes(kind)
            const wanted = action === "on" ? true : action === "off" ? false : !on
            if (wanted === on) return on ? "on" : "off"
            const next = current.filter(entry => entry !== kind)
            if (wanted) next.push(kind)
            Config.setNestedValue("atoll.bar.pieces", next)
            return wanted ? "on" : "off"
        }
        function arrange(action: string): string {
            const wanted = action === "on" ? true : action === "off" ? false : !GlobalStates.atollArrange
            if (wanted) GlobalStates.atollIslandPageRequest = "desktop"
            GlobalStates.atollArrange = wanted
            return wanted ? "on" : "off"
        }
        function edit(action: string): string {
            if (action.startsWith("tab:")) {
                const targets = { pieces: "pieces", look: "material", motion: "motion", layout: "island" }
                const target = targets[action.slice(4)]
                if (!target) return "Unknown tab"
                GlobalStates.atollEdit = true
                GlobalStates.atollEditTarget = target
                return action
            }
            if (!["on", "off", "toggle", ""].includes(action)) {
                GlobalStates.atollEdit = true
                if (AtollPieces.extraIds.includes(action)) GlobalStates.atollEditSelection = "extra:" + action
                else if (AtollPieces.slotIds.includes(action) || AtollPieces.isApp(action)) GlobalStates.atollEditSelection = action
                else GlobalStates.atollEditTarget = action
                return action
            }
            const wanted = action === "on" ? true : action === "off" ? false : !GlobalStates.atollEdit
            GlobalStates.atollEdit = wanted
            return wanted ? "on" : "off"
        }
        // `studio <area>` opens Studio on an area, `studio search:<words>` with a search typed.
        function studio(action: string): string {
            if (!["on", "off", "toggle"].includes(action)) {
                GlobalStates.atollStudioTarget = action
                GlobalStates.atollStudioOpen = true
                return action
            }
            const wanted = action === "on" ? true : action === "off" ? false : !GlobalStates.atollStudioOpen
            GlobalStates.atollStudioOpen = wanted
            return wanted ? "on" : "off"
        }
        function notch(action: string): string {
            const on = Config.options?.atoll?.bar?.notch ?? false
            const wanted = action === "on" ? true : action === "off" ? false : !on
            Config.setNestedValue("atoll.bar.notch", wanted)
            return wanted ? "on" : "off"
        }
        function surround(action: string): string {
            const on = Config.options?.atoll?.surround?.enable ?? false
            const wanted = action === "on" ? true : action === "off" ? false : !on
            Config.setNestedValue("atoll.surround.enable", wanted)
            return wanted ? "on" : "off"
        }
        function accent(name: string): string {
            if (!["blue", "mint", "rose", "lilac", "wallpaper"].includes(name)) return "Unknown accent"
            Config.setNestedValue("atoll.appearance.accent", name)
            return String(Config.options.atoll.appearance.accent)
        }
        function spotlight(query: string): void {
            GlobalStates.atollSpotlightQuery = query
            GlobalStates.searchOpen = true
        }
        function gallerySource(source: string, state: string): string {
            const known = ["wallhaven", "live", "konachan", "yandere"]
            if (!known.includes(source)) return "Unknown source: " + known.join(", ")
            const list = Array.from(Config.options?.atoll?.wallpaper?.sources ?? ["wallhaven", "live"]).map(String)
            const on = state === "on" || (state === "toggle" && !list.includes(source))
            if (state !== "on" && state !== "off" && state !== "toggle") return "on, off or toggle"
            const next = list.filter(id => id !== source).concat(on ? [source] : [])
            Config.setNestedValue("atoll.wallpaper.sources", next)
            return next.join(" ")
        }
        function orbit(query: string): string {
            if (!(Config.options?.atoll?.orbit?.enable ?? false)) return "Orbit is off: turn it on in Settings › Orbit or with lunana atoll set atoll.orbit.enable true"
            GlobalStates.atollOrbitQuery = query
            GlobalStates.atollOrbitOpen = true
            return "open"
        }
        function orbitCorner(): string { return JSON.stringify(GlobalStates.atollOrbitCorners) }
        function orbitClose(): string {
            GlobalStates.atollOrbitOpen = false
            return "closed"
        }
        function spotlightClose(): string {
            GlobalStates.searchOpen = false
            return "closed"
        }
        function bubbleCard(kind: string): string {
            if (kind === "close") { GlobalStates.atollBubbleCard = null; return "closed" }
            if (!AtollPieces.cardIds.includes(kind)) return "Unknown card"
            if (GlobalStates.atollBubbleCard?.kind === kind) return kind
            GlobalStates.atollBubbleCardRequest = ""
            GlobalStates.atollBubbleCardRequest = kind
            return kind
        }
        function tap(kind: string): string {
            if (kind.length === 0) return "Which piece?"
            root.pieceTapped = false
            root.pieceTapRequested(kind)
            return root.pieceTapped ? kind : kind + " is not a piece on the focused screen's bar"
        }
        function bubbleMenu(kind: string): string {
            if (kind.length === 0) return "Which bubble?"
            GlobalStates.atollBubbleMenuRequest = ""
            GlobalStates.atollBubbleMenuRequest = kind
            return kind
        }
        function morph(name: string): string {
            if (!Object.keys(AtollStyle.morphStyles).includes(name)) return "Unknown morph style"
            Config.setNestedValue("atoll.appearance.morph", name)
            return name
        }
        function activity(action: string, id: string, value: string): string {
            let result = null
            switch (action) {
            case "start": result = LiveActivities.start(id, value); break
            case "title": result = LiveActivities.setTitle(id, value); break
            case "progress": result = LiveActivities.setProgress(id, value); break
            case "detail": result = LiveActivities.setDetail(id, value); break
            case "glyph": result = LiveActivities.setGlyph(id, value); break
            case "tint": result = LiveActivities.setTint(id, value); break
            case "end": result = LiveActivities.end(id, value); break
            case "dismiss": LiveActivities.dismiss(id); return "dismissed"
            case "clear": LiveActivities.clear(); return "cleared"
            default: return "Unknown action: start, title, progress, detail, glyph, tint, end, dismiss, clear"
            }
            return result ? JSON.stringify(result) : "No activity " + id
        }
        function activities(): string {
            return JSON.stringify(LiveActivities.active)
        }
        function set(path: string, value: string): string {
            if (!path.startsWith("atoll.")) return "Only atoll.* options"
            let parsed = value
            try { parsed = JSON.parse(value) } catch (error) {}
            Config.setNestedValue(path, parsed)
            return JSON.stringify(Config.getNestedValue(path, null))
        }
        function adaptive(amount: string): string {
            const value = String(amount).trim().length > 0 ? Math.round(Number(amount)) : NaN
            if (isNaN(value)) return JSON.stringify({ strength: AtollMood.strength, luminance: AtollMood.luminance,
                contrast: AtollMood.contrast, colorfulness: AtollMood.colorfulness, colors: AtollMood.colors.length,
                sampled: AtollMood.sampled, glassTint: AtollStyle.glassTint, placeCovered: AtollStyle.placeCovered, placePlate: AtollStyle.placePlate })
            Config.setNestedValue("atoll.appearance.adaptive", Math.max(0, Math.min(100, value)))
            return String(Math.max(0, Math.min(100, value)))
        }
        function tokens(): string { return JSON.stringify(AtollStyle.audit()) }
        function palette(id: string): string {
            const known = AtollOptions.colourThemeIds
            if (id === "list") return JSON.stringify(known)
            if (id === "current") return String(ThemeService.currentTheme)
            if (!known.includes(id) && !ThemePresets.presets.some(preset => preset.id === id))
                return "Unknown colour theme. `list` names the ones Atoll shows; `auto` follows the wallpaper"
            ThemeService.setTheme(id)
            return String(ThemeService.currentTheme)
        }
        function preset(name: string): string {
            if (!Object.keys(AtollStyle.presets).includes(name)) return "Unknown preset"
            Config.setNestedValue("atoll.appearance.preset", name)
            return String(Config.options.atoll.appearance.preset)
        }
        function icon(piece: string, glyph: string): string {
            if (!AtollPieces.iconKinds.includes(piece))
                return "Unknown piece. One of: " + AtollPieces.iconKinds.join(", ")
            AtollPieces.setGlyph(piece, glyph === "reset" ? "" : glyph)
            const chosen = AtollPieces.chosenGlyph(piece)
            return chosen.length > 0 ? chosen : "default (" + AtollPieces.defaultGlyph(piece) + ")"
        }
        function control(action: string): string {
            if (AtollControlOptions.presets.some(preset => preset.id === action)) {
                AtollControlOptions.applyPreset(action)
                return action
            }
            if (action === "undo") return AtollControlOptions.undo() ? "undone" : "nothing to undo"
            if (action.startsWith("expand:")) {
                const list = action.slice(7)
                if (!["display", "system", "devices", "network", "bluetooth", "none"].includes(list))
                    return "Unknown expansion. One of: display, system, devices, network, bluetooth, none"
                if (!GlobalStates.controlPanelOpen) {
                    GlobalStates.atollMorphOwner = ""
                    GlobalStates.controlPanelOpen = true
                }
                GlobalStates.atollControlPickerRequest = ""
                GlobalStates.atollControlPickerRequest = list
                return list
            }
            const tab = action.startsWith("tab:") ? action.slice(4) : ""
            if (tab.length > 0 && !["controls", "layouts", "panel"].includes(tab))
                return "Unknown tab. One of: controls, layouts, panel"
            const wanted = tab.length > 0 || action === "edit" || action === "on" ? true
                : action === "off" || action === "done" ? false : !GlobalStates.atollControlEdit
            if (!wanted) {
                GlobalStates.atollControlEdit = false
                return "closed"
            }
            if (!GlobalStates.controlPanelOpen) {
                GlobalStates.atollMorphOwner = ""
                GlobalStates.controlPanelOpen = true
            }
            GlobalStates.atollControlEdit = true
            if (tab.length > 0) GlobalStates.atollControlTab = tab
            return tab.length > 0 ? tab : "arranging"
        }
        function lock(action: string): string {
            if (AtollLockOptions.presetOf(action)) {
                AtollLockOptions.applyPreset(action)
                return action
            }
            if (action.startsWith("widget:")) {
                const key = action.slice(7)
                if (!AtollFaceData.galleryEntries.some(entry => entry.key === key))
                    return "Unknown widget. One of: " + AtollFaceData.galleryEntries.map(entry => entry.key).join(", ")
                const screen = GlobalStates.focusedScreen?.name ?? ""
                AtollLockOptions.toggleWidget(screen, key)
                return AtollLockOptions.widgetShown(screen, key) ? key + " on the lock" : key + " off the lock"
            }
            if (action.startsWith("select:")) {
                const [key, tab] = action.slice(7).split("/")
                const screen = GlobalStates.focusedScreen?.name ?? ""
                if (!AtollLockOptions.widgetShown(screen, key)) return key + " is not on the lock; add it with widget:" + key
                if (tab && !["widget", "look", "arrange"].includes(tab)) return "Unknown tab. One of: widget, look, arrange"
                GlobalStates.atollLockEdit = true
                GlobalStates.atollLockSelection = "widget:" + key
                GlobalStates.atollLockWidgetTab = ""
                GlobalStates.atollLockWidgetTab = tab ?? ""
                return key + " selected" + (tab ? " on " + tab : "")
            }
            if (action.startsWith("page:")) {
                const page = AtollLockOptions.groups.find(group => group.toLowerCase() === action.slice(5).toLowerCase())
                if (!page) return "Unknown page. One of: " + AtollLockOptions.groups.join(", ")
                GlobalStates.atollLockPage = page
                GlobalStates.atollLockEdit = true
                return page
            }
            const wanted = action === "edit" || action === "on" ? true
                : action === "off" || action === "done" ? false : !GlobalStates.atollLockEdit
            GlobalStates.atollLockEdit = wanted
            return wanted ? "editing" : "closed"
        }
        function utility(name: string): string {
            if (!["tray", "tools", "sound", "mic", "none"].includes(name)) return "Unknown utility"
            Config.setNestedValue("atoll.bar.auxiliary", name)
            return String(Config.options.atoll.bar.auxiliary)
        }
        function watch(which: string): string {
            const shows = AnimeWatch.shows ?? []
            const query = String(which ?? "").trim()
            if (query.length === 0) {
                if (!AnimeWatch.available) return "No anime CLI found (install ani-cli, jerry or curd)"
                if (AnimeWatch.busy)
                    return AnimeWatch.busyEpisode.length > 0 ? `${AnimeWatch.phase}: episode ${AnimeWatch.busyEpisode}` : AnimeWatch.phase
                if (shows.length === 0) return AnimeWatch.error.length > 0 ? AnimeWatch.error : "Nothing watched yet"
                return (AnimeWatch.error.length > 0 ? `${AnimeWatch.error}\n` : "") + shows.map((show, index) => {
                    const start = AnimeWatch.targetStartOf(show)
                    const at = start > 0.5 ? `  ${AnimeWatch.clock(start)} in` : ""
                    return `${index + 1}\t${show.title}\tep ${AnimeWatch.targetEpisodeOf(show)}${at}`
                }).join("\n")
            }
            if (AnimeWatch.busy) return `Already ${AnimeWatch.phase}: episode ${AnimeWatch.busyEpisode}`
            if (!AnimeWatch.canTarget)
                return AnimeWatch.available ? `${AnimeWatch.cli} chooses what to resume` : "No anime CLI found"
            const index = Number(query)
            const chosen = isFinite(index) && index >= 1 && index <= shows.length
                ? shows[index - 1]
                : shows.find(show => String(show.title).toLowerCase().includes(query.toLowerCase()))
            if (!chosen) {
                AnimeWatch.search(query)
                return `Searching: ${query}`
            }
            AnimeWatch.resume(chosen)
            return `${chosen.title} · ep ${AnimeWatch.targetEpisodeOf(chosen)}`
        }
        function watchPick(value: string): string {
            const query = String(value ?? "").trim()
            if (query === "cancel") {
                if (!AnimeWatch.running) return "Nothing to cancel"
                AnimeWatch.cancel()
                return "Cancelled"
            }
            if (!AnimeWatch.choosing) return AnimeWatch.busy ? AnimeWatch.phase : "Nothing to choose"
            const items = AnimeWatch.pickItems
            if (query.length === 0)
                return items.map(item => `${AnimeWatch.pickValue(item)}\t${AnimeWatch.betweenEpisodes ? AnimeWatch.actionLabel(AnimeWatch.pickValue(item)) : AnimeWatch.pickLabel(item)}`).join("\n")
            const found = items.find(item => AnimeWatch.pickValue(item) === query)
                ?? items.find(item => (AnimeWatch.betweenEpisodes ? AnimeWatch.actionLabel(AnimeWatch.pickValue(item)) : AnimeWatch.pickLabel(item)).toLowerCase().includes(query.toLowerCase()))
            if (!found) return `No option matches: ${query}`
            AnimeWatch.choose(AnimeWatch.pickValue(found))
            return AnimeWatch.pickLabel(found)
        }
        function desktopAction(id: string): string {
            return AtollDesktopActions.run(id, NiriService.currentOutput || (Quickshell.screens[0]?.name ?? ""))
        }
        function desktopMenu(x: string, y: string): string {
            const output = NiriService.currentOutput
            const screen = Quickshell.screens.find(s => s.name === output) ?? Quickshell.screens[0]
            const px = x.length > 0 ? Number(x) : (screen?.width ?? 0) / 2
            const py = y.length > 0 ? Number(y) : (screen?.height ?? 0) / 2
            if (!isFinite(px) || !isFinite(py)) return "Give x and y in pixels of the focused output"
            GlobalStates.atollDesktopMenuRequested(screen?.name ?? "", px, py)
            return `${screen?.name ?? ""} ${Math.round(px)} ${Math.round(py)}`
        }
        function menuClose(): string {
            const menu = GlobalStates.activeContextMenu
            if (!menu) return "No menu open"
            menu.close ? menu.close() : (menu.active = false)
            return "closed"
        }
        function watchSubs(command: string): string {
            if (AnimeWatch.phase !== "playing") return "No episode playing"
            const c = String(command ?? "").trim()
            if (c === "size+" || c === "size-") AnimeWatch.setSubtitleScale(AnimeWatch.subtitleScale + (c === "size+" ? 10 : -10))
            else if (c === "delay+" || c === "delay-") AnimeWatch.nudgeSubtitleDelay(c === "delay+" ? 0.1 : -0.1)
            else if (c === "delay0") AnimeWatch.resetSubtitleDelay()
            else if (c === "off") AnimeWatch.selectSubtitle(0)
            else if (c.startsWith("track:")) AnimeWatch.selectSubtitle(Number(c.slice(6)) || 0)
            else if (c.startsWith("file:")) AnimeWatch.addSubtitle(c.slice(5))
            else if (c.length > 0) return "Use size+ size- delay+ delay- delay0 off track:<n> file:<path>"
            return `size ${AnimeWatch.subtitleScale} %, delay ${AnimeWatch.subtitleDelay.toFixed(1)} s, track ${AnimeWatch.subtitleId}\n`
                + AnimeWatch.subtitles.map((t, i) => `${t.id}\t${AnimeWatch.subtitleLabel(t, i)}`).join("\n")
        }
        function watchSeek(seconds: string): string {
            if (AnimeWatch.phase !== "playing") return "No episode playing"
            const value = Number(seconds)
            if (!isFinite(value) || value === 0) return "Seconds, e.g. 85 or -10"
            AnimeWatch.seekBy(value)
            return String(value)
        }
        function watchSkip(direction: string): string {
            const wanted = String(direction ?? "").trim() || "next"
            if (wanted !== "next" && wanted !== "previous") return "Use next or previous"
            if (AnimeWatch.phase !== "playing" && !AnimeWatch.betweenEpisodes) return "No episode playing"
            AnimeWatch.skip(wanted)
            return wanted
        }
        function motion(target: string): string { return AtollParts.AtollMotionMeter.start(target) }
        function motioned(): string { return JSON.stringify(AtollParts.AtollMotionMeter.result) }
        function status(): string {
            return JSON.stringify({
                islandExpanded: GlobalStates.atollIslandExpanded,
                islandShape: GlobalStates.atollIslandShape,
                islandPage: GlobalStates.atollIslandPage,
                accent: Config.options?.atoll?.appearance?.accent ?? "blue",
                preset: AtollStyle.presetName,
                bubbleCard: GlobalStates.atollBubbleCard?.kind ?? "",
                utility: Config.options?.atoll?.bar?.auxiliary ?? "tray",
                trayItems: SystemTray.items.values.length,
                dockShown: GlobalStates.atollDockShown,
                controlCenter: GlobalStates.controlPanelOpen,
                spotlight: GlobalStates.searchOpen,
                orbit: GlobalStates.atollOrbitOpen,
                focus: { open: GlobalStates.sidebarLeftOpen, pinned: Config.options?.atoll?.sidebars?.left?.pinned ?? false },
                today: { open: GlobalStates.sidebarRightOpen, pinned: Config.options?.atoll?.sidebars?.right?.pinned ?? false },
                // Modes that take the screen over until someone closes them.
                editing: { lock: GlobalStates.atollLockEdit, customize: GlobalStates.atollEdit, widgets: GlobalStates.widgetEditMode,
                    controlCenter: GlobalStates.atollControlEdit, island: GlobalStates.atollArrange },
                settings: GlobalStates.settingsOverlayOpen,
                gallery: GlobalStates.wallpaperLauncherOpen,
                media: MprisController.activePlayer ? {
                    player: MprisController.activePlayer.dbusName ?? "",
                    title: MprisController.titleOf(MprisController.activePlayer) ?? "",
                    playing: MprisController.activePlayer.isPlaying ?? false,
                    position: Math.round(MprisController.positionOf(MprisController.activePlayer) * 10) / 10,
                    length: Math.round(MprisController.lengthOf(MprisController.activePlayer) * 10) / 10,
                    players: MprisController.players.map(player => player.dbusName ?? "")
                } : null
            })
        }
    }

    function islandAllowed(screen: var): bool {
        const list = root.options?.screenList ?? []
        if (!list || list.length === 0) return true
        const matched = Quickshell.screens.filter(s => list.includes(s?.name ?? ""))
        return matched.length === 0 || list.includes(screen?.name ?? "")
    }

    Variants {
        model: Quickshell.screens

        delegate: LazyLoader {
            id: windowLoader
            required property var modelData
            property string loadedEdge: "top"
            readonly property bool loadedBottom: windowLoader.loadedEdge === "bottom"
            readonly property bool loadedVertical: windowLoader.loadedEdge === "left" || windowLoader.loadedEdge === "right"
            Component.onCompleted: windowLoader.loadedEdge = root.edge
            property bool recycling: false
            readonly property string requestedEdge: root.edge
            onRequestedEdgeChanged: windowLoader.recycle()
            // Rebuilt on shape changes: a ClippingRectangle does not re-mask when its corner structure changes.
            readonly property string shapeKey: String(Config.options?.atoll?.surround?.enable ?? false)
            onShapeKeyChanged: windowLoader.recycle()
            function recycle(): void {
                windowLoader.recycling = true
                Qt.callLater(() => {
                    windowLoader.loadedEdge = windowLoader.requestedEdge
                    windowLoader.recycling = false
                })
            }
            activeAsync: !windowLoader.recycling

            component: Scope {
            // Declared first so its strips map before the chassis and sit below it (AtollWaveBlur).
            AtollWaveBlur {
                id: waveBlur
                screen: windowLoader.modelData
                active: barWindow.frameBlurred && !barWindow.overlaid && AtollFrame.musicActive
                shapes: barWindow.blurShapes
                edgeWave: framePulse.amplitudes
                waveClock: framePulse.phase
                smoothing: chassisField.smoothing
            }
            PanelWindow {
                id: barWindow
                readonly property bool expanded: islandLoader.item?.expanded ?? false
                readonly property bool pinned: islandLoader.item?.pinned ?? false
                screen: windowLoader.modelData
                // After the wave strips, so Niri stacks the chassis above them (it keeps mapping order).
                visible: waveBlur.ready
                color: "transparent"
                exclusionMode: ExclusionMode.Ignore
                exclusiveZone: 0
                WlrLayershell.namespace: "quickshell:atoll-chassis"
                Component.onCompleted: AtollParts.AtollMotionMeter.registerChassis(barWindow.screen?.name ?? "", barWindow)
                Component.onDestruction: AtollParts.AtollMotionMeter.registerChassis(barWindow.screen?.name ?? "", null)
                readonly property bool editHere: GlobalStates.atollEdit
                    && (root.editScreen.length === 0 || barWindow.screen?.name === root.editScreen)
                readonly property bool presenting: barWindow.pinned || stage.cardPresent
                    || (controlCentreLoader.item?.present ?? false) || barWindow.editHere
                    || (dockLoader.item?.overFullscreen ?? false) || (dockLoader.item?.menuOpen ?? false)
                    || (spotlightLoader.item?.present ?? false) || (galleryLoader.item?.present ?? false)
                    || (orbitLoader.item?.present ?? false)
                // Niri keeps a fullscreen window above the Top layer, so the overview
                // over a game would show every other surface but this one.
                readonly property bool overviewOverFullscreen: CompositorService.isNiri && NiriService.inOverview
                    && GameMode.hasFullscreenOnOutput(barWindow.screen?.name ?? "")
                readonly property bool canvasSuppressed: barWindow.suppressed && !barWindow.presenting
                // Nothing of the chassis may cover, move or restack what sits still in it: continuous motion may
                // then draw in a surface of its own (LiveLayer) instead of repainting the whole output.
                readonly property bool liveCalm: !barWindow.presenting && !barWindow.expanded && !barWindow.overlaid
                    && !barWindow.canvasSuppressed && !AtollStyle.arriving && !(islandLoader.item?.morphing ?? false)
                    && (banners.fieldShapes ?? []).length === 0
                readonly property int liveLayer: WlrLayer.Top
                readonly property int liveEpoch: GlobalStates.atollChassisEpoch
                readonly property bool overlaid: ((islandLoader.item?.fullscreenCovered ?? false) && !barWindow.canvasSuppressed)
                    || barWindow.overviewOverFullscreen
                // Switching layers recreates the surface above the Dock's window, whose icons it would cover.
                onOverlaidChanged: if (!barWindow.overlaid) GlobalStates.atollChassisEpoch++
                WlrLayershell.layer: barWindow.overlaid ? WlrLayer.Overlay : WlrLayer.Top
                WlrLayershell.keyboardFocus: barWindow.pinned || stage.cardOpen || (controlCentreLoader.item?.morphOpen ?? false)
                    || (dockLoader.item?.menuOpen ?? false) || (spotlightLoader.item?.here && GlobalStates.searchOpen)
                    || (galleryLoader.item?.morphOpen ?? false) || (orbitLoader.item?.wanted ?? false) || (widgetBarLoader.item?.holdsKeyboard ?? false)
                    ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
                anchors { left: true; right: true; top: true; bottom: true }
                readonly property bool suppressed: islandLoader.active
                    ? (islandLoader.item?.suppressed ?? false) : false

                readonly property bool islandAutoHide: AtollFrame.islandAutoHide && islandLoader.active
                readonly property bool islandWorkspaceEmpty: {
                    if (!(root.options?.revealOnEmpty ?? true) || !CompositorService.isNiri) return false
                    const active = (NiriService.allWorkspaces ?? []).find(ws => ws.output === barWindow.screen?.name && ws.is_active)
                    return active !== undefined && !(NiriService.windows ?? []).some(w => w.workspace_id === active.id)
                }
                property bool islandEdgeIntent: false
                readonly property bool islandWants: barWindow.expanded || barWindow.pinned || barWindow.editHere
                    || (islandLoader.item?.feedback ?? false) || (islandLoader.item?.eventShown ?? false)
                    || (islandLoader.item?.morphing ?? false) || stage.cardPresent
                    || (controlCentreLoader.item?.present ?? false)
                readonly property bool islandRevealed: !barWindow.islandAutoHide
                    || barWindow.islandWorkspaceEmpty || barWindow.islandEdgeIntent || barWindow.islandWants
                // Off the edge the chassis is gone, but its fuse still reaches back onto
                // the screen and leaves a smudge where the Island used to melt in.
                readonly property bool islandTucked: islandLoader.tuck > islandLoader.hidden - 1
                readonly property bool pointerOnIslandBody: canvasHover.hovered
                    && [islandInput, menuStartInput, menuEndInput].some(area =>
                        canvasHover.point.position.x >= area.x && canvasHover.point.position.x < area.x + area.width
                        && canvasHover.point.position.y >= area.y && canvasHover.point.position.y < area.y + area.height)
                readonly property bool pointerNearIsland: islandEdgeHover.hovered || barWindow.pointerOnIslandBody
                onPointerNearIslandChanged: {
                    if (barWindow.pointerNearIsland) {
                        islandHideDelay.stop()
                        if (!barWindow.islandEdgeIntent) islandRevealDwell.restart()
                    } else {
                        islandRevealDwell.stop()
                        islandHideDelay.restart()
                    }
                }
                Timer { id: islandRevealDwell; interval: 110; onTriggered: barWindow.islandEdgeIntent = true }
                Timer { id: islandHideDelay; interval: 420
                    onTriggered: if (!barWindow.pointerNearIsland) barWindow.islandEdgeIntent = false }
                mask: barWindow.canvasSuppressed ? emptyRegion
                    : barWindow.pinned || stage.cardArmed || (controlCentreLoader.item?.armed ?? false)
                        || (dockLoader.item?.menuOpen ?? false) || (spotlightLoader.item?.armed ?? false)
                        || (galleryLoader.item?.armed ?? false) || (orbitLoader.item?.armed ?? false)
                        || (islandLoader.item?.morphing ?? false)
                        ? null : chassisRegion
                Region { id: emptyRegion }
                component PieceRegion: Region {
                    required property int index
                    readonly property var rect: stage.hitRects[index] ?? null
                    x: rect ? rect.x : 0
                    y: rect ? rect.y : 0
                    width: rect ? rect.width : 0
                    height: rect ? rect.height : 0
                }
                MouseArea {
                    anchors.fill: parent
                    enabled: dockLoader.item?.menuOpen ?? false
                    acceptedButtons: Qt.AllButtons
                    onPressed: dockLoader.item.closeMenu()
                }
                MouseArea {
                    anchors.fill: parent
                    enabled: barWindow.pinned
                    acceptedButtons: Qt.AllButtons
                    onPressed: islandLoader.item.expanded = false
                }
                Region {
                    id: chassisRegion
                    item: islandInput
                    Region { item: extensionInput }
                    Region { item: menuStartInput }
                    Region { item: menuEndInput }
                    Region {
                        readonly property rect area: islandLoader.item?.notchArea ?? Qt.rect(0, 0, 0, 0)
                        x: islandLoader.x + area.x
                        y: islandLoader.y + area.y
                        width: area.width
                        height: area.height
                    }
                    Region { item: islandEdgeStrip.armed ? islandEdgeStrip : null }
                    Region { item: dockLoader.item && !dockLoader.item.inputOff ? dockLoader.item.hitItem : null }
                    Region {
                        readonly property var rect: editLoader.item?.hitRect ?? null
                        x: rect?.x ?? 0
                        y: rect?.y ?? 0
                        width: rect?.width ?? 0
                        height: rect?.height ?? 0
                    }
                    Region {
                        readonly property var rect: widgetBarLoader.item?.hitRect ?? null
                        x: rect?.x ?? 0
                        y: rect?.y ?? 0
                        width: rect?.width ?? 0
                        height: rect?.height ?? 0
                    }
                    Region {
                        readonly property var rect: editLoader.item?.sheetRect ?? null
                        x: rect?.x ?? 0
                        y: rect?.y ?? 0
                        width: rect?.width ?? 0
                        height: rect?.height ?? 0
                    }
                    Region {
                        readonly property var rect: editLoader.item?.inspectorRect ?? null
                        x: rect?.x ?? 0
                        y: rect?.y ?? 0
                        width: rect?.width ?? 0
                        height: rect?.height ?? 0
                    }
                    Region {
                        readonly property var rect: editLoader.item?.knobRect ?? null
                        x: rect?.x ?? 0
                        y: rect?.y ?? 0
                        width: rect?.width ?? 0
                        height: rect?.height ?? 0
                    }
                    Region {
                        readonly property var panel: (controlCentreLoader.item?.present ?? false)
                            ? controlCentreLoader.item.body : null
                        x: panel ? controlCentreLoader.x + panel.x : 0
                        y: panel ? controlCentreLoader.y + panel.y : 0
                        width: panel ? panel.width : 0
                        height: panel ? panel.height : 0
                    }
                    Region {
                        x: banners.hitRect?.x ?? 0
                        y: banners.hitRect?.y ?? 0
                        width: banners.hitRect?.width ?? 0
                        height: banners.hitRect?.height ?? 0
                    }
                    PieceRegion { index: 0 }
                    PieceRegion { index: 1 }
                    PieceRegion { index: 2 }
                    PieceRegion { index: 3 }
                    PieceRegion { index: 4 }
                    PieceRegion { index: 5 }
                    PieceRegion { index: 6 }
                    PieceRegion { index: 7 }
                    PieceRegion { index: 8 }
                    PieceRegion { index: 9 }
                    PieceRegion { index: 10 }
                    PieceRegion { index: 11 }
                    PieceRegion { index: 12 }
                    PieceRegion { index: 13 }
                    PieceRegion { index: 14 }
                    PieceRegion { index: 15 }
                    PieceRegion { index: 16 }
                    PieceRegion { index: 17 }
                    PieceRegion { index: 18 }
                    PieceRegion { index: 19 }
                    PieceRegion { index: 20 }
                    PieceRegion { index: 21 }
                    PieceRegion { index: 22 }
                    PieceRegion { index: 23 }
                }
                // Arriving, the chassis is scaled; the compositor's region follows geometry, not
                // transforms, so it waits for the arrival instead of blurring beside the bodies.
                readonly property var blurShapes: barWindow.canvasSuppressed || AtollStyle.arriving ? []
                    : (barWindow.fieldShapes ?? []).filter(shape => chassisField.glassOf(shape) === 2)
                readonly property bool frameBlurred: !barWindow.canvasSuppressed && !AtollStyle.arriving
                    && AtollFrame.framed && chassisField.frameGlass === 2
                // The family grows inward: everything the chassis draws comes in from just past the
                // screen edges and settles; the transform is dropped at rest so nothing is resampled.
                Scale {
                    id: arrivalScale
                    origin.x: barWindow.width / 2
                    origin.y: barWindow.height / 2
                    xScale: 1 + 0.035 * (1 - AtollStyle.arrival)
                    yScale: 1 + 0.035 * (1 - AtollStyle.arrival)
                }
                Binding { target: barWindow.contentItem; property: "transform"; value: AtollStyle.arriving ? [arrivalScale] : [] }
                Binding { target: barWindow.contentItem; property: "opacity"; value: Math.min(1, AtollStyle.arrival * 1.6) }
                AtollBlurRegion {
                    id: glassBlurRegion
                    window: barWindow
                    shapes: barWindow.blurShapes
                    framed: barWindow.frameBlurred
                    windowWidth: barWindow.width
                    windowHeight: barWindow.height
                }
                // Keep the area under a still pointer: Wayland sends no re-enter after a resize.
                Item {
                    id: islandInput
                    readonly property real liveWidth: Math.max(islandLoader.width, islandLoader.item?.inputWidth ?? 0)
                    // A resting menu bar takes input on its strip only; the notch has a region of its own.
                    readonly property bool strip: (islandLoader.item?.menubar ?? false) && !(islandLoader.item?.expanded ?? false)
                        && (islandLoader.item?.extensionArea.width ?? 0) <= 0
                    readonly property real liveHeight: strip ? islandLoader.item.stripHeight
                        : Math.max(islandLoader.height, islandLoader.item?.inputHeight ?? 0)
                    property real heldWidth: 0
                    property real heldHeight: 0
                    readonly property bool holding: canvasHover.hovered
                        && (heldWidth > liveWidth + 1 || heldHeight > liveHeight + 1)
                    function release(): void { heldWidth = liveWidth; heldHeight = liveHeight }
                    onLiveWidthChanged: heldWidth = canvasHover.hovered ? Math.max(heldWidth, liveWidth) : liveWidth
                    onLiveHeightChanged: heldHeight = canvasHover.hovered ? Math.max(heldHeight, liveHeight) : liveHeight
                    width: Math.max(liveWidth, heldWidth)
                    height: Math.max(liveHeight, heldHeight)
                    x: !windowLoader.loadedVertical ? islandLoader.x + (islandLoader.width - width) / 2
                        : windowLoader.loadedEdge === "right" ? islandLoader.x + islandLoader.width - width : islandLoader.x
                    y: windowLoader.loadedVertical ? islandLoader.y + (islandLoader.height - height) / 2
                        : windowLoader.loadedBottom ? islandLoader.y + islandLoader.height - height : islandLoader.y
                }
                Item {
                    id: extensionInput
                    readonly property rect area: islandLoader.item?.extensionArea ?? Qt.rect(0, 0, 0, 0)
                    x: islandLoader.x + extensionInput.area.x
                    y: islandLoader.y + extensionInput.area.y
                    width: extensionInput.area.width
                    height: extensionInput.area.height
                }
                Item {
                    id: menuStartInput
                    readonly property rect area: islandLoader.item?.menuStartArea ?? Qt.rect(0, 0, 0, 0)
                    x: islandLoader.x + area.x
                    y: islandLoader.y + area.y
                    width: area.width
                    height: area.height
                }
                Item {
                    id: menuEndInput
                    readonly property rect area: islandLoader.item?.menuEndArea ?? Qt.rect(0, 0, 0, 0)
                    x: islandLoader.x + area.x
                    y: islandLoader.y + area.y
                    width: area.width
                    height: area.height
                }
                // The Island itself is off the edge while hidden, so its own input area
                // cannot catch the pointer that is supposed to bring it back.
                Item {
                    id: islandEdgeStrip
                    readonly property bool armed: barWindow.islandAutoHide
                    readonly property real depth: Math.max(2, AtollFrame.band + 2)
                    readonly property real slack: Math.round(40 * AtollStyle.density)
                    readonly property real span: (windowLoader.loadedVertical ? islandLoader.height : islandLoader.width) + 2 * islandEdgeStrip.slack
                    width: windowLoader.loadedVertical ? islandEdgeStrip.depth : islandEdgeStrip.span
                    height: windowLoader.loadedVertical ? islandEdgeStrip.span : islandEdgeStrip.depth
                    x: windowLoader.loadedVertical
                        ? (windowLoader.loadedEdge === "right" ? barWindow.width - islandEdgeStrip.depth : 0)
                        : Math.round(islandLoader.x - islandEdgeStrip.slack)
                    y: windowLoader.loadedVertical ? Math.round(islandLoader.y - islandEdgeStrip.slack)
                        : (windowLoader.loadedBottom ? barWindow.height - islandEdgeStrip.depth : 0)
                    HoverHandler { id: islandEdgeHover }
                }
                HoverHandler {
                    id: canvasHover
                    property point last: Qt.point(-1, -1)
                    onHoveredChanged: if (!hovered) islandInput.release()
                    onPointChanged: {
                        const p = point.position
                        if (Math.abs(p.x - last.x) + Math.abs(p.y - last.y) > 2) {
                            last = p
                            islandInput.release()
                        }
                    }
                }

                Shortcut {
                    sequence: "Escape"
                    enabled: barWindow.expanded
                    onActivated: islandLoader.item.expanded = false
                }

                Shortcut {
                    sequence: "Escape"
                    enabled: barWindow.editHere
                    onActivated: if (!(editLoader.item?.fold() ?? false)) GlobalStates.atollEdit = false
                }

                // Never coalesced: the field is the outline of what the items paint,
                // so a table that lands a turn later draws the rim and the shadow of
                // the shape the chassis had on the previous frame. Measured at 3 ms
                // per open/close for the whole chain — cheaper than one frame of lag.
                readonly property var fieldShapes: {
                    const dockBody = dockLoader.item?.bodyShape ?? null
                    const hung = (controlCentreLoader.item?.fieldShapes ?? [])
                        .concat(stage.fieldShapes)
                        .concat(editLoader.item?.fieldShapes ?? [])
                        .concat(widgetBarLoader.item?.fieldShapes ?? [])
                        .concat(Array.isArray(dockBody) ? dockBody : [])
                        .concat(banners.fieldShapes)
                        .concat(AtollFrame.placeShapesOn(barWindow.screen?.name ?? ""))
                    const bodies = hung.filter(shape => shape.joins === "island")
                    const island = barWindow.islandTucked ? [] : (islandLoader.item?.fieldShapes ?? []).map(shape => {
                        if (!shape.satellite) return shape
                        const reach = AtollStyle.fuse
                        const body = bodies.find(b => shape.x < b.x + b.width + reach && shape.x + shape.width > b.x - reach
                            && shape.y < b.y + b.height + reach && shape.y + shape.height > b.y - reach)
                        return body ? Object.assign({}, shape, { joins: [body.id].concat(Array.isArray(shape.joins) ? shape.joins.slice(1) : []), fuse: AtollStyle.fuse }) : shape
                    })
                    // Two bodies that meet the frame within reach of each other melt into one another too: joined to
                    // the frame alone, their fillets met in a cusp along the band (a side panel under a corner plate).
                    const framed = shape => (Array.isArray(shape.joins) ? shape.joins : [shape.joins]).length === 1
                        && (Array.isArray(shape.joins) ? shape.joins[0] : shape.joins) === "frame" && !!shape.id
                    const joined = island.concat(hung)
                    const all = joined.map(shape => {
                        if (!framed(shape)) return shape
                        let near = null, best = Infinity
                        for (const other of joined) {
                            if (other === shape || !framed(other)) continue
                            const dx = Math.max(0, other.x - shape.x - shape.width, shape.x - other.x - other.width)
                            const dy = Math.max(0, other.y - shape.y - shape.height, shape.y - other.y - other.height)
                            const gap = Math.hypot(dx, dy)
                            if (gap < Number(shape.fuse ?? 0) && gap < best) { best = gap; near = other }
                        }
                        return near ? Object.assign({}, shape, { joins: ["frame", near.id] }) : shape
                    })
                    if (all.length <= chassisField.capacity) return all
                    return all.filter(shape => !shape.paints)
                        .concat(all.filter(shape => shape.paints))
                        .slice(0, chassisField.capacity)
                }

                AtollField {
                    id: chassisField
                    anchors.fill: parent
                    compositorAllowed: true
                    providesBackdrop: true
                    tint: AtollStyle.chromeSurface
                    edgeWave: framePulse.amplitudes
                    waveClock: framePulse.phase
                    frameMusicLevel: framePulse.visibleLevel
                    shapes: barWindow.fieldShapes
                    opacity: barWindow.canvasSuppressed ? 0 : 1
                    visible: opacity > 0
                    Behavior on opacity { NumberAnimation { duration: AtollStyle.duration(160); easing.type: AtollStyle.feedbackEasing } }
                }

                AtollFramePulse {
                    id: framePulse
                    active: AtollFrame.musicActive && !barWindow.canvasSuppressed
                }

                AtollParts.AtollSpring {
                    id: islandPlacement
                    surface: "island"
                    intent: "move"
                    to: islandLoader.layout === "left" ? 0 : islandLoader.layout === "right" ? 1 : 0.5
                }

                Loader {
                    id: islandLoader
                    z: 3
                    active: GlobalStates.barOpen && root.islandAllowed(barWindow.screen)
                    readonly property string layout: String(root.options?.layout ?? "island")
                    readonly property real inset: AtollFrame.band + root.outerMargin
                    readonly property real edgeMargin: AtollFrame.band + (islandLoader.item
                        ? Math.round(root.restMargin * (1 - Math.min(1, islandLoader.item.notchness))) : root.outerMargin)
                    readonly property real along: islandPlacement.value
                        * ((windowLoader.loadedVertical ? parent.height - islandLoader.height : parent.width - islandLoader.width) - 2 * islandLoader.inset)
                    readonly property real hidden: (windowLoader.loadedVertical ? islandLoader.width : islandLoader.height)
                        + islandLoader.edgeMargin + Math.round(8 * AtollStyle.density)
                    property real tuck: barWindow.islandRevealed ? 0 : islandLoader.hidden
                    Behavior on tuck { NumberAnimation { duration: AtollStyle.morphDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: AtollStyle.morphCurve } }
                    readonly property real tuckX: !windowLoader.loadedVertical ? 0
                        : windowLoader.loadedEdge === "right" ? islandLoader.tuck : -islandLoader.tuck
                    readonly property real tuckY: windowLoader.loadedVertical ? 0
                        : windowLoader.loadedBottom ? islandLoader.tuck : -islandLoader.tuck
                    x: Math.round((!windowLoader.loadedVertical ? islandLoader.inset + islandLoader.along
                        : windowLoader.loadedEdge === "right" ? parent.width - islandLoader.width - islandLoader.edgeMargin : islandLoader.edgeMargin)
                        + islandLoader.tuckX)
                    y: Math.round((windowLoader.loadedVertical ? islandLoader.inset + islandLoader.along
                        : windowLoader.loadedBottom ? parent.height - islandLoader.height - islandLoader.edgeMargin : islandLoader.edgeMargin)
                        + islandLoader.tuckY)
                    width: item?.implicitWidth ?? (windowLoader.loadedVertical ? root.barHeight : 240)
                    height: item?.implicitHeight ?? (windowLoader.loadedVertical ? 240 : root.barHeight)
                    sourceComponent: AtollIsland {
                        id: island
                        targetScreen: barWindow.screen
                        onPieceActivated: (slot, kind, rect) => stage.activate(slot, kind, rect)
                        pointerHeld: islandInput.holding
                        availableWidth: (windowLoader.loadedVertical ? barWindow.height : barWindow.width) - (AtollFrame.band + root.outerMargin) * 2
                        availableAcross: barWindow.width - 2 * (AtollFrame.band + root.outerMargin) - root.barHeight - Math.round(24 * AtollStyle.density)
                        compactHeight: root.barHeight
                        edge: windowLoader.loadedEdge
                        screenOffsetY: 0
                        Connections {
                            target: root
                            function onPieceTapRequested(kind: string): void {
                                if (barWindow.screen?.name !== GlobalStates.focusedScreen?.name) return
                                const part = island.pieceItem(kind)
                                if (!part) return
                                root.pieceTapped = true
                                island.activatePiece(kind, part)
                            }
                            function onIslandRequested(open: bool, page: string): void {
                                if (!open || barWindow.screen?.name === GlobalStates.focusedScreen?.name) {
                                    if (open && (page === "next" || page === "prev")) {
                                        island.stepPage(page === "next" ? 1 : -1)
                                        return
                                    }
                                    if (open) island.page = page
                                    island.pinned = open
                                    island.expanded = open
                                }
                            }
                        }
                    }
                }

                // Above the banners and the Dock, under the Island it grows out of.
                Loader {
                    id: spotlightLoader
                    z: 2.5
                    anchors.fill: parent
                    anchors.margins: AtollFrame.band
                    active: Config.ready && GlobalStates.deferredPanelsReady
                        && (Config.options?.enabledPanels ?? []).includes("atollPalette")
                        && (Config.options?.atoll?.modules?.palette ?? true)
                    asynchronous: true
                    sourceComponent: AtollPalette { screen: barWindow.screen }
                }

                // Resident like Spotlight: built on open it cost ~90 ms before the first frame and grew from outside the Island.
                Loader {
                    id: galleryLoader
                    z: 2.5
                    anchors.fill: parent
                    anchors.margins: AtollFrame.band
                    active: Config.ready && GlobalStates.deferredPanelsReady
                    asynchronous: true
                    sourceComponent: AtollWallpaperPicker { screen: barWindow.screen }
                }

                // A Place like Spotlight: resident, so it opens on a warm frame and grows from where the Island rests.
                Loader {
                    id: orbitLoader
                    z: 2.5
                    anchors.fill: parent
                    anchors.margins: AtollFrame.band
                    active: Config.ready && GlobalStates.deferredPanelsReady && (Config.options?.atoll?.orbit?.enable ?? false)
                    asynchronous: true
                    sourceComponent: AtollOrbit { screen: barWindow.screen }
                }

                AtollBanners {
                    id: banners
                    z: 2
                    anchors.fill: parent
                    screenData: barWindow.screen
                    islandShapes: islandLoader.item?.fieldShapes ?? []
                }

                Loader {
                    id: dockLoader
                    z: 2
                    anchors.fill: parent
                    active: (Config.options?.atoll?.dock?.enable ?? true) && GlobalStates.deferredPanelsReady
                    asynchronous: true
                    sourceComponent: AtollDock {
                        screen: barWindow.screen
                        onPieceActivated: (slot, kind, rect) => stage.activate(slot, kind, rect)
                        onPieceMenuRequested: (slot, kind, rect, menu) => {
                            menu.model = stage.pieceMenu(slot, kind, rect)
                            menu.requestOpen()
                        }
                    }
                }

                AtollStage {
                    id: stage
                    z: 2
                    anchors.fill: parent
                    modelData: barWindow.screen
                    suppressed: barWindow.canvasSuppressed
                }

                Loader {
                    id: editLoader
                    z: 4
                    anchors.fill: parent
                    // Kept until its recede has played out, set imperatively (read back into `active` it is a
                    // binding loop). A grace flag set from atollEditChanged lost the race with `active`, so
                    // Done unloaded the bar inside its own click and the next click went nowhere.
                    property bool lingering: false
                    onLoaded: editLoader.lingering = true
                    Connections {
                        target: editLoader.item
                        function onShownChanged(): void {
                            if (editLoader.item.shown) editLoader.lingering = true
                            else editRelease.restart()
                        }
                    }
                    Timer { id: editRelease; interval: 0; onTriggered: editLoader.lingering = editLoader.item?.shown ?? false }
                    active: barWindow.editHere || editLoader.lingering
                    sourceComponent: AtollEditBar { screenData: barWindow.screen; shapes: barWindow.fieldShapes.concat(stage.pieceShapes, islandLoader.item?.carriedShapes ?? [], dockLoader.item?.editShapes ?? []) }
                }

                Loader {
                    id: widgetBarLoader
                    z: 4
                    anchors.fill: parent
                    // The bar stays until its own exit has played out: tied to edit mode alone, Done unloaded
                    // it from inside its own click, and the click that followed went nowhere.
                    property bool lingering: false
                    onLoaded: widgetBarLoader.lingering = true
                    Connections {
                        target: widgetBarLoader.item
                        function onShownChanged(): void {
                            if (widgetBarLoader.item.shown) widgetBarLoader.lingering = true
                            else widgetBarRelease.restart()
                        }
                    }
                    Timer { id: widgetBarRelease; interval: 0; onTriggered: widgetBarLoader.lingering = widgetBarLoader.item?.shown ?? false }
                    active: (GlobalStates.widgetEditMode || widgetBarLoader.lingering) && !barWindow.canvasSuppressed
                    sourceComponent: AtollWidgetBar { screenData: barWindow.screen }
                }

                Loader {
                    id: controlCentreLoader
                    z: 1
                    anchors.fill: parent
                    readonly property bool panelMode: String(Config.options?.atoll?.controlCenter?.opens ?? "island") !== "island"
                    readonly property bool externalOpen: GlobalStates.controlPanelOpen
                        && (controlCentreLoader.panelMode || GlobalStates.atollMorphOwner === "stage")
                    readonly property bool wanted: controlCentreLoader.externalOpen
                        || (controlCentreLoader.panelMode && GlobalStates.atollControlsWarm)
                        || stage.controlIntent
                    property bool resident: false
                    property Timer releaseTimer: Timer {
                        interval: Math.max(AtollStyle.recedeDuration, AtollStyle.settleDuration) + 120
                        onTriggered: if (!controlCentreLoader.wanted) controlCentreLoader.resident = false
                    }
                    onWantedChanged: {
                        if (controlCentreLoader.wanted) {
                            controlCentreLoader.releaseTimer.stop()
                            controlCentreLoader.resident = true
                        } else if (controlCentreLoader.resident) {
                            controlCentreLoader.releaseTimer.restart()
                        }
                    }
                    Component.onCompleted: if (controlCentreLoader.wanted) controlCentreLoader.resident = true
                    active: (Config.options?.atoll?.modules?.controlCenter ?? true) && controlCentreLoader.resident
                    asynchronous: true
                    sourceComponent: AtollControlCenter { screenData: barWindow.screen }
                }
            }
            }
        }
    }
}
