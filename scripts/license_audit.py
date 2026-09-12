#!/usr/bin/env python3
"""Audit a project's dependency tree against the permissive-license allowlist.

Usage:
  license_audit.py [PATH] [--json] [--strict] [--allow-file FILE] [--ecosystem npm|python|go|rust ...]

Detects ecosystems from manifests in PATH (default: current directory):
  package.json            -> npm    via `npx license-checker-rseidelsohn` (BSD-3-Clause)
  pyproject.toml / requirements*.txt
                          -> python via `uv run --with pip-licenses pip-licenses` (MIT), or pip-licenses on PATH
  go.mod                  -> go     via `go-licenses csv ./...` (Apache-2.0)
  Cargo.toml              -> rust   via `cargo license --json` (MIT OR Apache-2.0)

Every license string is normalised to an SPDX id and checked against the allowlist in
skills/community.json (`license_allowlist` + `dependency_license_allowlist_extra`). SPDX
expressions are honoured: `A OR B` passes if any side passes, `A AND B` only if all do.
Entries in `dependency_license_warnlist` (weak copyleft such as MPL-2.0) warn; --strict
turns warnings into failures. Unknown, custom or missing licenses fail.

Exceptions: a file (default `license-audit.allow.txt` in PATH) with one package name per
line and a `# reason`; matching packages are reported as `allowed-by-exception`.

Exit codes: 0 clean, 1 violations, 2 no ecosystem tool could run.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
DEFAULT_ALLOW = ["MIT", "MIT-0", "Apache-2.0", "BSD-2-Clause", "BSD-3-Clause", "ISC", "0BSD",
                 "Unlicense", "Zlib", "PostgreSQL"]
DEFAULT_EXTRA = ["PSF-2.0", "Python-2.0", "CC0-1.0", "BlueOak-1.0.0", "MIT-CMU", "X11",
                 "BSD-1-Clause", "Apache-2.0 WITH LLVM-exception"]
DEFAULT_WARN = ["MPL-2.0"]

# Free-text names that package managers emit, lower-cased -> SPDX id
SYNONYMS = {
    "mit": "MIT", "mit license": "MIT", "the mit license": "MIT", "expat": "MIT", "mit/x11": "MIT",
    "mit-0": "MIT-0", "mit no attribution": "MIT-0",
    "apache": "Apache-2.0", "apache 2": "Apache-2.0", "apache 2.0": "Apache-2.0", "apache-2": "Apache-2.0",
    "apache-2.0": "Apache-2.0", "apache license 2.0": "Apache-2.0", "apache license, version 2.0": "Apache-2.0",
    "apache software license": "Apache-2.0", "apache software license 2.0": "Apache-2.0", "asl 2.0": "Apache-2.0",
    "bsd": "BSD-3-Clause", "bsd license": "BSD-3-Clause", "new bsd": "BSD-3-Clause", "new bsd license": "BSD-3-Clause",
    "modified bsd": "BSD-3-Clause", "bsd-3": "BSD-3-Clause", "bsd 3-clause": "BSD-3-Clause", "bsd-3-clause": "BSD-3-Clause",
    "bsd 3-clause license": "BSD-3-Clause", "3-clause bsd": "BSD-3-Clause",
    "bsd-2": "BSD-2-Clause", "bsd 2-clause": "BSD-2-Clause", "bsd-2-clause": "BSD-2-Clause", "simplified bsd": "BSD-2-Clause",
    "freebsd": "BSD-2-Clause", "0bsd": "0BSD", "bsd zero clause license": "0BSD", "bsd-1-clause": "BSD-1-Clause",
    "isc": "ISC", "isc license": "ISC", "isc license (iscl)": "ISC",
    "python software foundation license": "PSF-2.0", "psf": "PSF-2.0", "psf-2.0": "PSF-2.0", "python-2.0": "Python-2.0",
    "zlib": "Zlib", "zlib/libpng": "Zlib", "zlib license": "Zlib",
    "unlicense": "Unlicense", "the unlicense": "Unlicense", "public domain": "Unlicense",
    "cc0": "CC0-1.0", "cc0-1.0": "CC0-1.0", "cc0 1.0 universal": "CC0-1.0",
    "blueoak-1.0.0": "BlueOak-1.0.0", "blue oak model license 1.0.0": "BlueOak-1.0.0",
    "postgresql": "PostgreSQL", "postgresql license": "PostgreSQL",
    "x11": "X11", "mit-cmu": "MIT-CMU",
    "mpl-2.0": "MPL-2.0", "mpl 2.0": "MPL-2.0", "mozilla public license 2.0": "MPL-2.0",
    "mozilla public license 2.0 (mpl 2.0)": "MPL-2.0",
    "lgpl": "LGPL-2.1", "lgpl-2.1": "LGPL-2.1", "lgpl-3.0": "LGPL-3.0", "gpl": "GPL-2.0", "gpl-2.0": "GPL-2.0",
    "gpl-3.0": "GPL-3.0", "agpl-3.0": "AGPL-3.0", "gnu general public license v3 (gplv3)": "GPL-3.0",
    "gnu lesser general public license v3 (lgplv3)": "LGPL-3.0", "gnu affero general public license v3": "AGPL-3.0",
}


def load_lists() -> tuple[set[str], set[str]]:
    allow, warn = set(DEFAULT_ALLOW) | set(DEFAULT_EXTRA), set(DEFAULT_WARN)
    cfg = REPO_ROOT / "skills" / "community.json"
    if cfg.exists():
        data = json.loads(cfg.read_text(encoding="utf-8"))
        allow = set(data.get("license_allowlist", DEFAULT_ALLOW)) | set(data.get("dependency_license_allowlist_extra", DEFAULT_EXTRA))
        warn = set(data.get("dependency_license_warnlist", DEFAULT_WARN))
    return allow, warn


def to_spdx(token: str) -> str:
    t = token.strip().strip("()").strip()
    if not t:
        return "UNKNOWN"
    low = t.lower()
    if low in SYNONYMS:
        return SYNONYMS[low]
    # already SPDX-looking (case-insensitive match against known ids)
    known = set(DEFAULT_ALLOW) | set(DEFAULT_EXTRA) | set(DEFAULT_WARN) | set(SYNONYMS.values())
    for k in known:
        if k.lower() == low:
            return k
    return t  # unknown string, reported verbatim


def evaluate(expr: str, allow: set[str], warn: set[str]) -> tuple[str, str]:
    """Return (status, normalised) where status is ok | warn | fail."""
    if not expr or expr.strip().upper() in {"UNKNOWN", "UNLICENSED", "NONE", "SEE LICENSE IN LICENSE"}:
        return "fail", "UNKNOWN"
    expr = expr.strip()
    # pip-licenses joins several classifiers with "; " — treat as alternatives (dual licensing)
    if ";" in expr and " AND " not in expr.upper():
        expr = " OR ".join(p.strip() for p in expr.split(";") if p.strip())
    upper = expr.upper()
    if " OR " in upper:
        parts = re.split(r"\s+OR\s+", expr, flags=re.I)
        results = [evaluate(p, allow, warn) for p in parts]
        norm = " OR ".join(r[1] for r in results)
        if any(r[0] == "ok" for r in results):
            return "ok", norm
        if any(r[0] == "warn" for r in results):
            return "warn", norm
        return "fail", norm
    if " AND " in upper:
        parts = re.split(r"\s+AND\s+", expr, flags=re.I)
        results = [evaluate(p, allow, warn) for p in parts]
        norm = " AND ".join(r[1] for r in results)
        if all(r[0] == "ok" for r in results):
            return "ok", norm
        if any(r[0] == "fail" for r in results):
            return "fail", norm
        return "warn", norm
    spdx = to_spdx(expr)
    if spdx in allow:
        return "ok", spdx
    if spdx in warn:
        return "warn", spdx
    return "fail", spdx


def run(cmd: list[str], cwd: Path) -> tuple[int, str, str]:
    exe = shutil.which(cmd[0])
    if not exe:
        return 127, "", f"{cmd[0]} not found"
    p = subprocess.run([exe, *cmd[1:]], cwd=str(cwd), capture_output=True, text=True)
    return p.returncode, p.stdout, p.stderr


def scan_npm(path: Path) -> tuple[list[dict], str | None]:
    if not (path / "package.json").exists():
        return [], None
    code, out, err = run(["npx", "-y", "license-checker-rseidelsohn", "--json", "--production", "--start", str(path)], path)
    if code != 0:
        return [], f"npm: license-checker failed ({err.strip()[:200]})"
    data = json.loads(out or "{}")
    rows = []
    for key, meta in data.items():
        lic = meta.get("licenses", "UNKNOWN")
        if isinstance(lic, list):
            lic = " OR ".join(lic)
        name, _, version = key.rpartition("@")
        rows.append({"ecosystem": "npm", "name": name or key, "version": version, "license": str(lic)})
    return rows, None


def scan_python(path: Path) -> tuple[list[dict], str | None]:
    if not any((path / f).exists() for f in ("pyproject.toml", "requirements.txt", "requirements-dev.txt", "setup.py", "Pipfile")):
        return [], None
    if shutil.which("uv") and (path / "pyproject.toml").exists():
        code, out, err = run(["uv", "run", "--project", str(path), "--with", "pip-licenses", "pip-licenses", "--format=json"], path)
    elif shutil.which("pip-licenses"):
        code, out, err = run(["pip-licenses", "--format=json"], path)
        err = (err + "\nnote: pip-licenses inspected the *current* environment; activate the project venv first").strip()
    else:
        return [], "python: neither uv nor pip-licenses available (uv tool install pip-licenses)"
    if code != 0:
        return [], f"python: pip-licenses failed ({err.strip()[:200]})"
    rows = [{"ecosystem": "python", "name": r.get("Name"), "version": r.get("Version"), "license": r.get("License", "UNKNOWN")}
            for r in json.loads(out or "[]")]
    return rows, None


def scan_go(path: Path) -> tuple[list[dict], str | None]:
    if not (path / "go.mod").exists():
        return [], None
    code, out, err = run(["go-licenses", "csv", "./..."], path)
    if code != 0:
        return [], f"go: go-licenses failed or missing (go install github.com/google/go-licenses@latest) {err.strip()[:120]}"
    rows = []
    for line in out.splitlines():
        parts = line.strip().split(",")
        if len(parts) >= 3:
            rows.append({"ecosystem": "go", "name": parts[0], "version": "", "license": parts[2]})
    return rows, None


def scan_rust(path: Path) -> tuple[list[dict], str | None]:
    if not (path / "Cargo.toml").exists():
        return [], None
    code, out, err = run(["cargo", "license", "--json"], path)
    if code != 0:
        return [], f"rust: cargo license failed or missing (cargo install cargo-license) {err.strip()[:120]}"
    rows = [{"ecosystem": "rust", "name": r.get("name"), "version": r.get("version"), "license": r.get("license") or "UNKNOWN"}
            for r in json.loads(out or "[]")]
    return rows, None


SCANNERS = {"npm": scan_npm, "python": scan_python, "go": scan_go, "rust": scan_rust}


def load_exceptions(path: Path) -> dict[str, str]:
    if not path.exists():
        return {}
    out: dict[str, str] = {}
    for line in path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        name, _, reason = line.partition("#")
        out[name.strip()] = reason.strip() or "no reason given"
    return out


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("path", nargs="?", default=".")
    ap.add_argument("--json", action="store_true", help="machine-readable output")
    ap.add_argument("--strict", action="store_true", help="treat warnings (weak copyleft) as failures")
    ap.add_argument("--allow-file", default=None, help="exceptions file (default PATH/license-audit.allow.txt)")
    ap.add_argument("--ecosystem", action="append", choices=list(SCANNERS), help="limit to ecosystems")
    args = ap.parse_args()

    path = Path(args.path).resolve()
    allow, warn = load_lists()
    exceptions = load_exceptions(Path(args.allow_file) if args.allow_file else path / "license-audit.allow.txt")

    rows: list[dict] = []
    notes: list[str] = []
    ran = 0
    for eco, fn in SCANNERS.items():
        if args.ecosystem and eco not in args.ecosystem:
            continue
        found, note = fn(path)
        if note:
            notes.append(note)
        elif found or (path / {"npm": "package.json", "python": "pyproject.toml", "go": "go.mod", "rust": "Cargo.toml"}[eco]).exists():
            ran += 1
        rows.extend(found)

    for r in rows:
        status, norm = evaluate(r["license"], allow, warn)
        if status != "ok" and r["name"] in exceptions:
            status, r["exception"] = "allowed-by-exception", exceptions[r["name"]]
        if status == "warn" and args.strict:
            status = "fail"
        r["status"], r["spdx"] = status, norm

    fails = [r for r in rows if r["status"] == "fail"]
    warns = [r for r in rows if r["status"] == "warn"]
    excs = [r for r in rows if r["status"] == "allowed-by-exception"]

    if args.json:
        print(json.dumps({"path": str(path), "checked": len(rows), "fail": fails, "warn": warns,
                          "exceptions": excs, "notes": notes}, indent=2))
    else:
        print(f"license audit: {path}")
        print(f"  packages checked: {len(rows)}   ok: {len(rows) - len(fails) - len(warns) - len(excs)}   "
              f"warn: {len(warns)}   exceptions: {len(excs)}   FAIL: {len(fails)}")
        for label, group in (("FAIL", fails), ("WARN", warns), ("EXCEPTION", excs)):
            for r in group:
                extra = f"  ({r['exception']})" if "exception" in r else ""
                print(f"  [{label}] {r['ecosystem']:6} {r['name']}@{r['version']}: {r['license']} -> {r['spdx']}{extra}")
        for n in notes:
            print(f"  note: {n}")
        if ran == 0 and not rows:
            print("  no ecosystem could be scanned (no manifest, or tools missing); see notes")

    if ran == 0 and not rows:
        return 2
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main())
