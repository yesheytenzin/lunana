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
    session-6 iris-wallpaper addition was missed there)."""
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
    """The ii left sidebar must keep the vendored content in a separate
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
    """The ii close-confirm host must be Hyprland-native. The vendored
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
    for variant in ("CloseConfirmContent", "WCloseConfirmContent", "IrisCloseConfirmContent"):
        check(variant in text,
              f"lunana.closeconfirm: host must keep the {variant} variant")


def test_iris_lock_hosts():
    """Every family lock host must mount the full vendored Lock, not a bare
    lock surface. The surfaces (ii LockSurface, WaffleLockSurface,
    IrisLockSurface) all declare a required `context` (PAM LockContext) that
    only the full Lock provides; mounting one directly fails plugin creation
    (`service plugin createObject returned null`)."""
    for pid, surface in (("lunana.iris-lock", "IrisLockSurface"),
                         ("lunana.waffle-lock", "WaffleLockSurface")):
        d = plugin_dir(pid)
        m = json.loads((d / "manifest.json").read_text())
        texts = [(rel, (d / rel).read_text()) for rel in m.get("entryPoints", {}).values()]
        for rel, text in texts:
            check("modules/lock" in text,
                  f"{pid}: {rel} must mount the full vendored Lock (context owner)")
            check(f"LnMod.{surface}" not in text and f"LnIris.{surface}" not in text,
                  f"{pid}: {rel} must not mount bare {surface} (required context unset)")


def test_iris_satellite_wiring():
    """Satellite hosts must wire what the chassis used to provide. The glass
    bodies behind island/dock/control/stage/edit are painted by the shared
    chassis IrisField from each piece's published shapes — without a
    per-output field the content floats bare. Embeddable pieces also need a
    filled loader (centerIn collapses them to 0x0) and their screen + state."""
    iris = REPO / "plugins" / "iris"
    host = lambda pid, rel: (iris / pid / rel).read_text()

    island = host("lunana.iris", "Iris.qml")
    check("IrisField" in island and "island.fieldShapes" in island,
          "lunana.iris: island needs its own IrisField fed by island.fieldShapes")

    dock = host("lunana.iris-dock", "IrisDock.qml")
    check("IrisField" in dock and "bodyShape" in dock,
          "lunana.iris-dock: dock needs its own IrisField fed by its bodyShape")
    check("screen: modelData" in dock,
          "lunana.iris-dock: dock needs the output screen")
    check("PanelWindow" in dock,
          "lunana.iris-dock: the embeddable dock needs a host PanelWindow surface")

    control = host("lunana.iris-control", "IrisControl.qml")
    check("anchors.fill: parent" in control and "anchors.centerIn: parent" not in control,
          "lunana.iris-control: fullscreen surface must fill, not center")
    check("screenData: modelData" in control,
          "lunana.iris-control: control needs the output screenData")
    check("controlPanelOpen = true" in control,
          "lunana.iris-control: host must drive controlPanelOpen like the chassis morph")
    check("fieldShapes" in control,
          "lunana.iris-control: control card needs its own IrisField")

    stage = host("lunana.iris-stage", "IrisStage.qml")
    check("modelData: modelData" in stage,
          "lunana.iris-stage: stage has a required modelData (unset fails the Loader)")
    check("anchors.centerIn: parent" not in stage,
          "lunana.iris-stage: fullscreen surface must fill, not center")

    edit = host("lunana.iris-edit", "IrisEdit.qml")
    check("screenData: modelData" in edit,
          "lunana.iris-edit: edit bar needs the output screenData")
    check("irisEdit = true" in edit,
          "lunana.iris-edit: host must drive GlobalStates.irisEdit like the chassis")

    palette = host("lunana.iris-palette", "IrisPalette.qml")
    check("screen: modelData" in palette,
          "lunana.iris-palette: palette needs the output screen (null breaks placement)")
    check("searchOpen = true" in palette,
          "lunana.iris-palette: host must drive GlobalStates.searchOpen like the chassis")

    orbit = host("lunana.iris-orbit", "IrisOrbit.qml")
    check("screen: modelData" in orbit,
          "lunana.iris-orbit: orbit needs the output screen")
    check("irisOrbitOpen = true" in orbit,
          "lunana.iris-orbit: host must drive GlobalStates.irisOrbitOpen (chassis hotcorner)")


def test_iris_test_hooks():
    """Test-only IPC hooks that make the nest-exerciseable what the harness
    cannot reach: the notification bus belongs to the host session and real
    volume keys do not exist in the nest. Each hook must stay wired to the
    exact render path it proves."""
    iris = REPO / "plugins" / "iris"
    osd = (iris / "lunana.iris-osd" / "IrisOsd.qml").read_text()
    check("function test(" in osd and "osdItem.show(" in osd,
          "lunana.iris-osd: test hook must drive the OSD render path directly")
    notif = (iris / "lunana.iris-notifications" / "IrisNotifications.qml").read_text()
    check("function test()" in notif and "popupList = [" in notif,
          "lunana.iris-notifications: test hook must inject into the popupList the banners read")
    check("popupList = []" in notif,
          "lunana.iris-notifications: test hook must clear after itself")


def test_hypr_windows_contract():
    """The Hyprland window-model mirror must publish every Niri-shaped field
    the orbit reads. On Hyprland-without-Niri, NiriService.windows /
    allWorkspaces stay empty upstream, so lunana.state mirrors Hyprland's
    models into exactly the shapes IrisOrbit consumes (actions stay Niri
    socket-bound and are documented reduced)."""
    orbit = (REPO / "vendor" / "modules" / "iris" / "orbit" / "IrisOrbit.qml").read_text()
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
    """Cycle ii -> waffle -> iris -> stock in a fixture HOME: exactly one
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


def test_suite_runs():
    r = subprocess.run([sys.executable, str(REPO / "scripts" / "lunana-suite"), "status"],
                       capture_output=True, text=True)
    check(r.returncode == 0, f"lunana-suite status exited {r.returncode}: {r.stderr.strip()}")
    r = subprocess.run([sys.executable, str(REPO / "scripts" / "lunana-suite"),
                        "install", "--dry-run"], capture_output=True, text=True)
    check(r.returncode == 0, f"lunana-suite install --dry-run exited {r.returncode}: {r.stderr.strip()}")


def test_shared_services_guarded():
    """The lunana.state outage (orbit/altswitcher silently empty on iris):
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


def main():
    for fn in (test_manifests, test_suite_matches_plugins, test_packaging_matches_plugins,
               test_vendor_closure, test_host_imports, test_sidebar_left_fallback,
               test_closeconfirm_hyprland,
               test_iris_lock_hosts, test_iris_satellite_wiring,
               test_iris_test_hooks, test_hypr_windows_contract,
               test_vendor_patch_lever,
               test_family_cycle, test_suite_runs, test_shared_services_guarded, test_hypr_config_adapters):
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
