pragma Singleton
pragma ComponentBehavior: Bound

import "modules/common"
import "services"
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

Singleton {
    id: root
    // Shell entry animation gate — starts false, set true after delay so panels slide in
    property bool shellEntryReady: false
    // Deferred panel loading gate — non-critical panels wait for this before activating
    property bool deferredPanelsReady: false
    // Startup lifecycle — singleton preserves one-shot state across hot reloads.
    property bool bootGreetingOpen: false
    property bool bootGreetingDone: false
    property bool startupLockDone: false
    property bool barOpen: true
    property bool crosshairOpen: false
    property bool sidebarLeftOpen: false
    property string sidebarLeftTargetOutput: ""
    property bool sidebarLeftExpanded: false
    // A left-sidebar feature requests the panel stay open through implicit closes
    // (backdrop click / focus loss) and yield keyboard focus — e.g. the InnerTune
    // device-flow login, where the user must type a code into an external browser.
    property bool sidebarLeftHoldOpen: false
    property bool aiChatDetached: false
    property bool sidebarRightOpen: false
    property string sidebarRightTargetOutput: ""
    property bool mediaControlsOpen: false
    property bool equalizerOpen: false
    property string equalizerTargetOutput: ""
    readonly property bool equalizerEnabled: (Config.options?.enabledPanels ?? []).includes("driftEqualizer")

    function openEqualizer(outputName: string): void {
        if (!root.equalizerEnabled)
            return
        const requested = String(outputName ?? "")
        equalizerTargetOutput = requested.length > 0
            ? requested
            : String(root.focusedScreen?.name ?? root.primaryScreen?.name ?? "")
        equalizerOpen = true
    }

    function closeEqualizer(): void {
        equalizerOpen = false
    }

    function toggleEqualizer(outputName: string): void {
        if (!root.equalizerEnabled) {
            closeEqualizer()
            return
        }
        if (equalizerOpen) {
            closeEqualizer()
            return
        }
        openEqualizer(outputName)
    }
    property real atollLevelQuietUntil: 0
    function quietIrisLevels(): void { root.atollLevelQuietUntil = Date.now() + 700 }
    property bool osdBrightnessOpen: false
    property bool osdVolumeOpen: false
    property bool osdMicOpen: false
    property bool osdMediaOpen: false
    property string osdMediaAction: "play" // "play", "pause", "next", "previous"
    signal osdMediaActionTriggered(string action)
    readonly property bool userMediaFeedback: Config.options?.panelFamily === "atoll"
        || (Config.options?.osd?.mediaEnabled ?? true)

    function showMediaAction(action: string): void {
        const normalized = String(action ?? "")
        if (!["play", "pause", "next", "previous"].includes(normalized))
            return
        root.osdMediaAction = normalized
        root.osdMediaOpen = true
        root.osdMediaActionTriggered(normalized)
    }

    property bool osdKeyboardLayoutOpen: false
    property bool osdConnectionOpen: false
    property bool oskOpen: false
    property bool overlayOpen: false
    property bool overviewOpen: false
    property string overviewMode: "default"
    property string overviewTargetOutput: ""
    property string overviewSearchPrefix: ""
    property bool orbitPocketRequested: false
    property bool orbitStudioRequested: false
    property bool orbitLensRequested: false
    property string orbitLensRequestedQuery: ""
    property string orbitStageOverride: ""
    property var orbitRuntimeStatus: ({ open: false })
    signal orbitNavigateRequested(int direction)
    signal pillSurfaceCommand(string command, string surface)
    property bool altSwitcherOpen: false
    signal altSwitcherCommand(string command)
    property int activeContextMenuCount: 0
    property var activeContextMenu: null
    property bool clipboardOpen: false
    // True only while Lunana asks Niri for internal window-preview frames.
    property bool windowPreviewCaptureActive: false
    property bool settingsOverlayOpen: false
    property int settingsOverlayRequestedPage: -1 // Set before opening to navigate to a specific page
    property string settingsOverlayRequestedSection: ""
    property int settingsOverlayCurrentPage: -1 // Published by whichever overlay chrome is loaded
    // Atoll Settings as a window: open or toggle with it mapped but not focused brings it forward instead.
    property bool settingsWindowBehind: false
    property int settingsRaiseRequest: 0
    property var _settingsNativeDialogs: ({})
    readonly property bool settingsNativeDialogOpen:
        Object.keys(root._settingsNativeDialogs).length > 0

    function openSettingsPage(index: int, section): void {
        const requestedSection = String(section ?? "")
        const isSlate = Config.options?.panelFamily === "slate"
            && Config.options?.slate?.settings?.useMaterialStyle !== true
        if (isSlate) {
            Quickshell.execDetached([((Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")) + "/omarchy/lunana-vendor/" + ("scripts/lunana")),
                "slate-settings-window"])
        } else if (Config.options?.panelFamily === "atoll" || (Config.options?.settingsUi?.overlayMode ?? false)) {
            root.settingsOverlayRequestedPage = index
            root.settingsOverlayRequestedSection = requestedSection
            if (root.settingsOverlayOpen) root.settingsRaiseRequest++
            root.settingsOverlayOpen = true
        } else {
            const args = ["/usr/bin/env", `QS_SETTINGS_PAGE=${index}`]
            if (requestedSection.length > 0)
                args.push(`QS_SETTINGS_SECTION=${requestedSection}`)
            args.push(((Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")) + "/omarchy/lunana-vendor/" + ("scripts/lunana")), "settings-window")
            Quickshell.execDetached(args)
        }
    }

    function openSettings(): void {
        const isSlate = Config.options?.panelFamily === "slate"
            && Config.options?.slate?.settings?.useMaterialStyle !== true
        if (isSlate) {
            Quickshell.execDetached([((Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")) + "/omarchy/lunana-vendor/" + ("scripts/lunana")),
                "slate-settings-window"])
        } else if (Config.options?.panelFamily === "atoll" || (Config.options?.settingsUi?.overlayMode ?? false)) {
            if (root.settingsOverlayOpen) root.settingsRaiseRequest++
            root.settingsOverlayOpen = true
        } else {
            Quickshell.execDetached([((Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")) + "/omarchy/lunana-vendor/" + ("scripts/lunana")),
                "settings-window"])
        }
    }

    function toggleSettings(): void {
        const isSlate = Config.options?.panelFamily === "slate"
            && Config.options?.slate?.settings?.useMaterialStyle !== true
        if (isSlate) {
            Quickshell.execDetached([((Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")) + "/omarchy/lunana-vendor/" + ("scripts/lunana")),
                "slate-settings-window", "--toggle"])
        } else if (Config.options?.panelFamily === "atoll" || (Config.options?.settingsUi?.overlayMode ?? false)) {
            if (root.settingsOverlayOpen && root.settingsWindowBehind) root.settingsRaiseRequest++
            else root.settingsOverlayOpen = !root.settingsOverlayOpen
        } else {
            Quickshell.execDetached([((Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")) + "/omarchy/lunana-vendor/" + ("scripts/lunana")),
                "settings-window", "--toggle"])
        }
    }

    function setSettingsNativeDialogVisible(dialogKey: string, visible: bool): void {
        const key = String(dialogKey ?? "").trim()
        if (!key) return
        const next = Object.assign({}, root._settingsNativeDialogs)
        if (visible)
            next[key] = true
        else
            delete next[key]
        root._settingsNativeDialogs = next
    }

    property bool regionSelectorOpen: false
    property bool japaneseLookupOpen: false
    property bool japaneseLookupExpanded: false
    property var japaneseLookupResult: ({})
    property string japaneseLookupScreen: ""
    property real japaneseLookupX: 0
    property real japaneseLookupY: 0
    property real japaneseLookupWidth: 0
    property real japaneseLookupHeight: 0
    property var regionSelectorAction: 0
    property var regionSelectorMode: 0
    // Explicit screenshot callers must remain deterministic. The dedicated
    // Niri binds for screenshot, OCR and visual search are separate contracts;
    // opening one must never inherit state left by another tool.
    function openRegionScreenshot(): void {
        regionSelectorAction = 0
        regionSelectorMode = 0
        regionSelectorOpen = true
    }

    // The unified snip menu may restore the last toolbar choice. Raw ordinals
    // mirror RegionSelection's enums: action 0 Shot, 1 Edit, 2 Search, 3 OCR
    // (record is never restored); mode 0 rectangle, 1 circle.
    function openRememberedRegionTool(): void {
        let action = 0
        let mode = 0
        if (Config.options?.regionSelector?.rememberSnipChoice ?? true) {
            const savedAction = Config.options?.regionSelector?.lastAction ?? 0
            const savedMode = Config.options?.regionSelector?.lastMode ?? 0
            if (savedAction >= 0 && savedAction <= 3) action = savedAction
            if (savedMode === 1) mode = savedMode
        }
        regionSelectorAction = action
        regionSelectorMode = mode
        regionSelectorOpen = true
    }
    property bool tilingOverlayPickerOpen: false
    property bool tilingOverlayOsdOpen: false
    // Native screenshot annotation editor (Edit action)
    property bool annotationEditorOpen: false
    property string annotationEditorPath: ""
    property string annotationEditorScreenName: ""
    property bool screenLocked: false
    property bool screenLockContainsCharacters: false
    property bool screenUnlockFailed: false
    property bool sessionOpen: false
    property bool superDown: false
    property bool superReleaseMightTrigger: true
    property bool wallpaperSelectorOpen: false
    property string wallpaperSelectorSource: ""
    property string wallpaperSelectorQuery: ""
    property string wallpaperSelectorKind: ""
    // `lunana wallpaperSelector move <step>`: the gallery moves its selection as the arrow keys do.
    signal wallpaperSelectorMoveRequested(int step)
    property var wallpaperSelectorSeries: null
    property string wallpaperSelectorKindActive: "all"
    property bool wallpaperLauncherOpen: false
    property string wallpaperLauncherMode: "static"
    property bool widgetEditMode: false
    // Finding a widget while arranging (the Atoll widget bar); `lunana background widgetSearch` drives the same state.
    property bool widgetSearchOpen: false
    property string widgetSearchText: ""
    signal widgetSearchCommand(string verb)
    // Arrow keys while arranging under Atoll: the chassis owns the keyboard and hands the step to the selected widget.
    signal desktopWidgetNudge(int dx, int dy)
    property string selectedDesktopWidget: ""
    property string selectedDesktopItem: ""
    property string desktopWidgetQuickControls: ""
    property string desktopWidgetManagerOutput: ""
    property bool shellLayoutEditMode: false

    function setWidgetEditMode(enabled: bool): void {
        if (enabled) {
            shellLayoutEditMode = false
            atollEdit = false
        }
        else {
            selectedDesktopWidget = ""
            selectedDesktopItem = ""
            desktopWidgetQuickControls = ""
            widgetSearchOpen = false
            widgetSearchText = ""
        }
        widgetEditMode = enabled
    }

    function selectDesktopWidget(instanceKey: string): void {
        if (!widgetEditMode)
            return
        selectedDesktopWidget = String(instanceKey ?? "")
        selectedDesktopItem = ""
    }

    function clearDesktopWidgetSelection(): void {
        selectedDesktopWidget = ""
        selectedDesktopItem = ""
        desktopWidgetQuickControls = ""
    }

    function selectDesktopItem(instanceKey: string): void {
        selectedDesktopItem = String(instanceKey ?? "")
        selectedDesktopWidget = ""
    }

    function clearDesktopItemSelection(): void {
        selectedDesktopItem = ""
    }

    function requestDesktopWidgetQuickControls(instanceKey: string): void {
        if (!widgetEditMode)
            return
        const key = String(instanceKey ?? "")
        selectedDesktopWidget = key
        desktopWidgetQuickControls = key
    }

    function setShellLayoutEditMode(enabled: bool): void {
        if (enabled) {
            widgetEditMode = false
            selectedDesktopWidget = ""
            selectedDesktopItem = ""
            desktopWidgetQuickControls = ""
        }
        shellLayoutEditMode = enabled
    }
    // Navigate sidebar right to a specific widget by type (e.g. "notepad", "calendar")
    property string sidebarRightRequestedWidget: ""
    // Dialog requests from other panels (e.g. left sidebar → right sidebar)
    property bool requestWifiDialog: false
    property bool requestBluetoothDialog: false
    // Selection targets: "main", "backdrop", "slate", "slate-backdrop"
    property string wallpaperSelectionTarget: "main"
    // Target monitor for wallpaper selector (set before opening, avoids config timing issues)
    property string wallpaperSelectorTargetMonitor: ""
    onWallpaperSelectorOpenChanged: {
        if (wallpaperSelectorOpen) atollOrbitOpen = false
        // Reset selection target when selector closes without selection
        if (!wallpaperSelectorOpen) {
            wallpaperSelectionTarget = "main";
            wallpaperSelectorTargetMonitor = "";
            // Also reset Config targets if they were set
            if (Config.options?.wallpaperSelector?.selectionTarget &&
                Config.options.wallpaperSelector.selectionTarget !== "main") {
                Config.setNestedValue("wallpaperSelector.selectionTarget", "main")
            }
            if (Config.options?.wallpaperSelector?.targetMonitor) {
                Config.setNestedValue("wallpaperSelector.targetMonitor", "")
            }
        }
    }
    onWallpaperLauncherOpenChanged: {
        if (wallpaperLauncherOpen) atollOrbitOpen = false
        if (!wallpaperLauncherOpen) {
            // Restore the configured wallpaper if the user browsed away without applying.
            Wallpapers.cancelWallpaperPreview()
            wallpaperSelectionTarget = "main"
            wallpaperSelectorTargetMonitor = ""
            if (Config.options?.wallpaperSelector?.selectionTarget
                    && Config.options.wallpaperSelector.selectionTarget !== "main")
                Config.setNestedValue("wallpaperSelector.selectionTarget", "main")
            if (Config.options?.wallpaperSelector?.targetMonitor)
                Config.setNestedValue("wallpaperSelector.targetMonitor", "")
        }
    }
    property bool cheatsheetOpen: false
    property bool coverflowSelectorOpen: false
    onCoverflowSelectorOpenChanged: {
        if (!coverflowSelectorOpen) {
            wallpaperSelectionTarget = "main";
            wallpaperSelectorTargetMonitor = "";
            if (Config.options?.wallpaperSelector?.selectionTarget &&
                Config.options.wallpaperSelector.selectionTarget !== "main") {
                Config.setNestedValue("wallpaperSelector.selectionTarget", "main")
            }
            if (Config.options?.wallpaperSelector?.targetMonitor) {
                Config.setNestedValue("wallpaperSelector.targetMonitor", "")
            }
        }
    }
    property bool controlPanelOpen: false
    // Atoll: screen-local geometry ({x, y, width, height, radius, screen}) of the
    // Island part that last opened a surface, so it can morph out of and back
    // into that exact shape. Transient coordination only; null means "no origin".
    property var atollMorphOrigin: null
    // Who published that origin when it is not the Island (e.g. "left" for a
    // side panel's button). The Island leaves a foreign origin alone on open and
    // close; the morph surface clears it once it has fully collapsed.
    property string atollMorphOwner: ""
    // True while a surface is mid-morph out of or back into that origin; the
    // Island hides the published part so only one shape is ever on screen.
    // Atoll intent preloading: the pointer resting on the Island (controls) or an
    // expanded Island (settings) instantiates those surfaces hidden, so the
    // morph starts on the click frame instead of after an async load.
    property bool atollControlsWarm: false
    // Asks the focused Island to open a page ("media", "desktop", "activity",
    // "tray", "tools") from a surface that is not the Island (card, floating bubble).
    property string atollIslandPageRequest: ""
    // A bubble's own card: { kind, x, y, width, height, radius, screen, source }
    // with the screen-local rect of the bubble it grows out of; `source` names
    // that bubble ("island-<slot>" or "float-<slot>") so it can hide meanwhile.
    property var atollBubbleCard: null
    // The Island's desktop page is being arranged in place (Atoll Studio).
    property bool atollArrange: false
    // The Dock's body per output, so the chassis field draws it in the same pass
    // as the frame and the Island instead of the Dock carrying a second surface.
    property var atollDockBody: ({})
    // Atoll is being edited in place: every piece is grabbable, the edit bar
    // holds the pieces, the look and the sizes, and Done ends it.
    // Arranging the Control Center in place; closing the panel ends it.
    property bool atollControlEdit: false
    property string atollControlTab: "controls"
    // The lock screen rehearsal: the same surface, editable, with no PAM behind it.
    property bool atollLockEdit: false
    property string atollLockSelection: ""
    // The quick-controls tab `lunana atoll lock select:<key>/<tab>` asks the selected lock widget to show.
    property string atollLockWidgetTab: ""
    property string atollLockPage: "scene"
    property bool atollEdit: false
    // What the edit bar is inspecting: a piece slot ("extra:vitals", "left",
    // "app:kitty"), a surface ("island", "dock", "cards"…) or "" for the family.
    property string atollEditSelection: ""
    // A Studio target the edit bar should inspect ("" = keep what it shows).
    property string atollEditTarget: ""
    property int atollChassisEpoch: 0
    onIrisEditChanged: {
        if (!atollEdit) { atollEditSelection = ""; atollEditTarget = "" }
        else if (widgetEditMode) setWidgetEditMode(false)
        if (atollEdit && atollStudioOpen) atollStudioOpen = false
    }
    onIrisEditSelectionChanged: if (atollEditSelection.length > 0) atollEditTarget = ""
    onIrisEditTargetChanged: if (atollEditTarget.length > 0) atollEditSelection = ""
    // The in-place editors belong to Atoll: leaving the family ends them, or they are destroyed open and
    // come back open when the family does.
    function endIrisEditing(): void {
        atollLockEdit = false
        atollEdit = false
        atollControlEdit = false
    }
    onControlPanelOpenChanged: if (!controlPanelOpen) atollControlEdit = false
    onIrisControlEditChanged: if (!atollControlEdit) atollControlTab = "controls"
    // Atoll Studio, the panel form of Customize, is open. It and Customize on the shell never show together.
    property bool atollStudioOpen: false
    onIrisStudioOpenChanged: if (atollStudioOpen && atollEdit) atollEdit = false
    // Customize, in the form the person chose (atoll.appearance.customize), on a target ("" = where it was).
    function openIrisCustomize(target): void {
        const wanted = String(target ?? "")
        if (String(Config.options?.atoll?.appearance?.customize ?? "shell") === "studio") {
            atollStudioTarget = wanted
            atollStudioOpen = true
        } else {
            atollEditTarget = wanted
            atollEdit = true
        }
    }
    // A target Studio should show when it opens or is already open ("" = keep).
    property string atollStudioTarget: ""
    // The `source` of the card on screen (kept while it collapses), "" when none.
    // Asks whichever bubble shows this kind (floating first, then the Island)
    // to open its card; IPC and keyboard paths use it.
    property string atollBubbleCardRequest: ""
    // A floating piece asked to open its own menu, by kind (IPC).
    property string atollBubbleMenuRequest: ""
    // A bubble being carried: { slot, kind, screen, x, y (screen-local centre),
    // size, released }. The bubble layer draws it and resolves the drop.
    property var atollBubbleDrag: null
    // Per output name: what each bubble slot shows ({ left, right, utility }) and
    // the resting Island's screen-local geometry, published by each Island.
    property var atollBubbleKinds: ({})
    property var atollIslandGeometry: ({})
    // Per output: pieces an edge owner carries instead of floating over it ({ island: [...], dock: [...] }).
    property var atollAbsorbed: ({})
    property bool atollSettingsWarm: false
    // Atoll side panel ("left"/"right") that was revealed by resting at its screen
    // edge: it closes when the pointer leaves until a press inside commits it.
    property string atollSidebarPeek: ""
    // Atoll Dock held on screen by IPC (`lunana atoll dock show`) until hidden again
    // or an app is chosen from it.
    property bool atollDockShown: false
    // Opens an app's windows or menu on the focused Dock: { appId, mode: "windows" | "menu" }.
    property var atollDockMenuRequest: null
    property var atollDockSlide: null
    property var atollDockHome: null
    // A query for Spotlight to type as it opens (IPC); taken and cleared by the palette.
    property string atollSpotlightQuery: ""
    // Orbit (Atoll): Niri's workspaces and windows as a place to find and go. `atollOrbitQuery` is what it types as it opens.
    property bool atollOrbitOpen: false
    property string atollOrbitQuery: ""
    // The output Orbit opened on when a hot corner asked for one; empty means the focused output. It stays put until the
    // next open, so a leaving Orbit is not pulled to another output.
    property string atollOrbitOutput: ""
    property bool _irisOrbitOutputAsked: false
    // The corner each output's Orbit hot corner is on right now ("" = none), published by the corner itself.
    property var atollOrbitCorners: ({})
    function openIrisOrbit(outputName: string): void {
        atollOrbitOutput = outputName
        _irisOrbitOutputAsked = true
        atollOrbitOpen = true
    }
    onIrisOrbitOpenChanged: {
        if (!atollOrbitOpen) return
        if (!_irisOrbitOutputAsked) atollOrbitOutput = ""
        _irisOrbitOutputAsked = false
        searchOpen = false
        wallpaperSelectorOpen = false
        wallpaperLauncherOpen = false
    }
    // Desktop widget manager toggle routed to the output that should show it.
    signal desktopWidgetManagerToggleRequested(string outputName)
    // The Atoll desktop menu opened at a point of an output (`lunana atoll desktopMenu`).
    signal atollDesktopMenuRequested(string outputName, real x, real y)
    // Whether any output's Island is expanded, published for `lunana atoll status`.
    property bool atollIslandExpanded: false
    property string atollIslandShape: ""
    property string atollControlPickerRequest: ""
    property string atollIslandPage: ""
    property bool dashboardOpen: false
    property bool workspaceShowNumbers: false
    property var activeBooruImageMenu: null  // Track which BooruImage has its menu open
    property var activeTaskViewMenu: null  // Track which WindowThumbnail has its menu open
    // Slate-specific states
    property bool searchOpen: false
    property bool slateActionCenterOpen: false
    property bool slateNotificationCenterOpen: false
    property bool slateWidgetsOpen: false
    property bool slateAltSwitcherOpen: false
    property bool slateClipboardOpen: false
    property bool slateTaskViewOpen: false
    // Panel family transition animation state
    property bool familyTransitionActive: false
    property string familyTransitionDirection: "left" // "left" = current exits left, new enters from right
    property string familyTransitionTarget: ""

    signal requestRipple(real x, real y, string screenName)

    // User-configured fallback for singular panels such as wallpaper pickers.
    // Empty string uses the first available Quickshell screen.
    readonly property var primaryScreen: {
        const name = Config.options?.display?.primaryMonitor ?? ""
        if (name.length > 0) {
            const s = Quickshell.screens.find(scr => scr.name === name)
            if (s) return s
        }
        return Quickshell.screens[0]
    }

    // Focus-following screen for singular interactive surfaces. Keep this
    // separate from primaryScreen: the latter is a user fallback, while this
    // follows the compositor and only falls back when focus cannot be resolved.
    readonly property var focusedScreen: {
        let name = ""
        if (CompositorService.isNiri)
            name = NiriService.currentOutput ?? ""
        else if (CompositorService.isHyprland)
            name = Hyprland.focusedMonitor?.name ?? ""
        return Quickshell.screens.find(screen => (screen?.name ?? "") === name)
            ?? root.primaryScreen
            ?? Quickshell.screens[0]
            ?? null
    }

    function connectedOutputNames(allowedOutputs): var {
        const connected = Quickshell.screens
            .map(screen => String(screen?.name ?? ""))
            .filter(name => name.length > 0)
        if (!Array.isArray(allowedOutputs) || allowedOutputs.length === 0)
            return connected
        const enabled = connected.filter(name => allowedOutputs.includes(name))
        return enabled.length > 0 ? enabled : connected
    }

    function resolveOutputName(requestedOutput, allowedOutputs): string {
        const names = root.connectedOutputNames(allowedOutputs)
        if (names.length === 0)
            return ""
        const requested = String(requestedOutput ?? "")
        if (requested.length > 0 && names.includes(requested))
            return requested
        const focused = String(root.focusedScreen?.name ?? "")
        if (focused.length > 0 && names.includes(focused))
            return focused
        const primary = String(root.primaryScreen?.name ?? "")
        if (primary.length > 0 && names.includes(primary))
            return primary
        return names[0]
    }

    readonly property string overviewPresentationOutput:
        root.resolveOutputName(root.overviewTargetOutput, [])
    readonly property var sidebarScreenList: (Config.options?.panelFamily ?? "drift") === "atoll"
        ? [] : (Config.options?.sidebar?.screenList ?? [])
    readonly property string sidebarLeftPresentationOutput:
        root.resolveOutputName(root.sidebarLeftTargetOutput,
            root.sidebarScreenList)
    readonly property string sidebarRightPresentationOutput:
        root.resolveOutputName(root.sidebarRightTargetOutput,
            root.sidebarScreenList)

    function openOverview(outputName): void {
        overviewMode = "default"
        overviewTargetOutput = root.resolveOutputName(outputName, [])
        overviewOpen = true
    }

    function closeOverview(): void {
        overviewOpen = false
        orbitPocketRequested = false
        orbitStudioRequested = false
        orbitLensRequested = false
        orbitLensRequestedQuery = ""
        orbitStageOverride = ""
        orbitRuntimeStatus = ({ open: false })
    }

    function toggleOverview(outputName): void {
        const resolved = root.resolveOutputName(outputName, [])
        if (overviewOpen && overviewMode === "default" && overviewPresentationOutput === resolved)
            root.closeOverview()
        else
            root.openOverview(resolved)
    }

    function openOrbit(outputName): void {
        if (!CompositorService.isNiri || !(Config.options?.orbit?.enable ?? true))
            return
        overviewMode = "orbit"
        overviewSearchPrefix = ""
        overviewTargetOutput = root.resolveOutputName(outputName, [])
        overviewOpen = true
    }

    function openOrbitView(outputName, view: string): void {
        if (!CompositorService.isNiri || !(Config.options?.orbit?.enable ?? true))
            return
        orbitStageOverride = view === "orbital" ? "orbital" : "stage"
        root.openOrbit(outputName)
    }

    function openOrbitPocket(outputName): void {
        if (!CompositorService.isNiri)
            return
        orbitPocketRequested = true
        root.openOrbit(outputName)
    }

    function openOrbitStudio(outputName): void {
        if (!CompositorService.isNiri)
            return
        orbitStudioRequested = true
        root.openOrbit(outputName)
    }

    function openOrbitLens(outputName, query: string): void {
        if (!CompositorService.isNiri)
            return
        orbitLensRequestedQuery = query
        orbitLensRequested = true
        root.openOrbit(outputName)
    }

    function toggleOrbit(outputName): void {
        const resolved = root.resolveOutputName(outputName, [])
        if (overviewOpen && overviewMode === "orbit" && overviewPresentationOutput === resolved)
            root.closeOverview()
        else
            root.openOrbit(resolved)
    }

    function toggleOrbitStageView(): void {
        if (!overviewOpen || overviewMode !== "orbit")
            return
        const configured = Config.options?.orbit?.stageMode === "orbital" ? "orbital" : "stage"
        const current = orbitStageOverride.length > 0 ? orbitStageOverride : configured
        orbitStageOverride = current === "orbital" ? "stage" : "orbital"
    }

    function openTaskView(outputName): void { root.openOrbit(outputName) }
    function toggleTaskView(outputName): void { root.toggleOrbit(outputName) }

    function openSidebarLeft(outputName): void {
        if (Config.options?.panelFamily === "atoll" && !(Config.options?.atoll?.sidebars?.left?.enable ?? true)) return
        sidebarLeftTargetOutput = root.resolveOutputName(outputName,
            root.sidebarScreenList)
        sidebarLeftOpen = true
    }

    function closeSidebarLeft(): void {
        sidebarLeftOpen = false
    }

    function toggleSidebarLeft(outputName): void {
        const resolved = root.resolveOutputName(outputName,
            root.sidebarScreenList)
        if (sidebarLeftOpen && sidebarLeftPresentationOutput === resolved)
            root.closeSidebarLeft()
        else
            root.openSidebarLeft(resolved)
    }

    function openSidebarRight(outputName): void {
        if (Config.options?.panelFamily === "atoll" && !(Config.options?.atoll?.sidebars?.right?.enable ?? true)) return
        sidebarRightTargetOutput = root.resolveOutputName(outputName,
            root.sidebarScreenList)
        sidebarRightOpen = true
    }

    function closeSidebarRight(): void {
        sidebarRightOpen = false
    }

    function toggleSidebarRight(outputName): void {
        const resolved = root.resolveOutputName(outputName,
            root.sidebarScreenList)
        if (sidebarRightOpen && sidebarRightPresentationOutput === resolved)
            root.closeSidebarRight()
        else
            root.openSidebarRight(resolved)
    }

    onOverviewOpenChanged: {
        if (overviewOpen && overviewTargetOutput.length === 0)
            overviewTargetOutput = root.resolveOutputName("", [])
    }

    onSidebarLeftOpenChanged: {
        if (sidebarLeftOpen && sidebarLeftTargetOutput.length === 0)
            sidebarLeftTargetOutput = root.resolveOutputName("",
                root.sidebarScreenList)
    }

    // Close other slate popups when one opens (unless allowMultiplePanels is enabled)
    property bool _allowMultiple: Config.options?.slate?.behavior?.allowMultiplePanels ?? false
    onSearchOpenChanged: {
        if (searchOpen) atollOrbitOpen = false
        if (searchOpen && !_allowMultiple) {
            slateActionCenterOpen = false
            slateNotificationCenterOpen = false
            slateWidgetsOpen = false
            slateClipboardOpen = false
        }
    }
    onSlateActionCenterOpenChanged: {
        if (slateActionCenterOpen && !_allowMultiple) {
            searchOpen = false
            slateNotificationCenterOpen = false
            slateWidgetsOpen = false
            slateClipboardOpen = false
        }
    }
    onSlateNotificationCenterOpenChanged: {
        if (slateNotificationCenterOpen) {
            if (!_allowMultiple) {
                searchOpen = false
                slateActionCenterOpen = false
                slateWidgetsOpen = false
                slateClipboardOpen = false
            }
            // Mark notifications as read when opening notification center
            Notifications.timeoutAll();
            Notifications.markAllRead();
        }
    }
    onSlateWidgetsOpenChanged: {
        if (slateWidgetsOpen && !_allowMultiple) {
            searchOpen = false
            slateActionCenterOpen = false
            slateNotificationCenterOpen = false
            slateClipboardOpen = false
        }
    }
    onSlateClipboardOpenChanged: {
        if (slateClipboardOpen && !_allowMultiple) {
            searchOpen = false
            slateActionCenterOpen = false
            slateNotificationCenterOpen = false
            slateWidgetsOpen = false
            slateTaskViewOpen = false
        }
    }
    onSlateTaskViewOpenChanged: {
        if (slateTaskViewOpen && !_allowMultiple) {
            searchOpen = false
            slateActionCenterOpen = false
            slateNotificationCenterOpen = false
            slateWidgetsOpen = false
            slateClipboardOpen = false
        }
    }

    onSidebarRightOpenChanged: {
        if (sidebarRightOpen && sidebarRightTargetOutput.length === 0)
            sidebarRightTargetOutput = root.resolveOutputName("",
                root.sidebarScreenList)
        if (sidebarRightOpen) {
            Notifications.timeoutAll()
            Notifications.markAllRead()
        }
    }

    property real screenZoom: 1
    onScreenZoomChanged: {
        // Niri doesn't have native zoom support like Hyprland's cursor:zoom_factor
        // The IPC handler still works but zoom is Hyprland-only for now
        if (!CompositorService.isHyprland)
            return;
        Quickshell.execDetached(["hyprctl", "keyword", "cursor:zoom_factor", root.screenZoom.toString()]);
    }
    Behavior on screenZoom {
        animation: NumberAnimation { duration: Appearance.animation.elementMoveFast.duration; easing.type: Appearance.animation.elementMoveFast.type; easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve }
    }

    Loader {
        active: CompositorService.isHyprland
        sourceComponent: GlobalShortcut {
            name: "workspaceNumber"
            description: "Hold to show workspace numbers, release to show icons"

            onPressed: {
                root.superDown = true
            }
            onReleased: {
                root.superDown = false
            }
        }
    }

    IpcHandler {
		target: "zoom"

		function zoomIn(): void {
            screenZoom = Math.min(screenZoom + 0.4, 3.0)
        }

        function zoomOut(): void {
            screenZoom = Math.max(screenZoom - 0.4, 1)
        }
	}
}
