pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import "../../.."
import "../../../services"
import "../../common"
import "../../common/functions"

// The desktop menu, one model for the widget canvas and the bare background: the wallpaper as its
// head, then the actions chosen in Settings (`atoll.desktopMenu.items`), grouped by what they touch,
// with a line between groups.
Singleton {
    id: root

    function lunana(args: var): void {
        Quickshell.execDetached([((Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")) + "/omarchy/lunana-vendor/" + ("scripts/lunana"))].concat(args))
    }

    // Every action the menu can carry. `group` orders the sections: the desktop, tools, the shell.
    readonly property var catalogue: [
        { id: "widgets", group: 0, label: Translation.tr("Edit widgets"), glyph: "widgets", tint: "teal",
            run: screen => {
                Config.setNestedValue("atoll.modules.desktopWidgets", true)
                GlobalStates.setWidgetEditMode(true)
            } },
        { id: "addWidgets", group: 0, label: Translation.tr("Add widgets"), glyph: "add_circle", tint: "teal",
            run: screen => {
                Config.setNestedValue("atoll.modules.desktopWidgets", true)
                GlobalStates.setWidgetEditMode(true)
                GlobalStates.desktopWidgetManagerToggleRequested(screen)
            } },
        { id: "customize", group: 0, label: Translation.tr("Customize Atoll"), glyph: "palette", tint: "purple",
            run: screen => GlobalStates.openIrisCustomize("") },
        { id: "nextWallpaper", group: 0, label: Translation.tr("Next wallpaper"), glyph: "shuffle", tint: "pink",
            run: screen => Wallpapers.nextWallpaper(Appearance.m3colors.darkmode, screen) },
        { id: "screenshot", group: 1, label: Translation.tr("Screenshot"), glyph: "screenshot_region", tint: "blue",
            run: screen => root.lunana(["region", "screenshot"]) },
        { id: "record", group: 1, label: Translation.tr("Record screen"), glyph: "screen_record", tint: "red",
            run: screen => root.lunana(["region", "record"]) },
        { id: "colorPicker", group: 1, label: Translation.tr("Pick a colour"), glyph: "colorize", tint: "orange",
            run: screen => root.lunana(["colorpicker"]) },
        { id: "terminal", group: 1, label: Translation.tr("Terminal"), glyph: "terminal", tint: "gray",
            run: screen => root.lunana(["terminal"]) },
        { id: "files", group: 1, label: Translation.tr("Files"), glyph: "folder", tint: "sky",
            run: screen => Quickshell.execDetached(["xdg-open", Quickshell.env("HOME") ?? "/"]) },
        { id: "settings", group: 2, label: Translation.tr("Settings"), glyph: "settings", tint: "gray",
            run: screen => root.lunana(["atoll", "settings", ""]) },
        { id: "restart", group: 2, label: Translation.tr("Restart shell"), glyph: "restart_alt", tint: "gray",
            run: screen => root.lunana(["restart"]) }
    ]
    readonly property var defaultItems: ["widgets", "customize", "screenshot", "terminal", "settings", "restart"]

    readonly property var options: Config.options?.atoll?.desktopMenu ?? ({})
    readonly property bool showWallpaper: root.options.wallpaper ?? true
    readonly property var chosen: {
        const list = Array.from(root.options.items ?? root.defaultItems)
        return list.filter(id => root.catalogue.some(entry => entry.id === id))
    }

    function menu(screenName: string, wallpaper: string, preview: string): var {
        const out = []
        if (root.showWallpaper)
            out.push({ type: "hero", id: "wallpaper", text: Translation.tr("Wallpaper"), detail: Translation.tr("Change"), image: preview,
                iconName: "chevron_right",
                action: () => {
                    GlobalStates.wallpaperSelectorTargetMonitor = screenName
                    GlobalActions.runLauncher(["wallpaperSelector", "toggle"])
                },
                secondary: { id: "wallpaperNext", iconName: "shuffle", text: Translation.tr("Next wallpaper"),
                    action: () => Wallpapers.nextWallpaper(Appearance.m3colors.darkmode, screenName) } })
        const groupOf = id => root.catalogue.find(item => item.id === id).group
        const ordered = root.chosen.map((id, index) => ({ id: id, index: index }))
            .sort((a, b) => groupOf(a.id) - groupOf(b.id) || a.index - b.index).map(item => item.id)
        let group = -1
        for (const id of ordered) {
            const entry = root.catalogue.find(item => item.id === id)
            if (group >= 0 ? entry.group !== group : out.length > 0)
                out.push({ type: "separator" })
            group = entry.group
            out.push({ id: entry.id, text: entry.label, iconName: entry.glyph, tint: entry.tint, action: () => entry.run(screenName) })
        }
        return out
    }

    function run(id: string, screenName: string): string {
        const shown = root.menu(screenName, "", "")
        for (const item of shown) {
            if (item.id === id && item.action) { item.action(); return id }
            if (item.secondary?.id === id) { item.secondary.action(); return id }
        }
        const entry = root.catalogue.find(item => item.id === id)
        if (!entry) return "Unknown action: wallpaper, wallpaperNext or " + root.catalogue.map(item => item.id).join(", ")
        entry.run(screenName)
        return id
    }
}
