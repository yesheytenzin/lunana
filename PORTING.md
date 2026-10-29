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
- [x] Branch `lunana/parity`
- [x] This file created
- [x] `scripts/test/nested-hypr` harness adopted (up/install/drive/shot/logs/down)
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
- [x] `lunana.closeconfirm` (overlay; vendored trigger falls back to `niri msg` — no Hyprland analog yet)
- [x] `lunana.settings` (overlay; Loader-gated ApplicationWindow)

## Wave 3 — iRiS family parity
- [x] `lunana.iris` island mount (exists — interim direct `IrisIsland`)
- [x] Satellite hosts: background, palette, control, orbit, stage, dock, edit (interim), lock (dormant), notifications, settings
- [ ] Full `IrisBar` chassis composition (deferred: chassis assumes iRiS owns the whole shell)
- [ ] iRiS lock ownership per family (enforced by family-cycle sets; default ii lock stays unless iris active)

## Wave 4 — Waffle family (new)
- [x] `lunana.bar-waffle` (bar) + `wBar`
- [x] `lunana.waffle-start` (searchOpen), `-action`,
      `-notifications`, `-lock` (dormant), `-osd`, `-background`
- [ ] `family-cycle` gains the `waffle` line (one line + bar-host dir)

## Wave 5 — shared services, integrations, settings
- [x] `lunana.state` owns the `lunana` subtree (family, themeSource; default omarchy-tokens)
- [ ] Material You opt-in wiring (vendored `scripts/colors/*` + `MaterialThemeLoader`; default stays Omarchy tokens)
- [ ] Un-defer integrations: `Ai`, `YtMusic`, `Wallhaven`, `AnimeService`/`Booru`
- [x] Nested harness proven live (2026-10-30, session 2): nested Hyprland + fixture $HOME +
      quickshell on fixture, `lunana-suite install` hermetic, `lunana.bar` active,
      `quickshell:bar/dock/background` layers up, `lunana.bar` active in listPlugins,
      overview summoned on demand (`shell toggle` → `quickshell:overview` layer).
      Zero `plugin load failed` lines after fixes (only benign warnings).
- [x] Verified in nest: bar (live data), dock, background, overview summon,
      cheatsheet summon + binds, zero load failures, hermetic install/uninstall
- [ ] Live-verify (nested) per surface (remaining): Audio, Network, Bluetooth, Weather,
      Battery, Brightness, Mpris, Notifications, Tray, KeyboardIndicators,
      multi-monitor; toggle each overlay, capture, confirm live data
- [ ] Settings: every page in all three families loads; Compositor page shows
      Hyprland-relevant options or hides what Omarchy owns

## Wave 6 — interchange, keybinds, layerrules, packaging, docs
- [x] `lunana-suite`: all 40 plugins; per-plugin vendor closures + root files + runtime script suffixes; hermetic fixture mode (LUNANA_FIXTURE=1)
- [x] `family-cycle`: `ii ↔ waffle ↔ iris ↔ stock`, exactly one family active (fixture-tested)
- [x] Keybinds: 8-surface additive set (plan §1.6); merged/removed by suite
- [x] Layerrules (`scripts/hypr/lunana.conf`) installed/removed by the suite
- [x] `packaging/package-metadata.json` (39 plugins + grim/slurp/wf-recorder/tesseract deps); `README.md` rewritten; stale
      P01–P06 references retired; `vendor/README.md` refreshed
- [x] `tests/test_manifests.py`: manifests + suite/family ownership + vendor-closure + family-cycle fixture test + suite smoke (vendor closure resolves) green

## Open questions / reduced fidelity (never silently dropped)
- Niri scrolling-column semantics → nearest Hyprland dispatcher (see §9 of plan).
- Default theme Omarchy tokens; Material You opt-in.
- `place-within-backdrop` dropped (no Hyprland analog).
- Blocked: none. If a surface cannot be hosted as an Omarchy plugin, record it
  here with the reason and ask the operator.

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
