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
- [ ] Overview: Hyprland `OverviewWidget` path is the one in use; orbit mode on
      Hyprland uses the compositor-agnostic orbital stage (no `null` branch)
- [ ] MRU tracker (new, compositor-agnostic) from Hyprland `activewindow` events
- [ ] iRiS orbit + workspace edge strip driven on Hyprland + MRU; `isNiri` gates dropped
- [ ] Column keybind ops: `CompositorService` Hyprland shims (`movefocus`,
      `movewindow`, `fullscreen`, `layoutmsg`, `resizeactive`)
- [ ] GameMode: fullscreen via Hyprland `fullscreen` field; animations via
      `hyprctl keyword animations:enabled`
- [ ] Window previews: key by `address` (hex); `grim -g` capture per client
- [ ] MinimizedWindows: Hyprland special workspace instead of Niri hidden trick
- [ ] Idle: extend the `isNiri`-gated screen-off branch to Hyprland (`dpms off`)
- [ ] Cheatsheet: verify `HyprlandKeybinds` parses the lunana-installed bind set

## Wave 2 — ii family parity (lunana hosts)
- [x] `lunana.bar` (bar, exists) — all styles: classic/islands/scenic/frame/pill/m3
- [x] `lunana.dock` (service, exists) — 4 positions + app icons
- [ ] `lunana.overview` (overlay) — grid + search + calculator
- [x] `lunana.sidebar-left` (overlay, exists) — AI chat, YT Music, translator, anime, Wallhaven, news, tools
- [x] `lunana.sidebar-right` (overlay, exists) — sliders/toggles/calendar/notifications
- [ ] `lunana.control-center` (overlay)
- [ ] `lunana.background` (service) — wallpaper + desktop widgets + items
- [ ] `lunana.lock` (service)
- [ ] `lunana.osd` (service) — volume/brightness/layout
- [ ] `lunana.cheatsheet` (overlay)
- [ ] `lunana.notifications` (service) — notification popup
- [ ] `lunana.wallpaper` (overlay) — launcher + selector
- [ ] `lunana.region` (overlay) — screenshot/OCR/record
- [ ] `lunana.session` (overlay) — session screen
- [ ] `lunana.mascot` (service)
- [ ] `lunana.altswitcher` (overlay)
- [ ] `lunana.tiling` (service) — tiling overlay
- [ ] `lunana.closeconfirm` (overlay)
- [ ] `lunana.settings` (overlay) — ii settings pages

## Wave 3 — iRiS family parity
- [x] `lunana.iris` island mount (exists — interim direct `IrisIsland`)
- [ ] Full composition: `IrisBar` chassis + morphing island + background/afterglow
- [ ] `IrisPalette` (launcher), control grid, stage, dock, edit mode, field/shaders
- [ ] iRiS lock, notifications/banners, settings pages (Compositor → Hyprland)
- [ ] Orbit + workspace strip on the Hyprland model (Wave 1)

## Wave 4 — Waffle family (new)
- [ ] `lunana.bar-waffle` (bar) + `wBar`
- [ ] `lunana.waffle-start` (start menu), `lunana.waffle-action`,
      `lunana.waffle-notifications`, `lunana.waffle-lock`/`-osd`, settings pages
- [ ] `family-cycle` gains the `waffle` line (one line + bar-host dir)

## Wave 5 — shared services, integrations, settings
- [ ] Material You opt-in (`scripts/colors/*` + `MaterialThemeLoader`;
      `lunana.state` theme-source flag; default stays Omarchy tokens)
- [ ] Un-defer integrations: `Ai`, `YtMusic`, `Wallhaven`, `AnimeService`/`Booru`
- [ ] Live-verify (nested): Audio, Network, Bluetooth, Weather, Battery,
      Brightness, Mpris, Notifications, Tray, KeyboardIndicators, multi-monitor
- [ ] Settings: every page in all three families loads; Compositor page shows
      Hyprland-relevant options or hides what Omarchy owns

## Wave 6 — interchange, keybinds, layerrules, packaging, docs
- [ ] `lunana-suite`: `MANAGED_PLUGINS` + `VENDOR_*` cover every new plugin
- [ ] `family-cycle`: `ii ↔ waffle ↔ iris ↔ stock`, exactly one family active
- [ ] Keybinds: every surface covered additively (`o.bind`, no Omarchy clobber)
- [ ] Layerrules: iNiR-owned sourced conf installed/removed by the suite
- [ ] `packaging/package-metadata.json` + AUR; `README.md` rewritten; stale
      P01–P06 references retired; `vendor/README.md` refreshed
- [ ] `tests/test_manifests.py` + suite smoke test (vendor closure resolves) green

## Open questions / reduced fidelity (never silently dropped)
- Niri scrolling-column semantics → nearest Hyprland dispatcher (see §9 of plan).
- Default theme Omarchy tokens; Material You opt-in.
- `place-within-backdrop` dropped (no Hyprland analog).
- Blocked: none. If a surface cannot be hosted as an Omarchy plugin, record it
  here with the reason and ask the operator.
