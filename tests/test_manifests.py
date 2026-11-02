#!/usr/bin/env python3
"""Smoke tests: manifests match the Omarchy schema, entry points exist, every
plugin is owned by the suite or the family switcher, every host's vendored
import closure resolves, family cycling converges, and the suite parses and
runs read-only. Pure stdlib; run with:

    python3 tests/test_manifests.py
"""

import json
import os
import re
import runpy
import subprocess
import sys
import tempfile
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
PLUGINS = REPO / "plugins"
ID_RE = re.compile(r"^[A-Za-z0-9][A-Za-z0-9._-]*$")
KIND_ENTRY = {"bar": "bar", "overlay": "overlay", "menu": "menu", "panel": "panel"}
VENDOR_IMPORT_RE = re.compile(r'import\s+"(\.\./\.\./lunana-vendor/[^"]+)"')
RELATIVE_IMPORT_RE = re.compile(r'import\s+"([^"]+)"')

failures = []


def check(cond, msg):
    if not cond:
        failures.append(msg)


def plugin_dirs():
    return sorted(p for p in PLUGINS.glob("*/*") if (p / "manifest.json").is_file())


def plugin_dir(pid):
    matches = [p for p in plugin_dirs() if p.name == pid]
    check(len(matches) == 1, f"expected one source for {pid}, found {len(matches)}")
    return matches[0] if len(matches) == 1 else PLUGINS / "missing" / pid


def test_manifests():
    dirs = plugin_dirs()
    check(len(dirs) >= 6, f"expected >=6 plugins, found {len(dirs)}")
    for d in dirs:
        m = json.loads((d / "manifest.json").read_text())
        pid = m.get("id", "")
        where = d.name
        check(m.get("schemaVersion") == 1, f"{where}: schemaVersion must be 1")
        for field in ("id", "name", "version", "kinds", "entryPoints"):
            check(field in m, f"{where}: missing required field '{field}'")
        check(bool(ID_RE.match(pid)) and ".." not in pid, f"{where}: invalid id '{pid}'")
        check(pid == d.name, f"{where}: manifest id '{pid}' must match dir name")
        check(not pid.startswith("omarchy."), f"{where}: id uses reserved omarchy.* namespace")
        check(isinstance(m.get("kinds"), list) and m["kinds"], f"{where}: kinds must be a non-empty array")
        eps = m.get("entryPoints", {})
        check(isinstance(eps, dict), f"{where}: entryPoints must be an object")
        for key, rel in eps.items():
            check(not str(rel).startswith("/"), f"{where}: entry point '{rel}' must be relative")
            check((d / rel).is_file(), f"{where}: entry point file missing: {rel}")
        for kind, ep in KIND_ENTRY.items():
            if kind in m.get("kinds", []):
                check(ep in eps, f"{where}: kind '{kind}' needs entryPoints.{ep}")


def test_suite_matches_plugins():
    suite = (REPO / "scripts" / "lunana-suite").read_text()
    family = (plugin_dir("lunana.family") / "family-cycle").read_text()
    for d in plugin_dirs():
        m = json.loads((d / "manifest.json").read_text())
        if m.get("x-lunana", {}).get("role") == "ui-probe":
            continue  # dev-only probe, manually assembled; never suite-installed
        owned = f'"{d.name}"' in suite or f'"{d.name}"' in family
        check(owned, f"neither suite nor family-cycle owns {d.name}")


def test_packaging_matches_plugins():
    """Every suite-installed plugin must be in the package metadata (the
    session-6 atoll-wallpaper addition was missed there)."""
    meta = json.loads((REPO / "packaging" / "package-metadata.json").read_text())
    packaged = set(meta.get("plugins", []))
    expected = set()
    for d in plugin_dirs():
        m = json.loads((d / "manifest.json").read_text())
        if m.get("x-lunana", {}).get("role") == "ui-probe":
            continue
        expected.add(d.name)
    check(packaged == expected,
          "packaging plugin set mismatch: "
          f"missing={sorted(expected - packaged)} extra={sorted(packaged - expected)}")


def test_vendor_closure():
    """Every `import "../../lunana-vendor/..."` in a plugin entry resolves in
    repo vendor/ (installed once as <config>/omarchy/lunana-vendor/)."""
    vendor = REPO / "vendor"
    for d in plugin_dirs():
        m = json.loads((d / "manifest.json").read_text())
        for rel in m.get("entryPoints", {}).values():
            text = (d / rel).read_text()
            for target in RELATIVE_IMPORT_RE.findall(text):
                if "vendor/" in target:
                    check(target.startswith("../../lunana-vendor/"),
                          f"{d.name}: {rel} uses stale vendor import {target}")
            for target in VENDOR_IMPORT_RE.findall(text):
                if target == "../../lunana-vendor/":
                    # Root import: needs the root qmldir + at least GlobalStates.
                    check((vendor / "qmldir").is_file(), f"{d.name}: vendor/qmldir missing")
                    check((vendor / "GlobalStates.qml").is_file(),
                          f"{d.name}: vendor/GlobalStates.qml missing")
                    continue
                sub = target[len("../../lunana-vendor/"):]
                check(not sub.startswith(".."), f"{d.name}: {rel} escapes the shared tree: {target}")
                candidate = vendor / sub
                check(candidate.exists(), f"{d.name}: {rel} imports {target} (missing in vendor/)")
                if candidate.is_dir():
                    check((candidate / "qmldir").is_file(),
                          f"{d.name}: {target} has no qmldir (vendor.py regen needed)")


def test_host_imports():
    """Hosts using ShellIpc must import qs.Commons (caught live: service
    plugin load failed with 'ShellIpc is not a type')."""
    for d in plugin_dirs():
        m = json.loads((d / "manifest.json").read_text())
        for rel in m.get("entryPoints", {}).values():
            text = (d / rel).read_text()
            if "ShellIpc" in text:
                check("qs.Commons" in text,
                      f"{d.name}: {rel} uses ShellIpc without importing qs.Commons")


def test_sidebar_left_fallback():
    """The drift left sidebar must keep the vendored content in a separate
    compilation unit. AiChat imports org.kde.syntaxhighlighting; if the host
    referenced SidebarLeftContent directly, a host without that optional QML
    module would fail to load and the overlay would never open."""
    host = plugin_dir("lunana.sidebar-left") / "SidebarLeft.qml"
    content = plugin_dir("lunana.sidebar-left") / "SidebarContent.qml"
    host_text = host.read_text()
    check(content.is_file(), "lunana.sidebar-left: SidebarContent.qml is missing")
    if not content.is_file():
        return
    check("LSLeft.SidebarLeftContent" not in host_text,
          "lunana.sidebar-left: host must not compile the vendored sidebar directly")
    check('source: "SidebarContent.qml"' in host_text,
          "lunana.sidebar-left: host must load SidebarContent.qml through a Loader")
    check("Loader.Error" in host_text,
          "lunana.sidebar-left: host must show a diagnostic on Loader.Error")
    check("LSLeft.SidebarLeftContent" in content.read_text(),
          "lunana.sidebar-left: SidebarContent.qml must instantiate the vendored sidebar")


def test_closeconfirm_hyprland():
    """The drift close-confirm host must be Hyprland-native. The vendored
    CloseConfirm trigger/close path uses `niri msg`, so a host that mounts it
    directly can never open on Hyprland (and `confirmItem.trigger` does not
    even exist on the Scope root). The host must snapshot
    Hyprland.activeToplevel, gate on closeConfirm.enabled, and close via the
    Hyprland closewindow path."""
    host = plugin_dir("lunana.closeconfirm") / "CloseConfirm.qml"
    text = host.read_text()
    check("LnMod.CloseConfirm {" not in text and "LnMod.CloseConfirm{" not in text,
          "lunana.closeconfirm: host must not mount the niri-only vendored CloseConfirm")
    check("Hyprland.activeToplevel" in text,
          "lunana.closeconfirm: host must snapshot Hyprland.activeToplevel")
    check("hl.dsp.window.close" in text,
          "lunana.closeconfirm: host must close via Omarchy's Lua dispatcher dialect "
          "(upstream `closewindow address:` is a Lua syntax error on this compositor)")
    check("closeConfirm?.enabled" in text or "closeConfirm.enabled" in text,
          "lunana.closeconfirm: host must honor Config.options.closeConfirm.enabled")
    check("WlrKeyboardFocus.Exclusive" in text,
          "lunana.closeconfirm: dialog must keep exclusive keyboard focus")
    for variant in ("CloseConfirmContent", "SCloseConfirmContent", "AtollCloseConfirmContent"):
        check(variant in text,
              f"lunana.closeconfirm: host must keep the {variant} variant")


def test_atoll_lock_hosts():
    """Every family lock host must mount the full vendored Lock, not a bare
    lock surface. The surfaces (drift LockSurface, SlateLockSurface,
    AtollLockSurface) all declare a required `context` (PAM LockContext) that
    only the full Lock provides; mounting one directly fails plugin creation
    (`service plugin createObject returned null`)."""
    for pid, surface in (("lunana.atoll-lock", "AtollLockSurface"),
                         ("lunana.slate-lock", "SlateLockSurface")):
        d = plugin_dir(pid)
        m = json.loads((d / "manifest.json").read_text())
        texts = [(rel, (d / rel).read_text()) for rel in m.get("entryPoints", {}).values()]
        for rel, text in texts:
            check("modules/lock" in text,
                  f"{pid}: {rel} must mount the full vendored Lock (context owner)")
            check(f"LnMod.{surface}" not in text and f"LnAtoll.{surface}" not in text,
                  f"{pid}: {rel} must not mount bare {surface} (required context unset)")


def test_atoll_composition():
    """lunana.atoll mounts lunana's real Atoll composition directly (bypassing
    AtollGate.official): Chassis.qml mirrors ShellIrisCriticalPanels (the AtollBar
    chassis + AtollReservations) and Panels.qml mirrors ShellIrisPanelsImpl (the
    panel set). Atoll.qml composes both. This is what gives lunana parity — the
    chassis owns the island/dock/control/stage/pieces/regions."""
    d = REPO / "plugins" / "atoll" / "lunana.atoll"
    read = lambda rel: (d / rel).read_text()

    chassis = read("Chassis.qml")
    check("AtollBar" in chassis, "lunana.atoll: Chassis must mount the AtollBar chassis")
    check("AtollReservations" in chassis, "lunana.atoll: Chassis must mount AtollReservations")

    panels = read("Panels.qml")
    for comp in ("AtollSidebar", "AtollSettingsOverlay", "AtollSessionScreen", "AtollOSD", "Lock"):
        check(comp in panels, f"lunana.atoll: Panels must mount {comp}")
    check("component OnDemandPanelLoader: Loader" in panels and "closeGraceMs" in panels,
          "lunana.atoll: on-demand panels must preserve lunana's exit-animation grace")
    check("LnServ.CompositorService.isNiri" in panels and "!root.atollBarEnabled" in panels,
          "lunana.atoll: standalone OSD must not duplicate the island feedback")

    atoll = read("Atoll.qml")
    check("Chassis {" in atoll and "Panels {" in atoll,
          "lunana.atoll: Atoll.qml must compose Chassis + Panels")


def test_atoll_test_hooks():
    """Test-only IPC hooks that make the nest-exerciseable what the harness
    cannot reach: the notification bus belongs to the host session and real
    volume keys do not exist in the nest. Each hook must stay wired to the
    exact render path it proves."""
    atoll = REPO / "plugins" / "atoll"
    osd = (atoll / "lunana.atoll-osd" / "AtollOsd.qml").read_text()
    check("function test(" in osd and "osdItem.show(" in osd,
          "lunana.atoll-osd: test hook must drive the OSD render path directly")
    notif = (atoll / "lunana.atoll-notifications" / "AtollNotifications.qml").read_text()
    check("function test()" in notif and "popupList = [" in notif,
          "lunana.atoll-notifications: test hook must inject into the popupList the banners read")
    check("popupList = []" in notif,
          "lunana.atoll-notifications: test hook must clear after itself")


def test_hypr_windows_contract():
    """The Hyprland window-model mirror must publish every Niri-shaped field
    the orbit reads. On Hyprland-without-Niri, NiriService.windows /
    allWorkspaces stay empty upstream, so lunana.state mirrors Hyprland's
    models into exactly the shapes AtollOrbit consumes (actions stay Niri
    socket-bound and are documented reduced)."""
    orbit = (REPO / "vendor" / "modules" / "atoll" / "orbit" / "AtollOrbit.qml").read_text()
    mirror = (plugin_dir("lunana.state") / "HyprWindows.qml").read_text()
    check("HyprWindows" in (plugin_dir("lunana.state") / "Service.qml").read_text(),
          "lunana.state: Service.qml must instantiate the HyprWindows mirror")
    window_fields = set(re.findall(r"window\?\.\s*([A-Za-z_]+)", orbit))
    window_fields |= set(re.findall(r"(?<![A-Za-z_.])window\.([A-Za-z_]+)", orbit))
    ws_fields = set(re.findall(r"(?<![A-Za-z])(?:slot\.)?ws\.([A-Za-z_]+)", orbit))
    ws_fields |= set(re.findall(r"\(\s*ws\.([A-Za-z_]+)", orbit))
    # Array.filter and MinimizedWindows.* share the trailing "ws." spelling;
    # only bare workspace objects count toward the Niri contract.
    ws_fields -= {"filter", "getMinimizedForOutput", "isStashWorkspace", "minimize", "restore", "restoreOriginal"}
    window_contract = {"id", "app_id", "title", "workspace_id", "is_active", "is_focused"}
    ws_contract = {"id", "idx", "name", "output", "is_active", "active_window_id"}
    check(window_fields <= window_contract,
          f"orbit reads window fields outside the mirror contract: {sorted(window_fields - window_contract)}")
    check(ws_fields <= ws_contract,
          f"orbit reads workspace fields outside the mirror contract: {sorted(ws_fields - ws_contract)}")
    for f in sorted(window_contract | ws_contract):
        check(f"{f}:" in mirror,
              f"HyprWindows.qml must publish '{f}:' for the orbit contract")
    check("addrToId" in mirror,
          "HyprWindows.qml must map addresses to small stable ints (raw "
          "address hex overflows QML's 32-bit int consumers: cursorId, "
          "card ids, NiriService action args)")
    check("parseInt(String(addr" not in mirror and "parseInt(String(keys" not in mirror,
          "HyprWindows.qml must not derive ids with parseInt (truncation)")
    check("isHyprland" in mirror and "isNiri" in mirror,
          "HyprWindows.qml must stay dormant unless Hyprland-without-Niri")


def test_vendor_patch_lever():
    """The vendor-patch lever must apply cleanly and idempotently, and the
    NiriService patch must keep its Hyprland routing markers (the Niri path
    stays byte-identical by construction: branches only, no rewrites)."""
    import subprocess
    r = subprocess.run([sys.executable, str(REPO / "scripts" / "vendor.py"), "--patch"],
                       capture_output=True, text=True)
    check(r.returncode == 0, f"vendor.py --patch failed: {r.stderr.strip()}")
    r2 = subprocess.run([sys.executable, str(REPO / "scripts" / "vendor.py"), "--patch"],
                        capture_output=True, text=True)
    check(r2.returncode == 0, f"vendor.py --patch is not idempotent: {r2.stderr.strip()}")
    patched = (REPO / "vendor" / "services" / "NiriService.qml").read_text()
    for marker in ("_hyprEnabled", "_hyprAddressFor", "_hyprDispatch",
                   "hl.dsp.window.close", "hl.dsp.focus", "hl.dsp.window.move",
                   "hl.dsp.window.float"):
        check(marker in patched, f"patched NiriService.qml lost marker: {marker}")
    check("import Quickshell.Hyprland" in patched,
          "patched NiriService.qml must import Quickshell.Hyprland")
    permit = REPO / "vendor" / "modules" / "lock" / "pam" / "lunana-permit.conf"
    check(permit.is_file(), "lever file-creation mode must install lunana-permit.conf")
    check("pam_permit" in permit.read_text(), "lunana-permit.conf must be permissive")
    # Family switching belongs to the shell transition, and every family
    # needs a stock exit: all five lunana call sites must route through
    # `omarchy-shell lunana.family set`, and the atoll choice row must offer
    # the Omarchy stock target.
    routed = (REPO / "vendor" / "modules" / "atoll" / "settings" / "AtollOptions.qml").read_text()
    check('["omarchy-shell", "lunana.family", "set"' in routed,
          "patched AtollOptions: panelFamily must route through lunana.family")
    check('{label:"Omarchy stock",value:"stock"' in routed,
          "patched AtollOptions: family choice must offer Omarchy stock")
    for rel in ("modules/settings/AtollConfig.qml",
                "modules/settings/ModulesConfig.qml",
                "modules/slate/settings/pages/SModulesPage.qml"):
        text = (REPO / "vendor" / rel).read_text()
        check('["omarchy-shell", "lunana.family", "set"' in text,
              f"patched {rel}: family switch must route through lunana.family")
        check('"panelFamily", "set"' not in text,
              f"patched {rel}: unvendored lunana script call must be gone")
    lockctx = (REPO / "vendor" / "modules" / "lock" / "LockContext.qml").read_text()
    check("LUNANA_TEST_PAM_UNLOCK" in lockctx and 'configDirectory: root._testPamPermit ? "pam" : ""' in lockctx,
          "LockContext.qml must gate the fixture-local PAM service on LUNANA_TEST_PAM_UNLOCK")


def _load_family_table():
    import importlib.util as ilu
    cycle = plugin_dir("lunana.family") / "family-cycle"
    spec = ilu.spec_from_loader("family_cycle_test", loader=None)
    mod = ilu.module_from_spec(spec)
    with open(cycle, encoding="utf-8") as handle:
        exec(compile(handle.read(), str(cycle), "exec"), mod.__dict__)
    return mod


def test_family_cycle():
    """Cycle drift -> slate -> atoll -> stock in a fixture HOME: exactly one
    family active, shared services never toggled."""
    mod = _load_family_table()
    with tempfile.TemporaryDirectory() as tmp:
        cfg = Path(tmp) / ".config" / "omarchy"
        (cfg / "plugins").mkdir(parents=True)
        # Every bar host "installed" so no family is skipped.
        for name, bar, _owned in mod.FAMILIES:
            if bar:
                (cfg / "plugins" / bar).mkdir(exist_ok=True)
        shell_path = cfg / "shell.json"
        shell_path.write_text(json.dumps({"bar": {"id": "lunana.bar"}, "plugins": []}))
        env = dict(os.environ, XDG_CONFIG_HOME=str(Path(tmp) / ".config"))

        def run(*args):
            return subprocess.run([sys.executable, str(plugin_dir("lunana.family") / "family-cycle"),
                                   *args], capture_output=True, text=True, env=env)

        r = run("status")
        check(r.returncode == 0, f"family-cycle status failed: {r.stderr.strip()}")
        old = os.environ.get("XDG_CONFIG_HOME")
        os.environ["XDG_CONFIG_HOME"] = str(Path(tmp) / ".config")
        try:
            seen = []
            for _ in range(len(mod.FAMILIES)):
                r = run("cycle")
                check(r.returncode == 0, f"family-cycle cycle failed: {r.stderr.strip()}")
                shell = json.loads(shell_path.read_text())
                fam = mod.current_family(shell)[0]
                seen.append(fam)
                check(shell.get("lunana", {}).get("family") == fam,
                      f"shell.json lunana.family does not record {fam}: {shell.get('lunana')!r}")
        finally:
            if old is None:
                del os.environ["XDG_CONFIG_HOME"]
            else:
                os.environ["XDG_CONFIG_HOME"] = old
        check(sorted(seen) == sorted(f[0] for f in mod.FAMILIES),
              f"cycle did not visit every family: {seen}")
        # Coherence: owned sets of distinct families never mix. (The empty
        # stock set trivially matches, so it is not a coherence witness.)
        shell = json.loads(shell_path.read_text())
        have = {e.get("id") for e in shell.get("plugins", []) if isinstance(e, dict)}
        for fam in mod.FAMILIES:
            if fam[2] and set(fam[2]) <= have:
                others = [o for f in mod.FAMILIES if f[0] != fam[0] for o in f[2]]
                overlap = [o for o in others if o in have and o not in mod.SHARED]
                check(not overlap, f"mixed-family plugins after cycle to {fam[0]}: {overlap}")


def test_family_set_command():
    """family-cycle set jumps straight to any family (drift/slate/atoll/stock),
    rejects unknown names, and never toggles shared services."""
    mod = _load_family_table()
    with tempfile.TemporaryDirectory() as tmp:
        cfg = Path(tmp) / ".config" / "omarchy"
        (cfg / "plugins").mkdir(parents=True)
        for name, bar, _owned in mod.FAMILIES:
            if bar:
                (cfg / "plugins" / bar).mkdir(exist_ok=True)
        shell_path = cfg / "shell.json"
        shell_path.write_text(json.dumps({
            "bar": {"id": "lunana.bar"},
            "plugins": [{"id": pid} for pid in sorted(mod.SHARED)]}))
        env = dict(os.environ, XDG_CONFIG_HOME=str(Path(tmp) / ".config"))

        def run(*args):
            return subprocess.run(
                [sys.executable,
                 str(plugin_dir("lunana.family") / "family-cycle"), *args],
                capture_output=True, text=True, env=env)

        for name in ("atoll", "stock", "slate", "drift"):
            # current_family() resolves installed bars from XDG_CONFIG_HOME:
            # keep the in-process view on the fixture (like the cycle test).
            old = os.environ.get("XDG_CONFIG_HOME")
            os.environ["XDG_CONFIG_HOME"] = str(Path(tmp) / ".config")
            try:
                r = run("set", name)
                check(r.returncode == 0,
                      f"family-cycle set {name} failed: {r.stderr.strip()}")
                shell = json.loads(shell_path.read_text())
                check(mod.current_family(shell)[0] == name,
                      f"set {name} did not land: {shell.get('lunana')}")
            finally:
                if old is None:
                    del os.environ["XDG_CONFIG_HOME"]
                else:
                    os.environ["XDG_CONFIG_HOME"] = old
            have = {e.get("id") for e in shell.get("plugins", [])
                    if isinstance(e, dict)}
            check(mod.SHARED <= have,
                  f"set {name} toggled a shared service: {sorted(have)}")
        r = run("set", "nope")
        check(r.returncode != 0,
              "family-cycle set accepted an unknown family")
        r = run("set")
        check(r.returncode != 0,
              "family-cycle set without a name must fail")


def test_family_widget_layout():
    """The suite pins lunana.family-switch into bar.layout.left (after the
    workspaces) on install and strips it on uninstall. The layout object is
    shared, so the stock bar offers the way back too."""
    suite = runpy.run_path(str(REPO / "scripts" / "lunana-suite"))
    old = os.environ.get("XDG_CONFIG_HOME")
    try:
        with tempfile.TemporaryDirectory() as tmp:
            os.environ["XDG_CONFIG_HOME"] = tmp
            shell = {"bar": {"id": "lunana.bar", "layout": {
                "left": [{"id": "omarchy.menu"},
                         {"id": "omarchy.workspaces"}],
                "right": []}}}
            check(suite["ensure_family_widget_layout"](shell) is True,
                  "install must pin the family widget")
            check([e["id"] for e in shell["bar"]["layout"]["left"]] ==
                  ["omarchy.menu", "omarchy.workspaces",
                   "lunana.family-switch"],
                  "widget must sit after the workspaces")
            check(suite["ensure_family_widget_layout"](shell) is False,
                  "layout pin must be idempotent")
            check(suite["strip_family_widget_layout"](shell) is True,
                  "uninstall must strip the widget")
            check(all(e.get("id") != "lunana.family-switch"
                      for entries in shell["bar"]["layout"].values()
                      for e in entries),
                  "widget survived the strip")
            check(suite["strip_family_widget_layout"](shell) is False,
                  "layout strip must be idempotent")
    finally:
        if old is None:
            os.environ.pop("XDG_CONFIG_HOME", None)
        else:
            os.environ["XDG_CONFIG_HOME"] = old


def test_suite_runs():
    r = subprocess.run([sys.executable, str(REPO / "scripts" / "lunana-suite"), "status"],
                       capture_output=True, text=True)
    check(r.returncode == 0, f"lunana-suite status exited {r.returncode}: {r.stderr.strip()}")
    r = subprocess.run([sys.executable, str(REPO / "scripts" / "lunana-suite"),
                        "install", "--dry-run"], capture_output=True, text=True)
    check(r.returncode == 0, f"lunana-suite install --dry-run exited {r.returncode}: {r.stderr.strip()}")


def test_shared_services_guarded():
    """The lunana.state outage (orbit/altswitcher silently empty on atoll):
    shared services must be runtime-ensured on live switches, never touched
    in fixtures, and enable/disable failures must be reported, not claimed."""
    cycle_src = (plugin_dir("lunana.family") / "family-cycle").read_text()
    check("ensure_shared_runtime" in cycle_src and "using_fixture" in cycle_src,
          "family-cycle must runtime-ensure SHARED services outside fixtures")
    check("LUNANA_FIXTURE" in cycle_src and "config_home() != Path.home()" in cycle_src,
          "family-cycle fixture gate must cover both the harness flag and redirected configs")
    suite_src = (REPO / "scripts" / "lunana-suite").read_text()
    check("proc.returncode != 0" in suite_src,
          "lunana-suite must check omarchy-plugin-{enable,disable} results instead of claiming success")


def test_family_shortcut_routing():
    """Shared keybinds must reach Atoll's native state when that family is
    active, rather than toggling drift-only overlay plugins."""
    family = (plugin_dir("lunana.family") / "Family.qml").read_text()
    keybinds = (REPO / "scripts" / "keybinds" / "lunana.lua").read_text()
    for action in ("overview", "focus", "today", "controls", "cheatsheet", "region", "settings"):
        check(f'function {action}(): void {{ root.route("{action}") }}' in family,
              f"lunana.family: must route {action} through the active family")
        check(f'omarchy-shell lunana.family {action}' in keybinds,
              f"lunana keybinds: must dispatch {action} through lunana.family")
    check("Lunana.GlobalStates.toggleSidebarLeft" in family
          and "Lunana.GlobalStates.controlPanelOpen" in family
          and "Lunana.GlobalStates.settingsOverlayOpen" in family,
          "lunana.family: atoll routing must use the native shared GlobalStates")
    check("function set(" in family and "setFamily" in family
          and '"set", name' in family,
          "lunana.family: must expose set() to jump straight to a family")
    # xkbcommon names the comma keysym "comma": an upper-case COMMA never
    # matches, and every comma chord is already an Omarchy notification bind.
    check("COMMA" not in keybinds,
          "lunana keybinds: must not use the COMMA keysym (xkbcommon wants lowercase, all chords taken)")
    check('SUPER + ALT + P' in keybinds and 'lunana.family settings' in keybinds,
          "lunana keybinds: settings must ride a free chord through lunana.family")


def test_omarchy_background_bridge():
    """The vendored tree must carry the Omarchy background sync: the follower
    in Wallpapers and the switcher rows in the atoll settings specs."""
    wallpapers = (REPO / "vendor" / "services" / "Wallpapers.qml").read_text()
    check("omarchyBackgroundLink" in wallpapers
          and "_adoptOmarchyBackground" in wallpapers
          and "_repointOmarchyLink" in wallpapers,
          "vendor Wallpapers: must follow + repoint Omarchy's background link")
    options = (REPO / "vendor" / "modules" / "atoll" / "settings" / "AtollOptions.qml").read_text()
    check("omarchyPresent" in options
          and "followOmarchyBackground" in options
          and '"omarchy", "theme", "switcher"' in options,
          "vendor AtollOptions: must expose the Omarchy theme/background rows")


def test_omarchy_theme_hook():
    """`omarchy theme set` must reach the atoll island, dock, panels and edges:
    the managed hook maps Omarchy slugs onto lunana theme ids and the suite
    installs, refreshes and removes it."""
    hook = REPO / "scripts" / "hooks" / "theme-set.d" / "50-lunana-atoll-theme"
    check(hook.is_file(), "lunana must ship the Omarchy theme-set hook")
    text = hook.read_text()
    for slug, lunana_id in (("catppuccin", "catppuccin-mocha"),
                          ("catppuccin-latte", "catppuccin-latte"),
                          ("everforest", "everforest"),
                          ("gruvbox", "gruvbox-material"),
                          ("kanagawa", "kanagawa"), ("nord", "nord"),
                          ("rose-pine", "rose-pine"),
                          ("tokyo-night", "tokyo-night")):
        check(f"{slug})" in text and f'"{lunana_id}"' in text,
              f"theme hook: must map Omarchy {slug} onto lunana {lunana_id}")
    check('*) lunana_theme="auto"' in text,
          "theme hook: unknown Omarchy themes must fall back to wallpaper colours")
    check("omarchy-theme.json" in text and '"slug"' in text,
          "theme hook: must stash the Omarchy palette in a sidecar for the washi solver")
    washi = (REPO / "vendor" / "modules" / "atoll" / "style" / "AtollWashi.qml").read_text()
    check("omarchySeedsLive" in washi and "omarchyThemeId" in washi,
          "vendor AtollWashi: must prefer Omarchy seeds while following the Omarchy theme")
    check("wallpaperSeeds?.primary" in washi,
          "vendor AtollWashi: must keep wallpaper seeds as the fallback path")
    check("illogical-impulse/config.json" in text and '"appearance"' in text,
          "theme hook: must write appearance.theme into the lunana config only")
    check("icons.theme" in text and '"iconTheme"' in text and "index.theme" in text,
          "theme hook: must converge appearance.iconTheme on an installed Omarchy icon theme")
    check("gtk-icon-theme-name" in text and "icon_theme" in text,
          "theme hook: must keep GTK and Qt icon settings on that theme")
    suite = (REPO / "scripts" / "lunana-suite").read_text()
    check("install_theme_hook(False)" in suite and "remove_theme_hook(False)" in suite
          and "converge_atoll_theme()" in suite,
          "lunana-suite: must install/remove the theme hook and converge once")


def test_chrome_contrast():
    style = (REPO / "vendor" / "modules" / "atoll" / "style" / "AtollStyle.qml").read_text()
    check("chromeContrast" in style and "chromeSurface" in style and "chromeRaised" in style,
          "AtollStyle: must expose the chrome elevation ladder")
    check("root.surfaceHigh, root.chromeContrast / 100" in style
          and "root.surfaceHighest, root.chromeContrast / 100" in style,
          "AtollStyle: chrome must move from surface to surfaceHigh, its controls one step above")
    bar = (REPO / "vendor" / "modules" / "atoll" / "bar" / "AtollBar.qml").read_text()
    check("tint: AtollStyle.chromeSurface" in bar,
          "AtollBar: the chassis field must wear the chrome tint")
    sidebar = (REPO / "vendor" / "modules" / "atoll" / "sidebar" / "AtollSidebarSection.qml").read_text()
    check("AtollStyle.chromeRaised" in sidebar,
          "sidebar sections: must stay one step above the chrome body")
    mark = (REPO / "vendor" / "modules" / "atoll" / "control" / "AtollControlMark.qml").read_text()
    check("AtollStyle.chromeRaised" in mark,
          "control marks: must stay visible on the chrome body")
    dock = (REPO / "vendor" / "modules" / "atoll" / "dock" / "AtollDock.qml").read_text()
    check("AtollStyle.chromeRaised" in dock,
          "dock menu: thumbnails must stay visible on the chrome body")
    config = (REPO / "vendor" / "modules" / "common" / "Config.qml").read_text()
    check("property int chromeContrast: 100" in config,
          "config schema: must default chromeContrast to the full step")
    options = (REPO / "vendor" / "modules" / "atoll" / "settings" / "AtollOptions.qml").read_text()
    check('path: "atoll.appearance.chromeContrast"' in options,
          "settings: must expose the Chrome contrast slider")


def test_hypr_config_adapters():
    suite = runpy.run_path(str(REPO / "scripts" / "lunana-suite"))
    suite["_reload_hypr"] = lambda: None
    old = os.environ.get("XDG_CONFIG_HOME")
    try:
        for kind in ("lua", "conf"):
            with tempfile.TemporaryDirectory() as tmp:
                cfg = Path(tmp) / "hypr"
                cfg.mkdir()
                entry = cfg / f"hyprland.{kind}"
                entry.write_text("-- sentinel\n" if kind == "lua" else "# sentinel\n")
                os.environ["XDG_CONFIG_HOME"] = tmp
                suite["install_hypr_conf"](False)
                suite["install_hypr_conf"](False)
                text = entry.read_text()
                token = "-- >>> lunana >>>" if kind == "lua" else "source = "
                check(text.count(token) == 1, f"{kind}: Lunana include is not idempotent")
                installed = cfg / f"lunana.{kind}"
                check(installed.is_file(), f"{kind}: fragment was not installed")
                suite["remove_hypr_conf"](False)
                check(not installed.exists(), f"{kind}: fragment survived uninstall")
                check("lunana" not in entry.read_text(), f"{kind}: include survived uninstall")
    finally:
        if old is None:
            os.environ.pop("XDG_CONFIG_HOME", None)
        else:
            os.environ["XDG_CONFIG_HOME"] = old


def test_no_stale_brand():
    """The rebrand is total: re-running scripts/vendor_rename.py must be a
    no-op everywhere it applies. Catches reintroduced pre-rename brand
    tokens in code, comments, and user-visible strings (translations keep
    their non-English verbs — the renamer's word boundaries protect those,
    so this test uses the renamer itself as the oracle)."""
    import importlib.util as ilu
    spec = ilu.spec_from_file_location("vendor_rename_test",
                                       str(REPO / "scripts" / "vendor_rename.py"))
    mod = ilu.module_from_spec(spec)
    spec.loader.exec_module(mod)
    offenders = []
    for path in mod.iter_files([r for r in mod.ROOTS if r.exists()]):
        try:
            text = path.read_text(encoding="utf-8")
        except (UnicodeDecodeError, OSError):
            continue
        if mod.rename_content(text) != text:
            offenders.append(str(path.relative_to(REPO)))
        if mod.rename_name(path.name) != path.name:
            offenders.append(str(path.relative_to(REPO)) + " (name)")
    check(not offenders,
          f"stale brand tokens survive the rename (run scripts/vendor_rename.py): {offenders[:8]}")


def main():
    for fn in (test_manifests, test_suite_matches_plugins, test_packaging_matches_plugins, test_no_stale_brand,
               test_vendor_closure, test_host_imports, test_sidebar_left_fallback,
               test_closeconfirm_hyprland,
               test_atoll_lock_hosts, test_atoll_composition,
               test_atoll_test_hooks, test_hypr_windows_contract,
               test_vendor_patch_lever,
               test_family_cycle, test_family_set_command,
               test_family_widget_layout, test_suite_runs, test_shared_services_guarded,
               test_family_shortcut_routing, test_omarchy_background_bridge,
               test_omarchy_theme_hook,
               test_chrome_contrast,
               test_hypr_config_adapters):
        try:
            fn()
        except Exception as exc:  # noqa: BLE001
            failures.append(f"{fn.__name__} raised {exc!r}")
    if failures:
        print(f"FAIL ({len(failures)}):")
        for f in failures:
            print(f"  - {f}")
        return 1
    print(f"PASS — {len(plugin_dirs())} plugins, manifests valid, closure resolves, suite OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
