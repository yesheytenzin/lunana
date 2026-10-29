# Lunana

A native plugin suite for the **Omarchy** (Quattro) shell that re-authors the
look, feel, and features of [inir](https://github.com/snowarch/inir) into
Omarchy's own long-lived Quickshell process — and is cleanly interchangeable
with the stock Omarchy bar.

> **Status: M0–M4 implemented and verified live on Omarchy `4.0.0.alpha`.**
> Bar (two styles), dock, overview, control center, and left sidebar all run as
> native plugins, swappable with stock, with keybinds and a transactional
> installer. Deep inir integrations (AI chat, YT Music, Material You, Wallhaven,
> anime tracker) are intentionally deferred — see "Deferred" below.

## How it works

Omarchy hosts plugins by `manifest.json` (`kinds`: `bar`, `bar-widget`,
`overlay`, `menu`, `panel`, `service`) inside one shell process. Lunana ships
`lunana.*` plugins. The active full bar is chosen by `~/.config/omarchy/shell.json`
→ `bar.id`; selecting `lunana.bar` deactivates the stock `omarchy.bar`, and
clearing it restores stock. Everything hot-reloads — no logout, no second
process, no `ShellRoot` of our own. A bar that fails to load falls back to the
stock bar automatically.

Lunana defers to Omarchy's theme tokens (`qs.Commons`) rather than running its
own color pipeline: Omarchy owns the hue, Lunana owns form and interaction.

## Try the swap

```bash
# validate + preview (writes nothing)
./scripts/lunana-suite install --dry-run

# swap the live bar to lunana (prompts first; hot-reloads)
./scripts/lunana-suite install

# after editing bar QML: re-copy + restart the shell (bar changes need a
# full restart — hot-reload reuses the running bar instance)
./scripts/lunana-suite sync

# check state
./scripts/lunana-suite status

# restore the stock Omarchy bar
./scripts/lunana-suite uninstall
```

The suite runs as your user, never calls pacman/sudo, never touches
`/usr/share/omarchy`, backs up `shell.json`, and writes it atomically.

## Layout

| Path | What |
|---|---|
| `lunana.bar/` | `kind: bar` host — the swap target; solid + floating island styles |
| `lunana.state/` | `kind: service` — shared state owner (placeholder) |
| `lunana.dock/` | `kind: service` — bottom dock of live Hyprland windows |
| `lunana.overview/` | `kind: overlay` — workspace + window overview |
| `lunana.control-center/` | `kind: overlay` — volume/brightness sliders + actions |
| `lunana.sidebar-left/` | `kind: overlay` — inir's exact left sidebar (tabs, widgets, AI chat) |
| `lunana.sidebar-right/` | `kind: overlay` — inir's exact right sidebar (sliders, toggles, calendar) |
| `lunana.family/` | `kind: service` — bar-family switcher (ii ↔ stock; waffle/iRiS plug in as one line) |
| `scripts/lunana-suite` | transactional install / sync / uninstall / status |
| `scripts/keybinds/lunana.lua` | Lua bind fragment merged into `bindings.lua` |
| `contracts/` | pinned host facade (`host-facade-v1.json`) |
| `packaging/aur/` | `PKGBUILD` + package metadata |
| `tests/` | manifest + suite smoke test (`python3 tests/test_manifests.py`) |

## Keybinds

Merged into `~/.config/hypr/bindings.lua` on install (removed on uninstall):

| Keys | Surface |
|---|---|
| `Super+Shift+O` | Overview |
| `Super+Shift+C` | Control Center |
| `Super+Shift+L` | Left Sidebar |
| `Super+Shift+R` | Right Sidebar |
| `Super+Shift+W` | Family Switch (ii ↔ stock) |

## Milestones — all verified live

- **M0 — swap proof** ✅: `lunana.bar` + `lunana.state` + `lunana-suite` that
  provably swaps stock ↔ lunana.
- **M1 — bar** ✅: live workspace pills (clickable), focused-window title,
  clock, date, themed from Omarchy tokens.
- **M2 — overview + dock + keybinds** ✅: `lunana.overview` (workspaces +
  windows, click to focus/switch), `lunana.dock` (live running apps), Lua
  keybinds merged into `bindings.lua`.
- **M3 — control center + left sidebar** ✅: live volume/brightness sliders
  (`wpctl`/`brightnessctl`) + actions; clock, live CPU/RAM stats, launchers.
- **M4 — polish** ✅: second bar style (floating island, `bar.lunana.floating`),
  pinned host-facade contract, AUR packaging, and a manifest/suite smoke test.

## Deferred (intentionally, not silently dropped)

These inir features are large external integrations left for later waves, not
part of M0–M4: AI chat, YT Music (InnerTube), Wallhaven browser, anime tracker,
the Material You color pipeline (lunana defers to Omarchy's theme tokens by
design), app icons in the dock, and multi-monitor-specific tuning.

## License

GPL-3.0 — inir is GPL-3.0, so anything ported from it keeps that license.
