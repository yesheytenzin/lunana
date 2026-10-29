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
- [x] Cheatsheet: `HyprlandKeybinds` also parses Omarchy bindings.lua `o.bind` lines (lunana block included)

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
- [ ] Live-verify (nested): Audio, Network, Bluetooth, Weather, Battery,
      Brightness, Mpris, Notifications, Tray, KeyboardIndicators, multi-monitor
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
