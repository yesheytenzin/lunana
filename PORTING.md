# PORTING.md — living checklist (supersedes P01–P06)

> Governing process for full iNiR UI parity on Omarchy. Updated after every
> task so a fresh session resumes here. P01–P06 pixel-parity program is retired;
> `docs/panel-family-parity-plan.md`, `.audit/*parity*`, `codex/p01*` stay as
> history only.

Feature source: `/home/tenzin/development/inir` @ `2.33.0` (`48cdcec`).
Delivery: this repo (`lunana.*` plugin hosts + `lunana-suite` + `family-cycle`).
Vendored tree `vendor/` is never hand-edited — regenerate via `scripts/vendor.py`.

Verification always runs in the nested-Hyprland harness (`scripts/test/`),
against a fixture `$HOME` — never the live session.

## Wave 0 — harness + baseline [DONE]
- [x] Work landed on `main` (clean tree, all committed; the `lunana/parity` branch name in the plan was not used)
- [x] This file created
- [x] `scripts/test/nested-hypr` harness adopted (up/install/drive/shot/logs/down;
      session-7 adds `--monitors`, a Lua fixture, runtime-log discovery, and a clean `down`)
- [x] `scripts/hypr/lunana.conf` (layerrules for `lunana-*` namespaces)
- [x] Full re-vendor of the iNiR module/service/script set below
- [x] `lunana-suite --dry-run` + `tests/test_manifests.py` green

## Wave 1 — iNiR Hyprland-completion (inir checkout, then re-vendor)
- [x] Overview: Hyprland `OverviewWidget` path is the one in use (orbitMode falls back to it, no null stage); orbit mode on
      Hyprland uses the compositor-agnostic orbital stage (no `null` branch)
- [x] MRU tracker (new, compositor-agnostic) in CompositorService from Hyprland `activewindow` events
- [x] iRiS orbit host + MRU wiring; full OrbitOrbitalStage port remains (Niri-native internals)
- [x] Column keybind ops (Hyprland shims in CompositorService; nearest-behavior only): `CompositorService` Hyprland shims (`movefocus`,
      `movewindow`, `fullscreen`, `layoutmsg`, `resizeactive`)
- [x] GameMode: Hyprland fullscreen via IPC snapshot; animations via `hyprctl keyword animations:enabled`
- [x] Window previews: address-keyed Hyprland path (`grim -g` via capture-windows-hyprland.sh); Niri int path untouched
- [x] MinimizedWindows: Hyprland special-workspace minimize/restore (address-keyed side map)
- [x] Idle: Hyprland screen-off via `hyprctl dpms off/on` + brightness save/restore
- [x] Cheatsheet: `HyprlandKeybinds` parses Omarchy bindings.lua (proven: Keybinds (8)
      with the full Omarchy section in the nest; binds nested under children[0])

## Wave 2 — ii family parity (lunana hosts)
- [x] `lunana.bar` (bar, exists) — all styles: classic/islands/scenic/frame/pill/m3
- [x] `lunana.dock` (service, exists) — 4 positions + app icons
- [x] `lunana.overview` (overlay) — grid + search + calculator (flag host)
- [x] `lunana.sidebar-left` (overlay, exists) — AI chat, YT Music, translator, anime, Wallhaven, news, tools
- [x] `lunana.sidebar-right` (overlay, exists) — sliders/toggles/calendar/notifications
- [x] `lunana.control-center` (overlay)
- [x] `lunana.background` (service) — wallpaper + desktop widgets + items
- [x] `lunana.lock` (service; open() locks, close() is auth-owned no-op)
- [x] `lunana.osd` (service) — volume/brightness/layout
- [x] `lunana.cheatsheet` (overlay; reads Omarchy bindings.lua via Wave 1 parser)
- [x] `lunana.notifications` (service) — notification popup
- [x] `lunana.wallpaper` (overlay) — selector summoned; launcher resident
- [x] `lunana.region` (overlay) — screenshot/OCR/record
- [x] `lunana.session` (overlay) — session screen
- [x] `lunana.mascot` (service)
- [x] `lunana.altswitcher` (overlay; MRU order via Wave 1 tracker)
- [x] `lunana.tiling` (service) — tiling overlay
- [x] `lunana.closeconfirm` (overlay; Hyprland-native host around the vendored
  ii/waffle/iris dialog content — the vendored trigger/close path is
  niri-only, so the host snapshots the focused toplevel itself and closes
  via Omarchy's Lua dispatcher dialect)
- [x] `lunana.settings` (overlay; Loader-gated ApplicationWindow)

## Wave 3 — iRiS family parity
- [x] `lunana.iris` island mount (exists — interim direct `IrisIsland`)
- [x] Satellite hosts: background, palette, control, orbit, stage, dock, edit (interim), lock, notifications, settings
- [x] Satellite gaps filled (session-6): `lunana.iris-osd` (IrisOSD), `lunana.iris-session`
      (IrisSessionScreen), `lunana.iris-wallpaper` (IrisWallpaperPicker / galleryLoader),
      `lunana.iris-sidebar-left` + `-right` (IrisSidebar focus/today). Without these the
      iris family lost OSD/session/gallery/sidebars (the ii-owned set is stood down under
      iris). Registered in MANAGED_PLUGINS + family-cycle iris set + packaging; render +
      output-targeting to be proven in #4.
- [~] Full `IrisBar` chassis composition — **decided (operator, session-6): Option A, keep the
      satellite-plugin model.** The monolithic chassis is one PanelWindow fusing island+dock+
      control+spotlight+orbit+stage+edit+banners under a shared IrisField; it assumes iRiS owns
      the whole shell. Hosting it would retire every iris-* satellite and fork family-cycle.
      Kept satellites instead; single-surface blur-fusion + cross-surface morph recorded as
      reduced fidelity (and the .qsb blur shaders already fall back on this Qt anyway).
- [x] iRiS lock ownership per family: enforced by the mutually-exclusive family sets. Lock is
      NOT in SHARED (only state+family are); ii→`lunana.lock`, iris→`lunana.iris-lock`
      (IrisLockSurface), waffle→`lunana.waffle-lock`. Exactly one WlSessionLock host enabled at
      a time. Lock *open* stays untested by design (would lock the test session).

## Wave 4 — Waffle family (new)
- [x] `lunana.bar-waffle` (bar) + `wBar`
- [x] `lunana.waffle-start` (searchOpen), `-action`,
      `-notifications`, `-lock` (dormant), `-osd`, `-background`
- [x] `family-cycle` gains the `waffle` line (present: ii/waffle/iris/stock all wired in FAMILIES)

## Wave 5 — shared services, integrations, settings
- [x] `lunana.state` owns the `lunana` subtree (family, themeSource; default omarchy-tokens)
- [x] Material You opt-in wired: `lunana.state themeSource=material-you` arms inir
      `Config appearance.theme=auto` + `generateMaterialYou(path)` runs the vendored
      switchwall pipeline (proven: theme flips, switchwall exits 0). Default stays
      Omarchy tokens (untouched path). Full wallpaper-following needs the matugen
      toolchain present (generate logs the gap, degrades cleanly)
- [x] Un-defer integrations: `Ai`, `YtMusic`, `Wallhaven`, `AnimeService`/`Booru`
      instantiate with zero type/load errors in the nest (session-6). Live network/
      process exercise still manual (needs the external CLIs/keys present).
- [x] Nested harness proven live (2026-10-30, session 2): nested Hyprland + fixture $HOME +
      quickshell on fixture, `lunana-suite install` hermetic, `lunana.bar` active,
      `quickshell:bar/dock/background` layers up, `lunana.bar` active in listPlugins,
      overview summoned on demand (`shell toggle` → `quickshell:overview` layer).
      Zero `plugin load failed` lines after fixes (only benign warnings).
- [x] Verified in nest: bar (live data), dock, background, overview summon,
      cheatsheet summon + binds, zero load failures, hermetic install/uninstall
- [x] Live-verify (nested, session-6): Audio/Network/Bluetooth/Weather/Battery/
      Brightness/Mpris singletons init with no errors; iRiS bar shows live weather
      (7°C) + clock in the capture. Session-7 completed the residual per-overlay
      toggle matrix and the nested dual-output multi-monitor proof (below).
- [x] Settings: ii overlay summons with full nav + working Themes page (Color
      Themes gallery, tabs, filters) in the nest. Page components resolve against
      the registry module, not the shell root (inir fix, identical under inir)

## Wave 6 — interchange, keybinds, layerrules, packaging, docs
- [x] `lunana-suite`: all 44 managed plugins (45 including the dev probe); per-plugin vendor closures + root files + runtime script suffixes; hermetic fixture mode (LUNANA_FIXTURE=1)
- [x] `family-cycle`: `ii ↔ waffle ↔ iris ↔ stock`, exactly one family active (fixture-tested)
- [x] Keybinds: 8-surface additive set (plan §1.6); merged/removed by suite
- [x] Layerrules (`scripts/hypr/lunana.conf`) installed/removed by the suite
- [x] `packaging/package-metadata.json` (44 plugins + grim/slurp/wf-recorder/tesseract deps); `README.md` rewritten; stale
      P01–P06 references retired; `vendor/README.md` refreshed
- [x] `tests/test_manifests.py`: manifests + suite/family ownership + vendor-closure + family-cycle fixture test + suite smoke (vendor closure resolves) green

## Open questions / reduced fidelity (never silently dropped)
- Niri scrolling-column semantics → nearest Hyprland dispatcher (see §9 of plan).
- Default theme Omarchy tokens; Material You opt-in.
- `place-within-backdrop` dropped (no Hyprland analog).
- iRiS single-surface chassis fusion (one IrisField blurring island+dock+control+banners
  as one glass body, cross-surface morph) is not reproduced by the satellite-plugin model
  (Option A). Each iRiS surface is its own layer; `.qsb` blur shaders also fall back on this Qt.
- iRiS has no close-confirm / mascot / alt-switcher / tiling-overlay satellite: `IrisCloseConfirmContent`
  needs the chassis's close-intercept + `targetWindow`. The ii host now
  supplies that interception on Hyprland natively (snapshot + Lua-dialect
  close); mascot/altswitcher/tiling have no iRiS module (iRiS folds window
  switching into orbit/pieces). Recorded, not hosted.
- `org.kde.syntaxhighlighting` (KF6 `syntax-highlighting`) is a hard dependency of the vendored
  AiChat. The ii `sidebar-left` host now isolates that content in a separate compilation unit and
  opens a diagnostic fallback when the module is absent, so the overlay still summons and closes
  on every output. Full sidebar content (AI chat and the other tabs) needs the system QML module;
  the success path was verified with a temporary stub module.
- `wf-recorder` is absent on the verification host; region screenshot/OCR works (grim/slurp/
  tesseract), but region recording is untested.
- `matugen` is absent; Material You opt-in degrades cleanly by design (default Omarchy tokens needs
  nothing).
- Bulk wallpaper thumbnails prefer inir's venv (`$HOME/.local/state/quickshell/.venv`); without it
  the vendored ImageMagick fallback runs. Both scripts are vendored; the venv is an optional
  operator install.
- Live AI/YtMusic/Wallhaven/Anime network exercise needs API keys and the full `sidebar-left`
  content (blocked above); the services instantiate clean.
- Hosting blocked: none. The items above are environment-dependent verification
  gaps or documented reduced fidelity, not missing plugin hosts. If a surface
  cannot be hosted as an Omarchy plugin, record it here and ask the operator.

## Nested-session findings (2026-10-30, folded back into the tree)
- Install race: copying plugins straight into the plugin dir lets the host's
  watcher load half-written trees (bar fallback sticks). `copy_plugins` now
  builds in `.lunana-staging` and swaps per plugin. Proven: reinstall shows
  `lunana.bar active` with no fallback.
- Shell-entry handshake: vendored surfaces gate on
  `GlobalStates.shellEntryReady` (set only by inir's shell.qml). `lunana.state`
  now mirrors the minimal boot (200ms entry, 500ms deferred); theme/icon
  boots stay Omarchy's.
- `omarchy-plugin-enable/disable` drive the LIVE shell over IPC and ignore
  `XDG_CONFIG_HOME`. Fixture work sets `LUNANA_FIXTURE=1` and edits
  shell.json directly; `omarchy restart shell` is skipped in fixture mode.
- Layerrules need Hyprland >=0.53 syntax
  (`layerrule = <effects>, match:namespace <re>`); old `layerrule = blur, ns`
  and `shadows` are hard config errors (0.56.2 live). Vendored surfaces keep
  `quickshell:*` namespaces — one regex covers them.
- Hyprland `source = ~/.config/hypr/lunana.conf` glob-misses when the
  compositor's HOME differs; the suite writes the absolute path.
- Fixture shell.json needs `version: 1` or the host ignores bar.id/plugins.
- Benign/known: duplicate IpcHandler targets (per-plugin singleton copies —
  first wins); `.qsb` shaders fail to deserialize on this Qt (fallback
  rendering); `IrisStyle` FontLoader points at a host font dir that does not
  exist; mascot reads a host manifest path; stock `omarchy-background` stays
  up alongside lunana's (stand-down not implemented); per-plugin singleton
  universes diverge for cross-plugin GlobalStates reads (degrades to
  defaults; single shared vendor tree is future work).
- `lunana-suite sync --restart` in fixture mode skips the live shell restart.

## Session-2 corrections (2026-10-30)
- Hosts using ShellIpc MUST `import qs.Commons` (18 generated hosts fixed;
  static test added). `lunana.lock` service failure was the live signal.
- `lunana.family` (the switcher) was in no family set, so never enabled;
  SHARED is now `{lunana.state, lunana.family}`.
- Per-plugin singleton universes: each installed plugin carries its own
  vendor/ copy. The shell-entry handshake therefore runs in EVERY
  vendor-mounting host (36 hosts + bar + state), not just lunana.state.
- Open: bar first-paint still unverified (grim wedges while the fullscreen
  overview layer is up; repeated toggles can stack duplicate overview
  layers). Prime suspect remains entry gating; per-host handshake is now in
  the tree awaiting a calm-session re-shot.

## Session-3 corrections (2026-10-30)
- Cheatsheet sections must nest keybinds under `children[0]` (fixed + proven).
- Toggle calls execute but the client reply times out under load; layers are
  the source of truth for summon verification, not the client rc.
- Missing system dep: `org.kde.syntaxhighlighting` QML module (KF6) breaks
  vendored AiChat → sidebar-left content. Packaging + README list it.
- `lunana.lock` / service-direct IPC (`omarchy-shell <target>`) reports
  "Target not found" — the overlay summon path (`shell toggle <id>`) is the
  contract path and works; service-direct needs host-semantics check.
- Repeated toggles can stack duplicate overview layers (needs close-path look).
- Full 40-plugin suite holds ~35% of one core in the nest (per-plugin
  singleton/polling duplication); slim sets idle at 0.3%. Single shared
  vendor tree is the fix direction (correctness + performance).
- grim wedges while fullscreen ScreencopyView content is up; host-side
  `grim -g <nested window>` is the fallback capture path.

## Session-4 proofs (2026-10-30, shared-tree nest)
- Shared `lunana-vendor/` works: bar/dock/background/overview/cheatsheet/
  island all render from `../../lunana-vendor/...` imports; zero load
  failures on clean boot.
- Cross-plugin singleton sharing PROVEN: overview summon slid the bar away
  via `overviewOwnsEdge` (flag set in overview's plugin, read in bar's).
- Full family loop live: ii → waffle (wBar renders w/ live data) → iris
  (island renders, ii set stood down) → stock → ii (20 plugins, bar back).
- Cheatsheet Keybinds (8) from the suite-installed binds; integrations
  (Ai/YtMusic/Wallhaven/AnimeService) instantiate with zero errors.
- Duplicate IpcHandler warnings down to a handful (shared singletons).
- Fixture stays awake (host + inir idle off); idle lock that wedged session 2
  cannot recur.
- Remaining: service-direct IPC registration (lock) unverified by design
  (executing it locks the test session); overlay path is the contract path
  and works. Sidebar-left needs system `syntax-highlighting` (operator
  installs). Material You opt-in wiring still open.

## Session-5 corrections (2026-10-30)
- Settings pages resolved against `Quickshell.shellPath` (host root) — dead
  under Omarchy. Registry now anchors at its own module dir
  (`resolveComponent`); proven: Themes page gallery renders.
- `lunana.lock close` (no-op) runs clean → service ShellIpc registers fine;
  earlier "Target not found" was the stale unloaded-plugin era. Lock *open*
  untested by design (would lock the test session); summon path is the contract.
- Inir idle seed belongs in `illogical-impulse/config.json`, not `inir/`; the
  harness template is fixed. Inir also needs `syntax-highlighting` noted as
  a hard dep (provides org.kde.syntaxhighlighting for AiChat).

## Session-6 — "fix open" campaign (2026-10-30)
Working the four open buckets one by one.
- [x] #1 Record reconciled: work is on `main` (not `lunana/parity`);
      `family-cycle` waffle line confirmed present (checkboxes corrected above).
- [x] #2a Stock `omarchy.background` stand-down: `lunana-suite` now stands it
      down on install (mirrors the `omarchy.dock` stand-down) and restores it on
      uninstall, recorded via `backgroundWasEnabled`. Every lunana family ships
      its own background, so the stock one no longer double-renders underneath.
      Dry-run plan strings updated both sides.
- [x] #2b Material You `matugen` marked `optionalDependencies` in
      `packaging/package-metadata.json` (hard deps unchanged; default
      omarchy-tokens needs nothing; the pipeline already degrades cleanly).
- [x] #2c **Broad shellPath finding (root cause, not cosmetic):** the vendored
      tree calls `Quickshell.shellPath(X)` in **186** sites (fonts, mascot
      assets, translations, and the `scripts/inir` runtime + color/capture
      scripts). Omarchy plugins resolve own files via `Quickshell.env(
      "OMARCHY_PATH")` + subpath or `Qt.resolvedUrl(...)`; `Quickshell.shellPath`
      returns the **omarchy-shell root**, so every one of these resolves into
      Omarchy's tree where the file is absent. The `IrisStyle` FontLoader is the
      canary (fires on load → font fallback); scripts fail only when a feature
      invokes them (why the nest saw "instantiate with zero errors"). Session-5
      already fixed the settings-registry instance via a module-dir anchor
      (`resolveComponent`) — generalize that: a `scripts/vendor.py` lever rewrite
      of `Quickshell.shellPath(X)` → resolve against `~/.config/omarchy/
      lunana-vendor/` (XDG_CONFIG_HOME-aware for the fixture), then full
      re-vendor. Subtleties to prove in the nest (URL vs bare path for
      `FontLoader.source`, template-literal args, env handling) — so this fix is
      folded into #4 (live-verify), where the running nest can prove it.
- [x] #3 Un-defer iRiS (Option A, operator-chosen): kept the satellite model and
      filled its gaps — added iris-osd/-session/-wallpaper/-sidebar-left/-right (45
      plugins now, tests green). Per-family lock ownership confirmed enforced by the
      family sets. Full chassis fusion recorded as reduced (see Wave 3 + reduced list).
      Render/output-targeting of the new satellites to be proven in #4.
- [x] #2c shellPath lever fix LANDED + PROVEN. `scripts/vendor.py` gained
      `rewrite_shellpath()` (balanced-paren scanner, handles string / template /
      `${…}`-ternary args) wired into `vendor_path` + a `--shellpath` in-place
      mode; 102 vendored files rewritten so `Quickshell.shellPath(X)` resolves to
      `<XDG_CONFIG_HOME|~/.config>/omarchy/lunana-vendor/X`. Nest proof: font
      `Cannot load` errors 35→0, no new syntax errors, iRiS text renders in
      Inter/Rubik (screenshot). Covers all 186 sites (fonts, mascot assets,
      scripts/inir runtime, color/capture scripts).
- [x] #4 Live-verify pass (nested Hyprland, 2026-10-30, session-6): PROVEN —
      ii family (quickshell:bar/dock/background layers) and iRiS family (lunana-iris
      island + stacked clock + live weather 7°C + afterglow wallpaper, screenshot
      `/tmp/lunana-nested/shots/iris-family.png`) both render; the 5 new iris
      satellites load with ZERO load/type errors; Audio/Network/Bluetooth/Weather/
      Battery/Brightness/Mpris singletons init with no errors; Ai/YtMusic/Wallhaven/
      AnimeService instantiate clean; background stand-down confirmed (disabledPlugins
      = [omarchy.dock, omarchy.background]). Residual non-fatal: IrisLockStage reads
      an undefined lock-context at rest (lock open untested by design); ShellUpdates
      version.json absent in fixture. Session-7 completed the residual per-overlay
      toggle matrix and the nested dual-output multi-monitor proof.
- Harness fixes (landed + proven in session-7; see below): the nest must launch
  `quickshell` WITHOUT `-n`/`--no-duplicate` when a live shell runs the same config
  name, and must use an OMARCHY_PATH distinct from the live shell's; quickshell
  logs to its instance runtime dir
  (`/run/user/<uid>/quickshell/by-id/<id>/log.qslog`), not the redirect. The
  fixture now uses `hyprland.lua`, which removes the old `hyprland.conf:1` monitor
  line error (geometry no longer falls back).

## Session-7 — open-items campaign (2026-10-30)

First verified on Hyprland 0.56.2; after a host reboot/update the whole matrix was
re-run on Hyprland 0.57.0. Results below are the 0.57.0 run unless noted.

### Harness
- [x] Distinct nested shell: `up` copies `$OMARCHY_PATH/shell` to
      `/tmp/lunana-nested/omarchy/shell` (the rest of Omarchy is symlinked) and
      launches `quickshell -p <nested>/shell` **without** `-n`. With `-n` and the
      live `OMARCHY_PATH`, Quickshell treated the nest as a duplicate of the live
      shell. This unblocked every live check below.
- [x] Log discovery: Quickshell writes to its instance runtime dir
      (`/run/user/<uid>/quickshell/by-id/<id>/log.qslog`), not the launcher
      redirect. The harness finds the path through `/proc/<pid>/fd`; `logs` reads
      it with `quickshell log --tail`.
- [x] `up --monitors N`: creates `headless` outputs, applies the same
      `hl.monitor` geometry via `hyprctl eval`, and asserts the monitor count.
      Clean `up --monitors 2` gives `WAYLAND-1` + `HEADLESS-1` at 1920x1080.
- [x] Fixture uses `hyprland.lua` (`hl.monitor({...})`), matching live Omarchy;
      the old `hyprland.conf:1` monitor-line error is gone.
- [x] Runtime socket links: the nested `XDG_RUNTIME_DIR` gets symlinks to the
      host's `pipewire-0`, `pipewire-0-manager`, and `pulse`, so audio
      integrations exercise the real PipeWire stack (`wpctl status` connects).
- [x] `install` stops/restarts only the fixture shell (matched by fixture `HOME`
      in `/proc/<pid>/environ`); `restart`/`logs`/`shot` share the same path.
      `down` kills the compositor (Hyprland 0.56+ Lua no longer accepts legacy
      `dispatch exit`) and removes the fixture/nested Omarchy/runtime/env while
      keeping shots and logs.

### Suite/config
- [x] `lunana-suite` detects `hyprland.lua` first, else `hyprland.conf`; installs
      `lunana.lua` with an idempotent `dofile(<abs path>)` block (or `lunana.conf`
      with `source = ...`), backs up the entry file, and removes both fragments and
      load directives on uninstall. `tests/test_manifests.py::test_hypr_config_adapters`
      covers both adapters, idempotency, and removal.
- [x] `scripts/hypr/lunana.lua` mirrors the conf layerrules for Lua configs.
- [x] Install records `shell.json.lunana.family = <default>` (ii), so reinstalling
      over a waffle/iris session cannot leave `panelFamily` gated to a family whose
      plugins were just stood down.

### Product fixes
- [x] Waffle/iris background hosts: `WaffleBackground`/`IrisBackground` are bare
      `Variants`; their default property is `delegate`, so the handshake `Timer`
      child replaced the vendored `PanelWindow` delegate. Both hosts now wrap the
      vendored item in a `Scope` with the Timer as a sibling. Proven:
      `quickshell:wBackground` and `quickshell:iris-background` appear on both
      outputs.
- [x] Family switching: `family-cycle` writes `shell.json.lunana.family`;
      `lunana.state` mirrors it into the vendored `Config.options.panelFamily` on
      family/ready changes (`stock` keeps the last real family). Live
      ii→waffle→iris→stock→ii now works without a shell restart.
- [x] `lunana.iris-control` now drives the shared `controlPanelOpen`/
      `irisMorphOwner` state and passes `screenData` to the vendored
      `IrisControlCenter`. Previously the layer toggled but the morph surface
      rendered empty; the quick panel now has visible content.
- [x] `lunana.sidebar-left` degrades gracefully when the vendored AiChat cannot
      compile. The host no longer references `LSLeft.SidebarLeftContent` in its
      own compilation unit; a `Loader` loads `SidebarContent.qml` and shows a
      themed diagnostic panel on `Loader.Error`. The layer now opens and closes
      on both outputs without `org.kde.syntaxhighlighting`, and the diagnostic
      logs once per plugin instance. A static regression test
      (`test_sidebar_left_fallback`) pins the isolation. The success path (full
      panel, no fallback) was verified with a temporary stub QML module.

### Vendoring
- [x] `vendor/` regenerated via `scripts/vendor.py` for `go.mod`,
      `scripts/scan-widgets.sh`, `scripts/detect_sensors.py`,
      `scripts/clipboard-copy.sh`, `scripts/keyring/*`, and `scripts/thumbnails/*`
      (byte-identical to inir). The shellPath-rewritten callers now resolve;
      `IrisWashi` warning gone and `inir-washi` builds. Bulk wallpaper thumbnails
      use inir's venv when present and the vendored ImageMagick fallback otherwise.
- [x] `tests/test_manifests.py` rejects stale `vendor/` relative imports;
      `lunana.ui-probe` moved to `../../lunana-vendor/...`.
- [x] Packaging parity test added; `lunana.iris-wallpaper` was missing from
      `packaging/package-metadata.json` (now 44 managed plugins).

### Verification matrix (nested Hyprland 0.57.0, dual output)
- ii overlays open/close: overview, cheatsheet, control-center, sidebar-left
  (diagnostic fallback without `org.kde.syntaxhighlighting`), sidebar-right,
  wallpaper, region, session, settings, altswitcher, closeconfirm.
- ii `sidebar-left` shows its diagnostic panel instead of the vendored content
  because `org.kde.syntaxhighlighting` (KF6 `syntax-highlighting`) is not
  installed; with a temporary stub module the real panel renders on both
  outputs.
- ii `closeconfirm` is a Hyprland-native host around the vendored dialog
  content: it snapshots the focused toplevel at trigger time
  (`Hyprland.activeToplevel`, activated-scan, then a direct `hyprctl
  activewindow` query as fallback for stale IPC caches), shows the
  ii/waffle/iris variant by `panelFamily`, and closes via Omarchy's Lua
  dispatcher dialect (`hl.dsp.window.close`, since the socket's `dispatch`
  is `hl.dispatch(...)` shorthand and the upstream `closewindow address:…`
  form is a Lua syntax error there). Verified in the nest with a focused
  foot terminal: dialog shows title + app id, confirm kills the window,
  cancel/Escape dismisses with the window surviving,
  `closeConfirm.enabled=false` closes immediately with no dialog, and no
  focused window warns without opening.
- waffle: `wBackground` + waffle bar; `wStartMenu`, `wActionCenter`,
  `wNotificationCenter` open/close.
- iris: `lunana-iris` + `quickshell:iris-background`; control, edit, palette,
  stage, wallpaper, session, settings, sidebar-left, sidebar-right open/close.
- family cycle iris→stock→ii restores ii fully (`background`/`bar`/`dock`; no
  iris/waffle layers). Dual monitor: both outputs show background/bar/dock/
  notifications; control-center summoned on `WAYLAND-1`.
- Integrations: Network connected (`nmcli`), Bluetooth adapter present but
  `Powered: no`, Battery 81%, brightness 100%, PipeWire connected (`wpctl`),
  Weather 8°C, sensors detect CPU/GPU, keyring script returns `{}`,
  `scan-widgets.sh` returns `[]`. No missing-script warnings after the vendor
  additions (lock-surface/`version.json`/duplicate-IpcHandler warnings remain
  known reduced-fidelity noise).

Evidence: `/tmp/lunana-nested/shots/dual-monitor-ii.png`,
`overlay-iris-control.png`, `family-lunana.waffle-start.png`,
`sidebar-left-fallback-dual.png` (missing module → diagnostic on both
outputs), `sidebar-left-stub.png` (temporary stub module → full panel),
and `closeconfirm-dialog.png` (Hyprland-native close-confirm dialog over a
focused foot terminal, showing its title + app id with Cancel/Close);
the overlay matrices were recorded in `/tmp/lunana-nested/overlay-matrix.txt`
and re-run after the host update.
