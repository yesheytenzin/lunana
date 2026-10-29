pragma Singleton
import QtQuick
import Quickshell
import ".."
import "../../modules/common"
import "../../modules/common/functions"
import "../../modules/common/models"

// LUNANA BACKING (R4) — minimal launcher search over DesktopEntries.
//
// Only the members the Waffle start menu reads are implemented:
// `query`, `ensurePrefix(prefix)`, `results`. Results are real application
// entries (AppSearch.fuzzyQuery, deduped by display name like inir) plus a
// "Run command" fallback. inir's extra providers (math, web, clipboard,
// emoji, actions) stay out: they need Cliphist/Emojis/GlobalActions, which
// are not vendored — note in commit, honestly still missing.
Singleton {
    id: root

    property string query: ""

    // inir's Config defaults for search prefixes (our Config shim has no
    // search tree yet, so these live here instead of Config.options).
    readonly property string _appPrefix: Config.options?.search?.prefix?.app ?? ">"
    readonly property string _shellPrefix: Config.options?.search?.prefix?.shellCommand ?? "$"

    function ensurePrefix(prefix: string): void {
        const known = [root._appPrefix, root._shellPrefix, "/", ";", ":", "=", "?", ">", "$"]
        if (known.some(p => p.length > 0 && root.query.startsWith(p))) {
            root.query = prefix + root.query.slice(1)
        } else {
            root.query = prefix + root.query
        }
    }

    property list<var> results: {
        const q = root.query
        if (q === "") return []

        const appQuery = q.startsWith(root._appPrefix) ? q.slice(root._appPrefix.length) : q
        const appEntries = AppSearch.fuzzyQuery(appQuery)

        // Dedupe by display name (Flatpak + system pairs), like inir.
        const seen = new Set()
        let result = []
        for (let i = 0; i < appEntries.length; i++) {
            const entry = appEntries[i]
            const nameKey = (entry?.name ?? "").trim().toLowerCase()
            if (nameKey.length === 0) continue
            if (seen.has(nameKey)) continue
            seen.add(nameKey)
            result.push({
                type: Translation.tr("App"),
                id: entry.id ?? entry.name ?? "",
                name: entry.name,
                iconName: entry.icon,
                iconType: LauncherSearchResult.IconType.System,
                verb: Translation.tr("Launch"),
                comment: entry.comment ?? "",
                genericName: entry.genericName ?? "",
                runInTerminal: entry.runInTerminal ?? false,
                execute: () => { AppSearch.launchEntry(entry) }
            })
        }

        // Shell command fallback: explicit `$cmd`, or Dictinct "Run ..." row
        // when the query looks like a command and matched nothing.
        const shellQuery = q.startsWith(root._shellPrefix) ? q.slice(root._shellPrefix.length) : q
        if (q.startsWith(root._shellPrefix) || (result.length === 0 && shellQuery.trim().length > 0)) {
            result.push({
                name: shellQuery,
                verb: Translation.tr("Run"),
                type: Translation.tr("Command"),
                fontType: LauncherSearchResult.FontType.Monospace,
                iconName: "terminal",
                iconType: LauncherSearchResult.IconType.Material,
                execute: () => { ShellExec.execCmd(shellQuery) }
            })
        }

        return result
    }
}
