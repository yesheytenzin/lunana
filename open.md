# Lunana — open items (2026-10-30, sessions 7–10)

Sessions 7–10 closed: the nested harness, the full ii/waffle/iris overlay
matrices, live family switching, dual-monitor behavior, the iris satellite
completion, the Hyprland orbit backend (list + actions), and the
untestable-harness items (OSD, banners incl. bus ingress, PAM both
branches, wake-word-free recording path) are proven on Hyprland 0.57.0.
What remains is upstream decisions and documented environment quirks.

## Graceful fallback (host works without the dependency)
- `lunana.sidebar-left` now opens, closes, and shows a diagnostic panel when
  the vendored sidebar cannot compile because `org.kde.syntaxhighlighting`
  is missing. The overlay layer appears on every output; the fallback names
  the missing module and stays click-to-close. Install `syntax-highlighting`
  to get the full panel. The success path (real content, no fallback) was
  verified with a temporary stub QML module.

## Proven since (operator installed the missing packages)
- `syntax-highlighting` is installed: the full `lunana.sidebar-left` content
  (widgets tab, clock, weather, calendar, toggles, rings) renders with no
  fallback and zero QML errors (`sidebar-full-syntax.png`). The graceful
  fallback stays for systems without it.
- `wf-recorder` is installed: the region-record path launches correctly —
  `vendor/scripts/lib` was missing from the vendor tree (added via
  `scripts/vendor.py`), and inir's `record.sh` passed a bare `-t` that no
  current wf-recorder accepts (`invalid option -- 't'`). Both fixed (see
  below); silent recording starts cleanly with valid args on wf-recorder
  0.6.0. mp4 finalization cannot complete in the nest: wf-recorder, like
  grim on WAYLAND-1, stalls waiting for compositor frames that never arrive
  (same screencopy stall, both outputs affected for capture clients). Sound
  mode additionally needs newer wf-recorder flags (`-R`/`-C`/`--audio-backend`
  absent from 0.6.0).
- inir `record.sh` `-t` fix: two bare-`-t` lines removed in the inir checkout
  (`/home/tenzin/development/inir`, left uncommitted — upstream bug, their
  call) and re-vendored via `scripts/vendor.py scripts/videos/record.sh`.

## Still blocked (operator action or newer packages needed)
- `matugen`: absent; Material You opt-in degrades cleanly. It is an optional
  dependency; the default Omarchy-tokens path needs nothing.
- inir thumbnail venv (`$HOME/.local/state/quickshell/.venv`): absent; bulk
  wallpaper thumbnails use the vendored ImageMagick fallback. Optional.
- wf-recorder sound mode: 0.6.0 lacks `-R`/`-C`/`--audio-backend`; needs a
  newer wf-recorder for the script's audio args.

## Needs credentials / live services
- AI, YtMusic, Wallhaven, and AnimeService network exercise needs API keys
  and the full `sidebar-left` content (blocked above). All services
  instantiate with zero errors in the nest.

## iRiS family — fully verified (nested Hyprland 0.57.0, dual output)
- Resident services render on both outputs with zero QML errors: `lunana-iris`
  (island pill + clock/wifi), `lunana.iris-dock` (dock pill + icons),
  `quickshell:iris-background` (wallpaper).
- All 9 overlays + orbit open/close with visible inir-exact content: control
  grid, edit bar, palette spotlight, stage (empty by default — correct; a
  placed clock bubble renders), session screen, settings window,
  focus/today sidebars, wallpaper gallery, orbit chrome.
- Host fixes (all host-side, no vendor edits): per-output `IrisField` behind
  every shape-publishing piece (island/dock/control/stage/edit), host
  PanelWindow for the windowless dock, `fill` loaders + required props/state
  for stage/edit/control/palette, orbit surface + toggle, and full-`Lock`
  hosts for iris/waffle lock (bare surfaces fail creation without `context`).
- Test-only IPC hooks (clearly labeled, no product behavior change):
  `lunana.iris-osd test [kind]` drives the OSD render path;
  `lunana.iris-notifications test` injects a wrapper-shaped synthetic entry
  into the `popupList` the banner delegates read (second call clears).
  Static tests pin both hooks.

## Reduced fidelity (documented, not defects — verified workarounds below)
- Orbit on Hyprland, Phase 1 landed: `lunana.state` now mirrors Hyprland
  toplevels/workspaces into NiriService's `windows`/`allWorkspaces`/
  `mruWindowIds` shape (small stable int ids per address — raw address hex
  overflows QML's 32-bit `int` consumers — dormant unless
  Hyprland-without-Niri), and the orbit renders workspace strips with live
  window cards on Hyprland (`iris-orbit-hyprland-mirror.png`).
- Orbit on Hyprland, Phase 2 landed: new `vendor-patches/` lever
  (`scripts/vendor.py --patch`, idempotent, fails loudly on drift) applies
  `services/NiriService.qml.patch`, routing closeWindow/focusWindow/
  moveWindowToWorkspaceById/switchToWorkspaceById through Omarchy's Lua dsp
  dialect and intercepting ToggleWindowFloating in `send()`. Verified live
  with explicit baselines: go-to focuses the searched window, Del closes it
  (correct window dies, survivor keeps working), Ctrl+F toggles floating.
  toggleOverview stays Niri-only (its analog is lunana.overview, unreachable
  from vendored code). Niri paths are byte-identical (branches only).
- OSD volume trigger: external `wpctl` changes do not reach the OSD because
  `showLevel` requires a recent `Audio.lastUserChange`, which only the
  `audio` IPC path sets (`qs ipc --pid <nested-shell> call audio volumeUp`
  hits the vendored handler — no omarchy `audio` target shadows it). Proven
  in the nest via `lunana.iris-osd test volume`: the glass volume pill renders
  exactly like inir. The Audio→OSD signal wiring itself is untouched vendored
  code.
- Notification banners: fully proven, two ways. (1) `lunana.iris-notifications
  test` injects a wrapper-shaped synthetic entry (second call clears) — fast
  regression path, full banner pixel-verified. (2) Real bus ingress: run the
  nested shell on a private session bus (`dbus-daemon --session`, point a
  manually-started nested shell's `DBUS_SESSION_BUS_ADDRESS` at it, revert
  afterwards) and `notify-send` reaches the nested server, which owns the
  name there (`iris-notif-bus-ingress.png`). The shared-bus limitation
  stands for the default harness (host owns the name there).
- Lock *open*: proven both branches in the nest. Wrong password shows the red
  "Incorrect password" via a real PAM round trip (stock behavior preserved
  with the patch applied, `iris-lock-failure.png`). With
  `LUNANA_TEST_PAM_UNLOCK=1` in the operator's environment, the harness
  passes it through (`nested-hypr` documents this as test-only) and the
  vendored `LockContext` uses a fixture-local `pam_permit` service instead of
  the system stack: any input unlocks, the desktop returns with no restart
  and no `clear_crashed_lockscreen` dance (`iris-lock-unlocked.png`). Never
  set the flag outside the nest. PAM against real credentials stays
  off-limits by design (the restart+eval recovery path remains documented
  as the no-flag fallback).
- iRiS single-surface chassis fusion is not reproduced by the satellite model
  (Option A). The known lock-surface, missing `version.json`, and duplicate
  `IpcHandler` warnings remain as recorded in PORTING.md.

## Proven this session
- Harness: distinct nested shell without `-n`, runtime `log.qslog` discovery,
  `up --monitors 2`, Lua fixture, clean `down`, and host PipeWire sockets
  linked into the nested runtime.
- ii overlays: 11/11 open/close (sidebar-left: full content verified with
  `syntax-highlighting` installed; diagnostic fallback stands without it;
  closeconfirm is a Hyprland-native host around the vendored dialog content);
  waffle: 3/3; iris: 9/9 overlays + orbit open/close (including visible
  `lunana.iris-control` content).
- Family cycle `ii ↔ waffle ↔ iris ↔ stock` live without a shell restart;
  dual-monitor layers (background/bar/dock/notifications) on both outputs.
- OSD pill, notification banner (synthetic + real bus ingress), lock open +
  lock failure + PAM-success unlock (gated fixture path), recording launch
  path, sidebar full content, and Hyprland orbit window list + actions
  (go-to, close, float toggle) proven with screenshots and explicit
  baselines; static tests pin the hooks, the orbit Niri-shape contract,
  and the vendor-patch lever (`test_iris_test_hooks`,
  `test_hypr_windows_contract`, `test_vendor_patch_lever`).
- ii family full pass (this session): 11/11 overlays open/close with
  per-step layer verification — overview (workspace cards on focused
  output), cheatsheet, control-center (`controlPanel`), sidebar-right,
  wallpaper (`wallpaperSelector`), region (`regionSelector`), session,
  settings (`settingsOverlay`), altswitcher (scrim + layer; card list
  shares the orbit-proven mirror model), sidebar-left
  (`lunana-sidebar-left`, full widget content), closeconfirm (dialog with
  icon/title/Cancel/Close over a focused foot; Cancel keeps the window,
  disabled-config fast path closes directly) — plus residents (bar, dock,
  background on both outputs), OSD pill via the natural `audio volumeUp`
  path (fast layer polling — the pill auto-hides after 1.5s, which is why
  slow checks miss it), and banner via real private-bus ingress
  (`ii-notif-banner.png`). Lock/mascot/tiling verified dormant +
  error-free (mascot companion logs reactions, tiling shows only on drag).
- Waffle family full pass (this session): bar + `wBackground` on both
  outputs, start menu (search, pinned apps, user footer), action center
  (toggles, sliders, battery), notification center (empty state, calendar,
  Focus timer), OSD pill via `qs ipc call audio volumeUp`.
- Harness notes: WAYLAND-1 screencopy wedges over a compositor's life
  (works fresh); HEADLESS-1 always captures. Focused-gated UI can be moved
  to HEADLESS-1 with raw-socket `hl.dsp.focus({ monitor = "HEADLESS-1" })`.
  Fixture `illogical-impulse/config.json` edits can be clobbered by the
  shell's own Config write-back — verify after writing, prefer edit-then-
  restart ordering.
  OSD methodology lesson: an earlier `lunana.osd test` hook was added on the
  unproven claim that vendored Audio never fires in the nest, then reverted
  once fast polling proved the natural path works — always verify a
  negative with timing tighter than the UI's own hide timer before adding
  test-only code.
  `pkill -f <pattern>` self-matches the invoking shell when the pattern
  appears in its own command line — use the `[b]racket` trick or kill by
  PID (learned the hard way, twice).
- Upstream notes: `RegionSelection.qml:169` null-screen TypeError on open
  is inir's own code (vendoring is import-rewrites only) and the selector
  still renders; altswitcher with zero windows correctly shows scrim only.
- Integrations: Network connected, Bluetooth adapter present (`Powered: no`),
  Battery 81%, brightness 100%, PipeWire connected, Weather 8°C, sensors detect
  CPU/GPU, keyring `{}`, widget scan `[]`.
