# vendor-patches/

Lunana-local behavior the upstream inir tree cannot carry, applied onto
`vendor/` by `scripts/vendor.py --patch` after vendoring.

Each file mirrors the vendor tree: `vendor-patches/services/Foo.qml.patch`
patches `vendor/services/Foo.qml`. Format is unified diff; application uses
zero fuzz and fails loudly on drift, so a changed upstream never misapplies
silently. Re-running `--patch` is idempotent (already-applied hunks are
detected and skipped).

Workflow rules:
- Never hand-edit `vendor/` — regenerate via `scripts/vendor.py <path>`,
  then re-run `scripts/vendor.py --patch` for every patched file it touched.
- A patch must be *narrow*: gate new behavior so the Niri path stays
  byte-identical (e.g. `if Hyprland-without-Niri … else original`).
- Prefer fixing upstream in inir when the fix is upstream-suitable (stock
  Hyprland syntax, Niri behavior). Patches are for behavior upstream cannot
  take — currently: Omarchy's Lua dispatcher dialect (`dispatch X` is
  `hl.dispatch(X)` shorthand, so upstream `closewindow address:…` is a Lua
  syntax error here; verified against the nested compositor).

Current patches:
- `services/NiriService.qml.patch` — route closeWindow / focusWindow /
  moveWindowToWorkspaceById / switchToWorkspaceById through `hl.dsp.*` and
  intercept `ToggleWindowFloating` in `send()` when on Hyprland without
  Niri. Lets Niri-shaped consumers (orbit, workspace strip) act on
  Hyprland; toggleOverview stays Niri-only (its analog is
  lunana.overview, which has no vendor-level handle).
