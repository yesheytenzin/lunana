#!/usr/bin/env python3
"""vendor.py — the vendoring lever for porting inir's GPL UI into lunana.

inir's QML imports its own code as fixed named modules (`import qs.modules.common`,
`import qs.services`, …) that Quickshell resolves against inir's config root. Inside
Omarchy's shell process the `qs` prefix is already claimed by Omarchy
(`qs.Commons`, `qs.Ui`), so vendored inir files cannot keep those imports. This tool
copies selected inir paths into lunana's `vendor/` tree (preserving inir's directory
structure, so its qmldir type sets stay intact) and rewrites every `import qs[.x]`
into the correct *relative-path* import for each file's depth — the pattern Omarchy
plugins use for their own modules (`import "subdir" as X`).

It is re-runnable: pointed at an updated inir checkout it re-vendors and re-rewrites,
so lunana can track inir changes. inir is GPL-3.0 and so is lunana; this is a
legitimate derivative — `vendor/INIR-LICENSE` preserves inir's license/attribution.

Usage:
    vendor.py <path> [<path> ...]      # inir paths (files or dirs), repo-relative
    vendor.py --list                   # show what's currently vendored
"""

from __future__ import annotations

import os
import re
import shutil
import sys
from pathlib import Path

INIR = Path(os.environ.get("INIR_SRC", "/home/tenzin/development/inir")).resolve()
LUNANA = Path(__file__).resolve().parent.parent
VENDOR = LUNANA / "vendor"

# `import qs[.a.b][ as Alias]` on its own line.
IMPORT_RE = re.compile(r'^(?P<indent>\s*)import\s+qs(?P<sub>(?:\.[A-Za-z0-9_]+)*)(?P<alias>\s+as\s+[A-Za-z0-9_]+)?\s*$')
# inir's Quickshell `import "root:[sub/path]"` (config-root-relative) on its own line.
ROOT_RE = re.compile(r'^(?P<indent>\s*)import\s+"root:(?P<sub>[^"]*)"(?P<alias>\s+as\s+[A-Za-z0-9_]+)?\s*$')


def qs_target_dir(sub: str) -> Path:
    """Map a `qs` import suffix (e.g. '.modules.common.functions') to its vendored dir."""
    rel = sub.lstrip(".").replace(".", "/") if sub else ""
    return (VENDOR / rel) if rel else VENDOR


def rewrite_imports(text: str, file_dir: Path) -> str:
    out = []
    for line in text.splitlines():
        m = IMPORT_RE.match(line)
        if m:
            target = qs_target_dir(m.group("sub"))
        else:
            m = ROOT_RE.match(line)
            if not m:
                out.append(line)
                continue
            # `root:` is inir's config root == our vendor/ root.
            target = VENDOR / m.group("sub") if m.group("sub") else VENDOR
        rel = os.path.relpath(target, file_dir)
        if rel == ".":
            rel = "."
        alias = m.group("alias") or ""
        out.append(f'{m.group("indent")}import "{rel}"{alias}')
    trailing = "\n" if text.endswith("\n") else ""
    return "\n".join(out) + trailing


def strip_module_line(qmldir_text: str) -> str:
    """Relative-path imports read a qmldir's type set but must not re-register a
    `qs.*` module URI, so drop the `module …` declaration from vendored qmldirs."""
    return "\n".join(l for l in qmldir_text.splitlines() if not l.strip().startswith("module "))


def vendor_path(rel_path: str) -> int:
    src = (INIR / rel_path).resolve()
    if not src.exists():
        print(f"vendor: not found in inir: {rel_path}", file=sys.stderr)
        return 0
    files = [src] if src.is_file() else [p for p in src.rglob("*") if p.is_file()]
    count = 0
    for f in files:
        rel = f.relative_to(INIR)
        dst = VENDOR / rel
        dst.parent.mkdir(parents=True, exist_ok=True)
        if f.name == "qmldir":
            dst.write_text(strip_module_line(f.read_text(encoding="utf-8")), encoding="utf-8")
        elif f.suffix in (".qml", ".js"):
            dst.write_text(rewrite_imports(f.read_text(encoding="utf-8"), dst.parent), encoding="utf-8")
        else:
            shutil.copy2(f, dst)  # shaders, images, json
        count += 1
    print(f"vendor: {rel_path} -> {count} file(s)")
    return count


def is_singleton(path: Path) -> bool:
    try:
        return "pragma Singleton" in path.read_text(encoding="utf-8")[:400]
    except OSError:
        return False


def regenerate_qmldirs() -> None:
    """inir relies on Quickshell's directory auto-registration (often no qmldir),
    but standard Qt relative-path imports need an explicit qmldir declaring each
    type — and `singleton` for pragma-Singleton files. Regenerate one per vendored
    directory from the files actually present, so the tree is self-consistent."""
    dirs = {p.parent for p in VENDOR.rglob("*.qml")}
    for d in sorted(dirs):
        lines = []
        for qml in sorted(d.glob("*.qml")):
            stem = qml.stem
            prefix = "singleton " if is_singleton(qml) else ""
            lines.append(f"{prefix}{stem} 1.0 {qml.name}")
        (d / "qmldir").write_text("\n".join(lines) + "\n", encoding="utf-8")


def write_attribution() -> None:
    VENDOR.mkdir(parents=True, exist_ok=True)
    lic = INIR / "LICENSE"
    if lic.is_file() and not (VENDOR / "INIR-LICENSE").exists():
        shutil.copy2(lic, VENDOR / "INIR-LICENSE")
    (VENDOR / "README.md").write_text(
        "# vendor/\n\n"
        "QML vendored from inir (https://github.com/snowarch/inir), GPL-3.0, with\n"
        "`import qs.*` rewritten to relative paths by `scripts/vendor.py`. Do not edit\n"
        "these files by hand — re-run the vendoring tool against an inir checkout.\n"
        "inir's license is preserved in `INIR-LICENSE`.\n",
        encoding="utf-8",
    )


def main(argv: list[str]) -> int:
    if not argv:
        print(__doc__)
        return 1
    if argv[0] == "--list":
        for p in sorted(VENDOR.rglob("*.qml")):
            print(p.relative_to(VENDOR))
        return 0
    if argv[0] == "--qmldir":
        regenerate_qmldirs()
        print("vendor: regenerated qmldirs")
        return 0
    if not INIR.is_dir():
        print(f"vendor: inir checkout not found at {INIR} (set INIR_SRC)", file=sys.stderr)
        return 1
    write_attribution()
    total = sum(vendor_path(p) for p in argv)
    regenerate_qmldirs()
    print(f"vendor: {total} file(s) total into {VENDOR}; qmldirs regenerated")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
