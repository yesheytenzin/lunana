pragma Singleton
import QtQuick
import Quickshell
import "../../services" as LnServices

// LUNANA SHIM (not vendored from inir).
// inir's real Config is a ~276KB JsonAdapter. lunana drives these surfaces from
// Omarchy, so this shim exposes just the `Config.options.*` paths the vendored
// UI reads, with inir's defaults (see inir defaults/config.json). Appearance
// (and other surfaces) access everything through optional chaining +
// `?? default`, so missing leaves are safe; the values that matter (globalStyle,
// theme) get wired to lunana/Omarchy state as waves land.
//
// R-union: the option groups below are the exact keys the mounted trees
// (bar/dock/iris/sidebars) read or connect to. Groups that trees `Connections`-
// target (dock, windows) are real QObjects with NOTIFYing properties —
// inir's JsonAdapter exposes the same signals, and a plain JS object target
// only produces "no signal matches" warnings. All other groups are plain
// data with inir's defaults, so every `Config.options.*` read resolves.
//
// Nested access mirrors inir's JsonAdapter API: getNestedValue ("a.b.c",
// fallback), setNestedValue, setNestedValues and previewNestedValue. Writes
// bump `revision`, refresh the `options` identity (so plain-leaf bindings
// re-evaluate) and emit `configChanged` (so Connections handlers re-sync),
// exactly like inir's _bumpRevision + configChanged contract.
Singleton {
    id: root

    property int revision: 0
    // Mirrors inir: false until the config is loaded, then true. The flip is
    // what kicks deferred starts (Translation catalogue scan, panel loaders).
    property bool ready: false
    // Mirrors inir's `signal configChanged`: emitted on load and on every
    // committed nested write. TimerService, Workspaces and the dock/taskbar
    // re-sync on this instead of dangling per-group handlers.
    signal configChanged()

    // inir parity: option groups with live signal bindings. Plain data cannot
    // be a Connections target; these QObjects give DockApps/BarTaskbar their
    // onPinnedAppsChanged / onIgnoredAppRegexesChanged /
    // onAppIdentityRulesChanged notifiers for real.
    QtObject {
        id: dockOptions
        property bool enable: true
        property bool enableBlurGlass: false
        property int height: 60
        property int hoverRegionHeight: 2
        property bool hoverToReveal: false
        property var ignoredAppRegexes: []
        property bool monochromeIcons: true
        // R1: pinned desktop IDs so the exact ii dock renders chrome with
        // zero windows open. All three ship .desktop files + theme icons on
        // this system (firefox/Alacritty/org.gnome.Nautilus); inir's default
        // set names kitty, which is not installed here.
        property var pinnedApps: ["firefox", "Alacritty", "org.gnome.Nautilus"]
        property bool pinnedOnStartup: true
        property var screenList: []
        property bool showBackground: true
        property int iconSize: 35
        property bool separatePinnedFromRunning: true
        property bool enableDragReorder: true
        property bool notificationBadge: true
        property string style: "m3"
        // Not in inir's defaults; the tree opts out with `!== false`.
        property bool hoverPreview: true
    }
    QtObject {
        id: windowsOptions
        property bool centerTitle: true
        property bool showTitlebar: true
        property var appIdentityRules: []
    }

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
        bar: {
            borderless: true, cornerStyle: 1, height: 40, verbose: false,
            autoHide: {
                enable: false, hoverRegionWidth: 2, pushWindows: false,
                showWhenPressingSuper: { delay: 140, enable: true }
            },
            tray: {
                filterPassive: true, invertPinnedItems: true,
                monochromeIcons: true, pinnedItems: [], showItemId: false
            },
            indicators: { notifications: { showUnreadCount: true } }
        },
        dock: dockOptions,
        windows: windowsOptions,
        performance: { reduceAnimations: false, lowPower: false, compositorBlur: false },
        time: {
            format: "hh:mm", shortDateFormat: "dd/MM", dateFormat: "ddd, dd/MM",
            secondPrecision: false,
            pomodoro: { focus: 1500, breakTime: 300, longBreak: 900, cyclesBeforeLongBreak: 4 }
        },
        networking: { userAgent: "" },
        interactions: {
            scrolling: {
                fasterTouchpadScroll: false, mouseScrollDeltaThreshold: 120,
                mouseScrollFactor: 120, touchpadScrollFactor: 450
            }
        },
        battery: {
            automaticSuspend: false, critical: 5, full: 101, low: 20,
            notifyFull: true, suspend: 3,
            chargeLimit: { enable: false, threshold: 80 }
        }
    })

    // --- nested access (inir JsonAdapter parity) ---------------------------

    function _splitPath(nestedKey) {
        if (Array.isArray(nestedKey)) return nestedKey;
        if (typeof nestedKey === "string" && nestedKey.length > 0) return nestedKey.split(".");
        return [];
    }

    // QObjects expose objectName; plain JS objects/arrays don't.
    function _isQtObject(v) {
        return v !== null && typeof v === "object" && v.objectName !== undefined;
    }

    function _convertValue(value) {
        if (typeof value === "string") {
            const trimmed = value.trim();
            if (trimmed === "true" || trimmed === "false" || !isNaN(Number(trimmed))) {
                try { return JSON.parse(trimmed); } catch (e) { return value; }
            }
        }
        return value;
    }

    // Walk to the parent of the leaf. Creates plain-object intermediates;
    // QtObject groups only accept their declared keys (all settings paths
    // under dock/windows are declared above), so creation stops there.
    function _parentOf(keys, create) {
        let obj = root.options;
        for (let i = 0; i < keys.length - 1; ++i) {
            const k = keys[i];
            let next = obj[k];
            if (next === undefined || next === null) {
                if (!create || root._isQtObject(obj)) return null;
                next = {};
                obj[k] = next;
            }
            obj = next;
        }
        return obj;
    }

    function _applyNestedKey(nestedKey, value) {
        const keys = root._splitPath(nestedKey);
        if (keys.length === 0) {
            console.warn("[Config] setNestedValue called with an invalid key:", nestedKey);
            return false;
        }
        const parent = root._parentOf(keys, true);
        if (parent === null || parent === undefined) return false;
        const leaf = keys[keys.length - 1];
        const converted = root._convertValue(value);
        const target = parent[leaf];
        // Object payloads aimed at a QtObject group land key by key (the
        // engine rejects wholesale QJSValue assignment); plain leaves assign.
        if (converted !== null && typeof converted === "object" && !Array.isArray(converted)
                && root._isQtObject(target)) {
            const ks = Object.keys(converted);
            for (let i = 0; i < ks.length; ++i) parent[leaf][ks[i]] = converted[ks[i]];
        } else {
            parent[leaf] = converted;
        }
        return true;
    }

    function _bumpRevision() {
        root.revision = (root.revision + 1) % 2147483647;
    }

    // Committed writes refresh every options binding: plain-leaf reads only
    // re-evaluate when the `options` identity changes, QtObject leaves notify
    // on their own, and Connections handlers follow `configChanged`.
    function _commitWrite() {
        root._bumpRevision();
        root.options = Object.assign({}, root.options);
        root.configChanged();
    }

    function getNestedValue(nestedKey, fallback) {
        root.revision;
        const keys = root._splitPath(nestedKey);
        if (keys.length === 0) return fallback;
        let obj = root.options;
        for (let i = 0; i < keys.length; ++i) {
            if (obj === undefined || obj === null) return fallback;
            obj = obj[keys[i]];
        }
        return obj === undefined ? fallback : obj;
    }

    function setNestedValue(nestedKey, value) {
        if (root._applyNestedKey(nestedKey, value)) root._commitWrite();
    }

    // Batch several writes, emitting configChanged only once.
    function setNestedValues(updates) {
        if (!updates || typeof updates !== "object") return;
        const paths = Object.keys(updates);
        let applied = false;
        for (let i = 0; i < paths.length; ++i) {
            if (root._applyNestedKey(paths[i], updates[paths[i]])) applied = true;
        }
        if (applied) root._commitWrite();
    }

    // A drag preview: consumers follow it, but nothing commits.
    function previewNestedValue(nestedKey, value) {
        root._applyNestedKey(nestedKey, value);
    }

    // No file backend in the shim; writes are in-memory. Kept so settings
    // surfaces calling it keep working.
    function flushWrites() {}

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
    // Async flip like inir's JsonAdapter: deferred so every singleton's
    // onReadyChanged (Translation scans, panel loaders) is attached first.
    // A same-tick onCompleted flip fires before late listeners attach.
    Timer {
        interval: 100
        running: true
        repeat: false
        onTriggered: {
            root.ready = true;
            root.configChanged();
            LnServices.MaterialThemeLoader.applyPalette();
        }
    }
}
