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

## Reduced fidelity (documented, not defects)
- `lunana.closeconfirm` has no Hyprland close-intercept analog; the vendored
  trigger falls back to `niri msg`, so the overlay cannot open in the nest
  without a toplevel/niri fallback. Kept as reduced fidelity.
- iRiS single-surface chassis fusion is not reproduced by the satellite model
  (Option A); lock *open* stays untested by design (it would lock the test
  session). The known lock-surface, missing `version.json`, and duplicate
  `IpcHandler` warnings remain as recorded in PORTING.md.

## Proven this session
- Harness: distinct nested shell without `-n`, runtime `log.qslog` discovery,
  `up --monitors 2`, Lua fixture, clean `down`, and host PipeWire sockets
  linked into the nested runtime.
- ii overlays: 10/11 open/close (sidebar-left opens with the diagnostic
  fallback; closeconfirm remains reduced fidelity); waffle: 3/3; iris: 9/9
  (including visible `lunana.iris-control` content).
- Family cycle `ii ↔ waffle ↔ iris ↔ stock` live without a shell restart;
  dual-monitor layers (background/bar/dock/notifications) on both outputs.
- Integrations: Network connected, Bluetooth adapter present (`Powered: no`),
  Battery 81%, brightness 100%, PipeWire connected, Weather 8°C, sensors detect
  CPU/GPU, keyring `{}`, widget scan `[]`.
