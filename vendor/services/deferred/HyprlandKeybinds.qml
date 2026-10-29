pragma Singleton
pragma ComponentBehavior: Bound

import "../../modules/common"
import "../../modules/common/functions"
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import ".."

/**
 * A service that provides access to Hyprland keybinds.
 * Uses the `get_keybinds.py` script to parse comments in config files in a certain format and convert to JSON.
 */
Singleton {
    id: root
    property string keybindParserPath: FileUtils.trimFileProtocol(`${Directories.scriptPath}/hyprland/get_keybinds.py`)
    property string defaultKeybindConfigPath: FileUtils.trimFileProtocol(`${Directories.config}/hypr/hyprland/keybinds.conf`)
    property string userKeybindConfigPath: FileUtils.trimFileProtocol(`${Directories.config}/hypr/custom/keybinds.conf`)
    // Omarchy (Quattro) owns keybinds in ~/.config/hypr/bindings.lua via
    // o.bind("KEYS", "Description", "command"). lunana-suite merges its own
    // block there, so the cheatsheet must read this file — the .conf parser
    // above does not follow `source=` includes and cannot parse lua.
    property string omarchyKeybindConfigPath: FileUtils.trimFileProtocol(`${Directories.config}/hypr/bindings.lua`)
    property var defaultKeybinds: {"children": []}
    property var userKeybinds: {"children": []}
    property var omarchyKeybinds: {"children": []}
    property var keybinds: ({
        children: [
            ...(defaultKeybinds.children ?? []),
            ...(userKeybinds.children ?? []),
            ...(omarchyKeybinds.children ?? []),
        ]
    })

    FileView {
        id: omarchyBindsFile
        path: root.omarchyKeybindConfigPath
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: root.omarchyKeybinds = root.parseOmarchyBinds(text())
    }

    // Parse o.bind("MOD + KEY", "Description", "command") lines. Comment lines
    // starting with `-- #!` become section headers; lines tagged `[hidden]`
    // are skipped — the same conventions as get_keybinds.py.
    function parseOmarchyBinds(text): var {
        const sections = []
        let current = { name: "Omarchy", children: [], keybinds: [] }
        try {
            const lines = String(text ?? "").split("\n")
            const bindRe = /o\.bind\(\s*"([^"]+)"\s*,\s*"([^"]*)"/
            for (const raw of lines) {
                const line = raw.trim()
                if (line.startsWith("-- #!")) {
                    if (current.keybinds.length > 0 || current.name !== "Omarchy")
                        sections.push(current)
                    current = { name: line.slice(5).trim(), children: [], keybinds: [] }
                    continue
                }
                const m = line.match(bindRe)
                if (!m) continue
                if (m[2].includes("[hidden]")) continue
                current.keybinds.push({
                    mods: "", key: m[1], dispatcher: "",
                    params: "", comment: m[2].replace("[hidden]", "").trim()
                })
            }
            sections.push(current)
        } catch (e) {}
        return { children: sections }
    }

    Connections {
        target: CompositorService.isHyprland ? Hyprland : null
        enabled: CompositorService.isHyprland

        function onRawEvent(event) {
            if (event.name == "configreloaded") {
                getDefaultKeybinds.running = true
                getUserKeybinds.running = true
            }
        }
    }

    Process {
        id: getDefaultKeybinds
        running: false
        command: [root.keybindParserPath, "--path", root.defaultKeybindConfigPath]
        
        stdout: SplitParser {
            onRead: data => {
                try {
                    root.defaultKeybinds = JSON.parse(data)
                } catch (e) {
                    console.error("[CheatsheetKeybinds] Error parsing keybinds:", e)
                }
            }
        }
    }

    Process {
        id: getUserKeybinds
        running: false
        command: [root.keybindParserPath, "--path", root.userKeybindConfigPath]
        
        stdout: SplitParser {
            onRead: data => {
                try {
                    root.userKeybinds = JSON.parse(data)
                } catch (e) {
                    console.error("[CheatsheetKeybinds] Error parsing keybinds:", e)
                }
            }
        }
    }

    Timer {
        id: initTimer
        interval: 600
        repeat: false
        onTriggered: {
            if (!CompositorService.isHyprland) return
            getDefaultKeybinds.running = true
            getUserKeybinds.running = true
        }
    }

    Connections {
        target: CompositorService
        function onIsHyprlandChanged() {
            if (CompositorService.isHyprland) {
                initTimer.start()
            }
        }
    }

    Component.onCompleted: {
        if (CompositorService.isHyprland) initTimer.start()
    }
}

