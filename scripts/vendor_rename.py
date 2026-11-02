#!/usr/bin/env python3
"""vendor-rename.py — rebrand inir -> lunana across the lunana repo.

Applies the brand + family rename as ordered regex rules over file contents,
then renames files/dirs whose names carry brand tokens. Idempotent: re-running
is a no-op once applied.

Order of operations for a fresh vendor refresh:
    LUNANA_SRC=... python3 scripts/vendor.py <paths>
    python3 scripts/vendor.py --patch     # patches expect PRE-rename upstream text
    python3 scripts/vendor-rename.py       # this script (post-patch)

Deliberately NOT renamed (allowlists below):
- vendor/INIR-LICENSE ................ the upstream attribution itself
- vendor-patches/*.patch .............. diff hunks must match pre-rename vendor text
- docs/history/* ...................... timestamped historical log, immutable
- README.md ........................... rewritten by hand (credit section), not sed
- Translation source strings in non-English languages are protected by using
  word-boundary rules only (definir/redefinir/gezinirken never match).
- This script itself (its RULES contain the brand tokens as patterns).

Family mapping: ii -> drift, waffle -> slate, iris/iRiS -> atoll.
"""

from __future__ import annotations

import os
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent

# (pattern, replacement), applied in order. Case-sensitive throughout.
# NOTE: keep the left-hand sides frozen — this file skips itself so the
# patterns are never rewritten by a run.
RULES: list[tuple[str, str]] = [
    # --- product brand ---
    (r"iNiR", "Lunana"),
    (r"\bINIR\b", "LUNANA"),
    (r"INIR_", "LUNANA_"),
    (r"_INIR\b", "_LUNANA"),
    (r"\bInir(?=[A-Z])", "Lunana"),   # InirTUI
    (r"\bInir\b", "Lunana"),
    (r"\binir\b", "lunana"),
    (r"\binir_", "lunana_"),          # inir_config_file, ?inir_art=
    (r"\binir(?=[A-Z])", "lunana"),   # inirEverywhere, inirStyle, ...
    (r"_inir", "_lunana"),             # snake_case identifiers
    (r"\bisInir\b", "isLunana"),
    (r"\bquotedInir\b", "quotedLunana"),
    (r"\blibinir\b", "liblunana"),
    # --- iris family -> atoll ---
    (r"iRiS", "Atoll"),
    (r"\bIris(?=[A-Z])", "Atoll"),    # IrisBar, IrisStyle, ...
    (r"\bIris\b", "Atoll"),
    (r"([a-z0-9])Iris\b", r"\1Atoll"),  # widgetIris
    (r"onIris", "onAtoll"),               # signal handlers: onIrisEditChanged
    (r"onWaffle", "onSlate"),
    (r"onIi", "onDrift"),
    (r"\biris\b", "atoll"),
    (r"\biris(?=[A-Z])", "atoll"),    # irisEdit, irisBar, ...
    (r"_iris\b", "_atoll"),
    (r"IRIS_QML", "ATOLL_QML"),        # heredoc delimiter
    # --- waffle family -> slate ---
    (r"\bWaffle\b", "Slate"),
    (r"Waffle", "Slate"),              # mid-identifier: isWaffleActive
    (r"\bWAFFLE\b", "SLATE"),
    (r"\bwaffles\b", "slate"),         # config subtree + identifiers
    (r"\bwaffle\b", "slate"),
    (r"\bwaffle(?=[A-Z])", "slate"),   # waffleActionCenterOpen
    (r'"w([A-Z][A-Za-z]*)"', r'"slate\1"'),  # quoted panel ids only ("wBar")
    # --- ii family -> drift ---
    (r"\bii(?=[A-Z])", "drift"),       # iiBar, iiDock, ...
    (r"Ii(?=[A-Z])", "Drift"),         # isIiActive, ShellIiPanels, ...
    (r'"ii"', '"drift"'),
    (r"'ii'", "'drift'"),
    (r"/ii/", "/drift/"),
    (r"\bii\b", "drift"),
    # --- misc brand-adjacent ---
    (r"Windows 11", "Slate"),
    (r"Windows-11", "Slate"),
    (r"Win11", "Slate"),
    (r"\bW11\b", "Slate"),
]

# File/dir name token map (plain substring, longest first).
NAME_RULES: list[tuple[str, str]] = [
    ("inir", "lunana"),
    ("Inir", "Lunana"),
    ("INIR", "LUNANA"),
    ("iRiS", "Atoll"),
    ("Iris", "Atoll"),
    ("iris", "atoll"),
    ("Waffle", "Slate"),
    ("waffle", "slate"),
    ("Ii", "Drift"),
]

SKIP_DIRS = {".git", "__pycache__", "node_modules"}
SKIP_FILES = {"INIR-LICENSE", "vendor_rename.py"}
SKIP_TREES = {"vendor-patches", os.path.join("docs", "history")}
# Top-level README.md only (rewritten by hand with the credit section);
# nested READMEs are normal content and DO get renamed.


def should_skip(path: Path) -> bool:
    rel = path.relative_to(REPO).as_posix()
    if path.name in SKIP_FILES:
        return True
    if path.relative_to(REPO).as_posix() == "README.md":
        return True  # top-level README only; nested READMEs are renamed
    return any(rel == t or rel.startswith(t + "/") for t in SKIP_TREES)


def iter_files(roots: list[Path]):
    for root in roots:
        if not root.exists():
            continue
        if root.is_file():
            if not should_skip(root):
                yield root
            continue
        for dirpath, dirnames, filenames in os.walk(root):
            dirnames[:] = [d for d in dirnames if d not in SKIP_DIRS]
            for fn in filenames:
                p = Path(dirpath) / fn
                if should_skip(p):
                    continue
                yield p


# Literal strings that must never be rewritten (facts: the upstream checkout
# path and the credited source URL). Held out of the rule pass via
# placeholders so future runs keep them intact.
PROTECTED = {
    "/home/tenzin/development/inir": "\ue000UPSTREAM_CHECKOUT\ue001",
    "snowarch/inir": "\ue000UPSTREAM_REPO\ue001",
    "github.com/snowarch/inir": "\ue000UPSTREAM_URL\ue001",
    # Legacy-migration data (pre-rename ids the new world maps FROM).
    # These literals must survive verbatim or migration silently no-ops.
    '{"ii": "drift", "waffle": "slate", "iris": "atoll"}': "\ue000LEGACY_FAMS\ue001",
    '{ "ii": "drift", "waffle": "slate", "iris": "atoll" }': "\ue000LEGACY_FAMS_QML\ue001",
    '{"lunana.bar-waffle": "lunana.bar-slate"}': "\ue000LEGACY_BARS\ue001",
    '/^ii(?=[A-Z])/': "\ue000LEGACY_RE_II\ue001",
    '/^iris(?=[A-Z])/': "\ue000LEGACY_RE_IRIS\ue001",
}


def rename_content(text: str) -> str:
    for literal, holder in PROTECTED.items():
        text = text.replace(literal, holder)
    for pat, rep in RULES:
        text = re.sub(pat, rep, text)
    for literal, holder in PROTECTED.items():
        text = text.replace(holder, literal)
    return text


def rename_name(name: str) -> str:
    for old, new in NAME_RULES:
        name = name.replace(old, new)
    # Slate design-system types/files carry a bare W prefix (WBarPage,
    # WText, ...). Window/Wave/Wallpaper generics never match: their second
    # letter is lowercase.
    name = re.sub(r"^W(?=[A-Z][a-z])", "S", name)
    return name


ROOTS = ([REPO / r for r in
          ("vendor", "plugins", "scripts", "tests", "docs",
           "packaging", "contracts")]
         + [REPO / f for f in
            ("plan.md", "PORTING.md", "open.md", "open-fix.todo.md",
             "package-metadata.json")])


def main(argv: list[str]) -> int:
    roots = [r for r in ROOTS if r.exists()]

    content_changed = 0
    for path in iter_files(roots):
        try:
            text = path.read_text(encoding="utf-8")
        except (UnicodeDecodeError, OSError):
            continue  # binary blob (.qsb, fonts): filename rename still applies
        new = rename_content(text)
        if new != text:
            path.write_text(new, encoding="utf-8")
            content_changed += 1

    # File/dir renames, deepest first so parents move after children.
    all_paths: list[Path] = []
    for root in roots:
        if root.is_file():
            continue
        for dirpath, dirnames, filenames in os.walk(root):
            for n in dirnames + filenames:
                p = Path(dirpath) / n
                if should_skip(p):
                    continue
                all_paths.append(p)
    renamed = 0
    for path in sorted(all_paths, key=lambda p: -len(p.parts)):
        new_name = rename_name(path.name)
        if new_name != path.name:
            target = path.with_name(new_name)
            if target.exists():
                print(f"COLLISION (skipped): {path.relative_to(REPO)}", file=sys.stderr)
                continue
            path.rename(target)
            renamed += 1

    print(f"vendor-rename: {content_changed} files rewritten, {renamed} paths renamed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
