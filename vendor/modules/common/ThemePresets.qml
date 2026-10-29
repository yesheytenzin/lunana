pragma Singleton
import QtQuick
import Quickshell

// LUNANA SHIM (not vendored from inir).
// inir's real ThemePresets is a ~153KB catalog of named color presets. Appearance
// only reads `activeThemePreset.meta`, so the shim returns a preset carrying a
// sensible meta block. The full catalog can be vendored later for the themes UI.
Singleton {
    function getPreset(name) {
        return {
            id: name,
            name: name,
            meta: { roundingScale: 1, fontStyle: "default" },
            colors: ({})
        }
    }
}
