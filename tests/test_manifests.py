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
import subprocess
import sys
import tempfile
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
ID_RE = re.compile(r"^[A-Za-z0-9][A-Za-z0-9._-]*$")
KIND_ENTRY = {"bar": "bar", "overlay": "overlay", "menu": "menu", "panel": "panel"}
VENDOR_IMPORT_RE = re.compile(r'import\s+"(\.\./lunana-vendor/[^"]+)"')

failures = []


def check(cond, msg):
    if not cond:
        failures.append(msg)


def plugin_dirs():
    return sorted(p for p in REPO.glob("lunana.*") if (p / "manifest.json").is_file())


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
    family = (REPO / "lunana.family" / "family-cycle").read_text()
    for d in plugin_dirs():
        m = json.loads((d / "manifest.json").read_text())
        if m.get("x-lunana", {}).get("role") == "ui-probe":
            continue  # dev-only probe, manually assembled; never suite-installed
        owned = f'"{d.name}"' in suite or f'"{d.name}"' in family
        check(owned, f"neither suite nor family-cycle owns {d.name}")


def test_vendor_closure():
    """Every `import "../lunana-vendor/..."` in a plugin entry resolves in
    repo vendor/ (installed once as <config>/omarchy/lunana-vendor/)."""
    vendor = REPO / "vendor"
    for d in plugin_dirs():
        m = json.loads((d / "manifest.json").read_text())
        for rel in m.get("entryPoints", {}).values():
            text = (d / rel).read_text()
            for target in VENDOR_IMPORT_RE.findall(text):
                if target == "../lunana-vendor/":
                    # Root import: needs the root qmldir + at least GlobalStates.
                    check((vendor / "qmldir").is_file(), f"{d.name}: vendor/qmldir missing")
                    check((vendor / "GlobalStates.qml").is_file(),
                          f"{d.name}: vendor/GlobalStates.qml missing")
                    continue
                sub = target[len("../lunana-vendor/"):]
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


def _load_family_table():
    import importlib.util as ilu
    cycle = REPO / "lunana.family" / "family-cycle"
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
            return subprocess.run([sys.executable, str(REPO / "lunana.family" / "family-cycle"),
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
                seen.append(mod.current_family(shell)[0])
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


def main():
    for fn in (test_manifests, test_suite_matches_plugins, test_vendor_closure,
               test_host_imports, test_family_cycle, test_suite_runs):
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
