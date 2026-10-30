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
    vendor.py --patch                  # apply vendor-patches/*.patch onto vendor/

`vendor/` is never hand-edited: after any `vendor.py <path>` run that touches
a patched file, re-run `vendor.py --patch`. Patch files live in
`vendor-patches/`, mirroring the vendor tree (`services/Foo.qml.patch`
patches `vendor/services/Foo.qml`). They apply with zero fuzz and fail
loudly on drift so a changed upstream never misapplies silently; re-running
`--patch` is idempotent. Patches are lunana-local behavior the upstream tree
cannot carry — e.g. Omarchy's Lua dispatcher dialect, which is a syntax
error on stock Hyprland.
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


# inir resolves its own assets/scripts with `Quickshell.shellPath("x")`, which
# returns a path relative to the *shell root*. Re-hosted inside Omarchy's shell
# that root is omarchy-shell's own dir, not the vendored tree, so every such
# call (fonts, mascot assets, translations, the scripts/inir runtime + color/
# capture scripts — ~186 sites) resolves into Omarchy's tree where the file is
# absent. Rewrite each call to resolve against the installed shared vendored
# tree instead: <XDG_CONFIG_HOME|~/.config>/omarchy/lunana-vendor/<x>. The arg
# is preserved verbatim (string, template literal, or template with ${…}).
SHELLPATH_MARKER = "Quickshell.shellPath("
_SHELLPATH_PRE = ('((Quickshell.env("XDG_CONFIG_HOME") || '
                  '(Quickshell.env("HOME") + "/.config")) + '
                  '"/omarchy/lunana-vendor/" + (')
_SHELLPATH_POST = "))"


def rewrite_shellpath(text: str) -> str:
    """Replace each `Quickshell.shellPath(ARG)` with a concat that resolves ARG
    against the installed lunana-vendor tree. ARG is captured by scanning for
    the matching close paren while respecting nested brackets and string/
    template literals, so template literals with `${…}` survive intact.
    Idempotent: the replacement contains no `Quickshell.shellPath(`."""
    out = []
    i = 0
    n = len(text)
    while True:
        j = text.find(SHELLPATH_MARKER, i)
        if j < 0:
            out.append(text[i:])
            break
        out.append(text[i:j])
        k = j + len(SHELLPATH_MARKER)
        depth = 1
        arg_start = k
        quote = None
        while k < n and depth > 0:
            c = text[k]
            if quote:
                if c == "\\":
                    k += 2
                    continue
                if c == quote:
                    quote = None
                k += 1
                continue
            if c in ('"', "'", "`"):
                quote = c
            elif c in "([{":
                depth += 1
            elif c in ")]}":
                depth -= 1
                if depth == 0:
                    break
            k += 1
        arg = text[arg_start:k]  # k is at the matching ')'
        out.append(_SHELLPATH_PRE + arg + _SHELLPATH_POST)
        i = k + 1
    return "".join(out)


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
            dst.write_text(rewrite_shellpath(rewrite_imports(f.read_text(encoding="utf-8"), dst.parent)), encoding="utf-8")
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


PATCHES = LUNANA / "vendor-patches"


def _parse_hunks(patch_text):
    """Parse a unified diff into (header, [(old_start, old_lines, new_lines)]).
    Context and removal lines must match the target exactly; fuzz is zero so
    drift fails loudly instead of misapplying."""
    import re as _re
    hunks = []
    header = []
    cur = None
    raw = patch_text.splitlines()
    # Drop trailing empty entries from the file's final newline: in unified
    # format a bare blank line is always hunk context, never a separator.
    while raw and raw[-1] == "":
        raw.pop()
    for line in raw:
        m = _re.match(r"^@@ -(\d+)(?:,\d+)? \+(\d+)(?:,\d+)? @@", line)
        if m:
            cur = [int(m.group(1)), [], []]
            hunks.append(cur)
            continue
        if cur is None:
            header.append(line)
            continue
        if line.startswith("+++") or line.startswith("---"):
            header.append(line)
            cur = None
            continue
        if line.startswith("\\"):
            continue
        if line == "":
            cur[1].append("")
            cur[2].append("")
        elif line.startswith("+"):
            cur[2].append(line[1:])
        elif line.startswith("-"):
            cur[1].append(line[1:])
        elif line.startswith(" "):
            cur[1].append(line[1:])
            cur[2].append(line[1:])
        else:
            raise ValueError(f"bad patch line: {line!r}")
    return header, [(h[0], h[1], h[2]) for h in hunks]


def apply_patch_file(patch_path: Path) -> str:
    """Apply one vendor-patches/<tree>.patch onto vendor/. Per-hunk
    idempotency: hunks whose new text is already present are skipped; the
    rest must match their old text exactly or the patch fails loudly
    (vendor drift). This also tolerates editing a patch after a partial
    apply: only the missing hunks are applied."""
    rel = patch_path.relative_to(PATCHES)
    target_rel = str(rel)[:-len(".patch")]
    target = VENDOR / target_rel
    if not target.is_file():
        raise ValueError(f"patch target missing: {target_rel}")
    _header, hunks = _parse_hunks(patch_path.read_text(encoding="utf-8"))
    if not hunks:
        raise ValueError(f"no hunks in {patch_path}")
    lines = target.read_text(encoding="utf-8").splitlines()
    applied = 0
    for old_start, old_lines, new_lines in hunks:
        if new_lines and _find_block(lines, new_lines) is not None:
            continue  # already applied; skip
        at = _find_block(lines, old_lines)
        if at is None:
            raise ValueError(
                f"{target_rel}: hunk @@ -{old_start} does not match; "
                f"vendor file drifted — reconcile the patch")
        lines[at:at + len(old_lines)] = new_lines
        applied += 1
    if applied:
        target.write_text("\n".join(lines) + ("\n" if lines else ""), encoding="utf-8")
    return "applied" if applied else "already-applied"


def _find_block(lines, block):
    if not block:
        return 0
    for i in range(len(lines) - len(block) + 1):
        if lines[i:i + len(block)] == block:
            return i
    return None


def cmd_patch() -> int:
    if not PATCHES.is_dir():
        print("vendor: no vendor-patches/ dir; nothing to do")
        return 0
    patches = sorted(PATCHES.rglob("*.patch"))
    if not patches:
        print("vendor: no patches; nothing to do")
        return 0
    results = []
    for p in patches:
        try:
            results.append((p, apply_patch_file(p)))
        except ValueError as exc:
            print(f"vendor: PATCH FAILED: {exc}", file=sys.stderr)
            return 1
    for p, status in results:
        print(f"vendor: {p.relative_to(PATCHES)} ... {status}")
    return 0


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
    if argv[0] == "--shellpath":
        # Apply the shellPath rewrite to the already-vendored tree in place,
        # without re-pulling from inir (no drift risk). Idempotent.
        changed = 0
        for f in sorted(list(VENDOR.rglob("*.qml")) + list(VENDOR.rglob("*.js"))):
            before = f.read_text(encoding="utf-8")
            after = rewrite_shellpath(before)
            if after != before:
                f.write_text(after, encoding="utf-8")
                changed += 1
        print(f"vendor: shellPath rewrite applied to {changed} file(s) in {VENDOR}")
        return 0
    if argv[0] == "--patch":
        return cmd_patch()
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
