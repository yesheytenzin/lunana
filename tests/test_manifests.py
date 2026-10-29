#!/usr/bin/env python3
"""Smoke test: every lunana plugin manifest matches the Omarchy schema, entry
points exist, and the suite parses and runs read-only. Pure stdlib; run with:

    python3 tests/test_manifests.py
"""

import json
import re
import subprocess
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
ID_RE = re.compile(r"^[A-Za-z0-9][A-Za-z0-9._-]*$")
KIND_ENTRY = {"bar": "bar", "overlay": "overlay", "menu": "menu", "panel": "panel"}

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
    text = (REPO / "scripts" / "lunana-suite").read_text()
    for d in plugin_dirs():
        m = json.loads((d / "manifest.json").read_text())
        if m.get("x-lunana", {}).get("role") == "ui-probe":
            continue  # dev-only probe, manually assembled; never suite-installed
        check(f'"{d.name}"' in text, f"suite MANAGED_PLUGINS missing {d.name}")


def test_suite_runs():
    r = subprocess.run([sys.executable, str(REPO / "scripts" / "lunana-suite"), "status"],
                       capture_output=True, text=True)
    check(r.returncode == 0, f"lunana-suite status exited {r.returncode}: {r.stderr.strip()}")


def main():
    for fn in (test_manifests, test_suite_matches_plugins, test_suite_runs):
        try:
            fn()
        except Exception as exc:  # noqa: BLE001
            failures.append(f"{fn.__name__} raised {exc!r}")
    if failures:
        print(f"FAIL ({len(failures)}):")
        for f in failures:
            print(f"  - {f}")
        return 1
    print(f"PASS — {len(plugin_dirs())} plugins, manifests valid, suite OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
