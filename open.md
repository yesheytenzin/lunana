# Lunana — open items (2026-10-30, sessions 7–10)

Sessions 7–10 closed: the nested harness, the full ii/waffle/iris overlay
matrices, live family switching, dual-monitor behavior, and the iRiS
satellite completion are proven on Hyprland 0.57.0. What remains is
environment-dependent or documented reduced fidelity.

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
  `mruWindowIds` shape (int ids derived from addresses; dormant unless
  Hyprland-without-Niri), and the orbit renders workspace strips with live
  window cards on Hyprland (`iris-orbit-hyprland-mirror.png`). Window actions
  still route to Niri socket functions (dead without Niri) — the
  vendor-patch lever + dsp-dialect action mapping is the planned Phase 2.
- OSD volume trigger: external `wpctl` changes do not reach the OSD because
  `showLevel` requires a recent `Audio.lastUserChange`, which only the
  `audio` IPC path sets (`qs ipc --pid <nested-shell> call audio volumeUp`
  hits the vendored handler — no omarchy `audio` target shadows it). Proven
  in the nest via `lunana.iris-osd test volume`: the glass volume pill renders
  exactly like inir. The Audio→OSD signal wiring itself is untouched vendored
  code.
- Notification banners: `notify-send` reaches the host session's notification
  server (shared bus), and omarchy's notifications service shadows the
  vendored `notifications` IPC target — so bus ingress is untestable in the
  nest. Proven instead via `lunana.iris-notifications test`: full banner
  pixel-verified — icon, summary, wrapped body, app name, and timestamp all
  render (`iris-notif-text-final.png`; WAYLAND-1 screencopy is flaky in the
  nest, HEADLESS-1 always captures, so the proof needed a fresh compositor).
- Lock *open*: proven in the nest with restart recovery — `lunana.iris-lock
  open` renders the full iris lock UI (clock, weather, battery, avatar,
  password field); `restart` kills the lock client, the compositor shows its
  crashed-lockscreen screen, and raw-socket
  `eval hl.clear_crashed_lockscreen()` restores the desktop. PAM-success
  unlock stays untestable (no non-interactive password path); the PAM
  *failure* branch is proven — a wrong password shows the red "Incorrect
  password" state via a real PAM round trip (`iris-lock-failure.png`).
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
- OSD pill, notification banner (full text), lock open + lock failure, and
  Hyprland orbit window list proven with screenshots; static tests pin the
  hooks and the orbit Niri-shape contract (`test_iris_test_hooks`,
  `test_hypr_windows_contract`).
- Integrations: Network connected, Bluetooth adapter present (`Powered: no`),
  Battery 81%, brightness 100%, PipeWire connected, Weather 8°C, sensors detect
  CPU/GPU, keyring `{}`, widget scan `[]`.
