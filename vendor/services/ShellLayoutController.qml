pragma Singleton
import QtQuick
import Quickshell
import "../modules/common"

// LUNANA BACKING (R4) — Waffle family layout reads.
//
// descriptor()/surfacesForFamily()/currentState() are ported from inir, so
// the Waffle settings page shows the real taskbar placement (read from
// Config.options.waffles.bar.bottom, default bottom). Mutators stay
// honest no-ops: live shell-edit is out of scope, so moveSurface/
// validatePlacement/resetSurface/setProperty return ok:false with a message
// instead of pretending to move anything.
//
// Sidebar slot addressing (Wave-A ii bar) is unchanged: still no-ops.
// currentState() for non-Waffle surfaces returns ok:false — R4 is
// Waffle-scoped, and inventing ii/dock state here would lie to callers.
Singleton {
    id: root

    readonly property string activeFamily: Config.options?.panelFamily ?? "ii"

    readonly property var _descriptors: [
        {
            id: "featureSidebar",
            families: ["ii"],
            kind: "edge",
            labelKey: "Feature sidebar",
            icon: "left_panel_open",
            layoutScope: "global",
            slots: ["left", "right"],
            editableProperties: ["sizeMode", "height", "thickness"],
            collisionPolicy: "swap-sidebar",
            resetScopes: ["surface", "family"]
        },
        {
            id: "systemSidebar",
            families: ["ii"],
            kind: "edge",
            labelKey: "System sidebar",
            icon: "right_panel_open",
            layoutScope: "global",
            slots: ["left", "right"],
            editableProperties: ["sizeMode", "height", "thickness"],
            collisionPolicy: "swap-sidebar",
            resetScopes: ["surface", "family"]
        },
        {
            id: "iiBar",
            families: ["ii"],
            kind: "edge",
            labelKey: "Bar",
            icon: "toolbar",
            layoutScope: "enabledOutputs",
            slots: ["top", "right", "bottom", "left"],
            editableProperties: [],
            collisionPolicy: "swap-edge",
            resetScopes: ["surface", "family"]
        },
        {
            id: "iiDock",
            families: ["ii"],
            kind: "edge",
            labelKey: "Dock",
            icon: "dock_to_bottom",
            layoutScope: "enabledOutputs",
            slots: ["top", "right", "bottom", "left"],
            editableProperties: ["thickness"],
            collisionPolicy: "swap-edge",
            resetScopes: ["surface", "family"]
        },
        {
            id: "waffleBar",
            families: ["waffle"],
            kind: "edge",
            labelKey: "Taskbar",
            icon: "desktop_windows",
            layoutScope: "enabledOutputs",
            slots: ["top", "bottom"],
            editableProperties: [],
            collisionPolicy: "validated",
            resetScopes: ["surface", "family"]
        }
    ]

    function _clone(value: var): var {
        return JSON.parse(JSON.stringify(value))
    }

    function _failure(code: string, message: string): var {
        return {
            ok: false,
            code: code,
            message: message,
            effectiveSlot: "",
            scope: "",
            requiresRebuild: false
        }
    }

    function descriptor(surfaceId: string): var {
        const found = root._descriptors.find(item => item.id === surfaceId)
        return found ? root._clone(found) : null
    }

    function surfacesForFamily(family: string): var {
        const targetFamily = family.length > 0 ? family : root.activeFamily
        return root._descriptors
            .filter(item => item.families.includes(targetFamily))
            .map(item => root._clone(item))
    }

    function currentState(surfaceId: string, outputName: string): var {
        const desc = root.descriptor(surfaceId)
        if (!desc)
            return root._failure("unknown-surface", "Unknown shell surface")
        if (surfaceId === "waffleBar") {
            return {
                ok: true,
                id: surfaceId,
                slot: (Config.options?.waffles?.bar?.bottom ?? true) ? "bottom" : "top",
                scope: desc.layoutScope,
                outputName: outputName,
                enabledOutputs: Config.options?.waffles?.bar?.screenList ?? [],
                source: "waffles.bar.bottom"
            }
        }
        return root._failure("not-backed",
            "R4 backs the Waffle family only; no live state for " + surfaceId)
    }

    function validatePlacement(surfaceId: string, slot: string, outputName: string): var {
        return root._failure("shell-edit-out-of-scope",
            "Live shell-edit is out of scope; placement stays as configured")
    }

    function moveSurface(surfaceId: string, slot: string, outputName: string): var {
        return root._failure("shell-edit-out-of-scope",
            "Live shell-edit is out of scope; placement stays as configured")
    }

    function resetSurface(surfaceId: string, outputName: string): var {
        return root._failure("shell-edit-out-of-scope",
            "Live shell-edit is out of scope; placement stays as configured")
    }

    function setProperty(surfaceId: string, key: string, value: var, outputName: string): var {
        return root._failure("shell-edit-out-of-scope",
            "Live shell-edit is out of scope; placement stays as configured")
    }

    function diagnosticState(outputName: string): var {
        return ({ surfaces: root.surfacesForFamily("waffle"), outputName: outputName })
    }

    // Wave-A sidebar slot addressing: unchanged no-ops (ii bar seam).
    function sidebarOpenAtSlot(slot, output) { return false }
    function toggleSidebarAtSlot(slot, output) {}
}
