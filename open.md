# Lunana — open items (session-7, 2026-10-30)

The previous open.md items are closed: the nested harness, the full overlay
matrix, live family switching, and dual-monitor behavior are proven on Hyprland
0.57.0 (first pass on 0.56.2, re-run after the host update). What remains is
environment-dependent or documented reduced fidelity.

## Graceful fallback (host works without the dependency)
- `lunana.sidebar-left` now opens, closes, and shows a diagnostic panel when
  the vendored sidebar cannot compile because `org.kde.syntaxhighlighting`
  is missing. The overlay layer appears on every output; the fallback names
  the missing module and stays click-to-close. Install `syntax-highlighting`
  to get the full panel. The success path (real content, no fallback) was
  verified with a temporary stub QML module.

## Blocked by missing system packages / tools
- `org.kde.syntaxhighlighting` (KF6 `syntax-highlighting`): required by the
  vendored AiChat, so the full `lunana.sidebar-left` content cannot be
  exercised until it is installed. The host degrades gracefully as above.
- `wf-recorder`: absent; the region-recording path is untested. Region
  screenshot/OCR (grim/slurp/tesseract) works.
- `matugen`: absent; Material You opt-in degrades cleanly. It is an optional
  dependency; the default Omarchy-tokens path needs nothing.
- inir thumbnail venv (`$HOME/.local/state/quickshell/.venv`): absent; bulk
  wallpaper thumbnails use the vendored ImageMagick fallback. Optional.

## Needs credentials / live services
- AI, YtMusic, Wallhaven, and AnimeService network exercise needs API keys
  and the full `sidebar-left` content (blocked above). All services
  instantiate with zero errors in the nest.

## iRiS family — fully verified this session (nested Hyprland 0.57.0, dual output)
- Resident services render on both outputs with zero QML errors: `lunana-iris`
  (island pill + clock/wifi), `lunana-iris-dock` (dock pill + icons),
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
- Reduced, not fixable host-side: orbit lists no windows on Hyprland (its
  window/workspace model is Niri-only upstream — identical on
  inir-on-Hyprland). OSD volume-trigger and notification banners are
  environment-limited in the nest (PipeWire sink plumbing; notification bus
  owned by the host session); both services instantiate clean. Lock *open*
  stays untested by design.

## Reduced fidelity (documented, not defects — verified workarounds below)
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
  nest. Proven instead via `lunana.iris-notifications test`, which injects a
  synthetic entry shaped like the service wrapper straight into the
  `popupList` the banner delegates read (second call clears): pill, icon,
  timestamp render; summary/body flow through the identical delegate
  expressions. Full-pixel summary/body proof awaits a working WAYLAND-1
  screencopy (only HEADLESS-1 captures in the nest right now).
- Lock *open*: proven in the nest with restart recovery — `lunana.iris-lock
  open` renders the full iris lock UI (clock, weather, battery, avatar,
  password field); `restart` kills the lock client, the compositor shows its
  crashed-lockscreen screen, and raw-socket
  `eval hl.clear_crashed_lockscreen()` restores the desktop. PAM-success
  unlock stays untestable (no non-interactive password path).
- iRiS single-surface chassis fusion is not reproduced by the satellite model
  (Option A); lock *open* stays untested by design (it would lock the test
  session). The known lock-surface, missing `version.json`, and duplicate
  `IpcHandler` warnings remain as recorded in PORTING.md.

## Proven this session
- Harness: distinct nested shell without `-n`, runtime `log.qslog` discovery,
  `up --monitors 2`, Lua fixture, clean `down`, and host PipeWire sockets
  linked into the nested runtime.
- ii overlays: 11/11 open/close (sidebar-left opens with the diagnostic
  fallback when `org.kde.syntaxhighlighting` is absent; closeconfirm is a
  Hyprland-native host around the vendored dialog content); waffle: 3/3;
  iris: 9/9 overlays + orbit open/close (including visible
  `lunana.iris-control` content).
- Family cycle `ii ↔ waffle ↔ iris ↔ stock` live without a shell restart;
  dual-monitor layers (background/bar/dock/notifications) on both outputs.
- Integrations: Network connected, Bluetooth adapter present (`Powered: no`),
  Battery 81%, brightness 100%, PipeWire connected, Weather 8°C, sensors detect
  CPU/GPU, keyring `{}`, widget scan `[]`.
