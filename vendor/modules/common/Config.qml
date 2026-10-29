pragma Singleton
import QtQuick
import Quickshell
import "../../services" as LnServices

// LUNANA SHIM (not vendored from inir).
// inir's real Config is a ~276KB JsonAdapter. lunana drives these surfaces from
// Omarchy, so this shim exposes just the `Config.options.*` paths the vendored
// UI reads, with inir-like defaults. Appearance (and other surfaces) access
// everything through optional chaining + `?? default`, so missing leaves are
// safe; the values that matter (globalStyle, theme) get wired to lunana/Omarchy
// state as waves land.
Singleton {
    id: root

    property int revision: 0
    readonly property bool ready: true

    property var options: ({
        appearance: {
            globalStyle: "material",
            theme: "auto",
            desaturation: 0,
            typography: {
                mainFont: "", titleFont: "", monospaceFont: "", sizeScale: 1,
                variableAxes: { wght: 400, wdth: 100, grad: 0 }
            },
            animationSpeed: { clickBounce: 1, enterExit: 1, movement: 1, scroll: 1 },
            animationCurve: {},
            aurora: { transparency: 0.1 },
            angel: {
                border: {}, blur: {}, glow: {}, surface: {}, transparency: {},
                rounding: {}, escalonado: {}, escalonadoShadow: {}, colorStrength: 1
            },
            editorial: {},
            regalia: {},
            zzz: { shape: "chamfer", glass: false }
        },
        bar: { borderless: true, cornerStyle: 1, height: 40, verbose: false },
        // R1: pinned desktop IDs so the exact ii dock renders chrome with
        // zero windows open. All three ship .desktop files + theme icons on
        // this system (firefox/Alacritty/org.gnome.Nautilus). Every other
        // dock.* read in the vendored tree has a `?? default` fallback.
        dock: { pinnedApps: ["firefox", "Alacritty", "org.gnome.Nautilus"] },
        performance: { reduceAnimations: false, lowPower: false, compositorBlur: false }
    })

    // inir mutates config through this; the shim is read-mostly for now.
    function setNestedValue(path, value) {}

    // Odd top-level reads in Appearance; benign defaults.
    property var sidebars: ({})
    property var popups: ({})
    property var overlays: ({})
    property var scope: ({})
    property real saturation: 1
    property var dock: ({})
    property var brightness: ({})
    property bool enable: true

    // Wave-A seam trigger: every vendored surface reads Config, so poking the
    // palette bridge here guarantees Omarchy's colors reach
    // Appearance.m3colors (singletons are lazy — nothing else instantiates the
    // loader, which is why the probe first rendered inir defaults).
    Component.onCompleted: LnServices.MaterialThemeLoader.applyPalette()
}
