#!/usr/bin/env python3
"""Validate the repository: JSON, YAML, TOML syntax; skill frontmatter; alias consistency.

Run via scripts/validate.sh or scripts/validate.ps1. Exit code 1 on any failure.
Requires Python 3.11+ (tomllib). PyYAML is optional; without it YAML files are skipped.
"""

from __future__ import annotations

import json
import re
import sys
import tomllib
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SKIP_DIRS = {".git", "node_modules", ".venv", "__pycache__"}
errors: list[str] = []
checked = 0


def files(*suffixes: str):
    for p in ROOT.rglob("*"):
        if any(part in SKIP_DIRS for part in p.parts):
            continue
        if p.is_file() and p.suffix in suffixes:
            yield p


def rel(p: Path) -> str:
    return p.relative_to(ROOT).as_posix()


def check_json() -> None:
    global checked
    for p in files(".json"):
        checked += 1
        try:
            json.loads(p.read_text(encoding="utf-8"))
        except json.JSONDecodeError as e:
            errors.append(f"{rel(p)}: invalid JSON: {e}")


def check_yaml() -> dict[str, dict]:
    global checked
    loaded: dict[str, dict] = {}
    try:
        import yaml  # type: ignore
    except ImportError:
        print("note: PyYAML not installed; YAML files skipped (pip install pyyaml)")
        return loaded
    class TolerantLoader(yaml.SafeLoader):
        """SafeLoader that accepts Compose tags such as !override and !reset."""

    def _passthrough(loader, tag_suffix, node):  # noqa: ANN001
        if isinstance(node, yaml.SequenceNode):
            return loader.construct_sequence(node)
        if isinstance(node, yaml.MappingNode):
            return loader.construct_mapping(node)
        return loader.construct_scalar(node)

    TolerantLoader.add_multi_constructor("!", _passthrough)

    for p in files(".yaml", ".yml"):
        checked += 1
        try:
            data = yaml.load(p.read_text(encoding="utf-8"), Loader=TolerantLoader)
            loaded[rel(p)] = data if isinstance(data, dict) else {}
        except yaml.YAMLError as e:
            errors.append(f"{rel(p)}: invalid YAML: {e}")
    return loaded


def check_toml() -> None:
    global checked
    for p in files(".toml"):
        checked += 1
        try:
            tomllib.loads(p.read_text(encoding="utf-8"))
        except tomllib.TOMLDecodeError as e:
            errors.append(f"{rel(p)}: invalid TOML: {e}")


FRONTMATTER = re.compile(r"^---\r?\n(.*?)\r?\n---\r?\n", re.S)
NAME_RE = re.compile(r"^[a-z0-9]+(-[a-z0-9]+)*$")


def parse_frontmatter(text: str) -> dict[str, str] | None:
    m = FRONTMATTER.match(text)
    if not m:
        return None
    out: dict[str, str] = {}
    for line in m.group(1).splitlines():
        if ":" in line and not line.startswith((" ", "\t")):
            k, v = line.split(":", 1)
            out[k.strip()] = v.strip().strip("\"'")
    return out


def check_skills() -> None:
    global checked
    for skill_md in ROOT.rglob("SKILL.md"):
        if any(part in SKIP_DIRS for part in skill_md.parts):
            continue
        checked += 1
        fm = parse_frontmatter(skill_md.read_text(encoding="utf-8"))
        where = rel(skill_md)
        if fm is None:
            errors.append(f"{where}: missing YAML frontmatter")
            continue
        name = fm.get("name", "")
        desc = fm.get("description", "")
        folder = skill_md.parent.name
        if not name:
            errors.append(f"{where}: frontmatter missing 'name'")
        elif not NAME_RE.match(name) or len(name) > 64:
            errors.append(f"{where}: invalid name '{name}' (lowercase, hyphens, <=64 chars)")
        elif name != folder:
            errors.append(f"{where}: name '{name}' != folder '{folder}'")
        if not desc:
            errors.append(f"{where}: frontmatter missing 'description'")
        elif len(desc) > 1024:
            errors.append(f"{where}: description longer than 1024 chars")
        body_lines = skill_md.read_text(encoding="utf-8").count("\n")
        if body_lines > 500:
            errors.append(f"{where}: SKILL.md has {body_lines} lines (>500); move detail to references/")


def check_agents_and_commands() -> None:
    """OpenCode agent/command markdown needs frontmatter with a description."""
    global checked
    for sub in ("clients/opencode/agents", "clients/opencode/commands"):
        d = ROOT / sub
        if not d.is_dir():
            continue
        for p in d.glob("*.md"):
            checked += 1
            fm = parse_frontmatter(p.read_text(encoding="utf-8"))
            if fm is None or not fm.get("description"):
                errors.append(f"{rel(p)}: missing frontmatter or 'description'")


def check_alias_consistency(yamls: dict[str, dict]) -> None:
    """Every fallback target in a LiteLLM config must be a model_name in the same file,
    and every model in the OpenCode configs must exist in the personal gateway config."""
    for name, data in yamls.items():
        if not name.startswith("gateway/config/"):
            continue
        model_names = {m.get("model_name") for m in data.get("model_list", []) if isinstance(m, dict)}
        rs = data.get("router_settings", {}) or {}
        for key in ("fallbacks", "context_window_fallbacks"):
            for entry in rs.get(key, []) or []:
                for src, targets in entry.items():
                    if src not in model_names:
                        errors.append(f"{name}: {key} source '{src}' is not a model_name")
                    for t in targets:
                        if t not in model_names:
                            errors.append(f"{name}: {key} target '{t}' (for {src}) is not a model_name")
        for alias, target in (rs.get("model_group_alias") or {}).items():
            if target not in model_names:
                errors.append(f"{name}: model_group_alias '{alias}' -> '{target}' is not a model_name")

    personal = yamls.get("gateway/config/litellm.personal.yaml")
    if personal:
        gw = {m.get("model_name") for m in personal.get("model_list", [])}
        oc = ROOT / "clients/opencode/opencode.json"
        if oc.exists():
            models = json.loads(oc.read_text(encoding="utf-8"))["provider"]["litellm"]["models"]
            for m in models:
                if m not in gw:
                    errors.append(f"clients/opencode/opencode.json: model '{m}' not served by litellm.personal.yaml")


def check_licenses() -> None:
    """Every recommended third-party entry must carry a permissive license from the allowlist
    (skills/community.json) or be a hosted `service`. Excluded entries are exempt."""
    community = ROOT / "skills/community.json"
    if not community.exists():
        return
    data = json.loads(community.read_text(encoding="utf-8"))
    allow = set(data.get("license_allowlist", []))
    if not allow:
        errors.append("skills/community.json: license_allowlist is empty")
        return

    def ok(license_value: str) -> bool:
        return license_value in allow or license_value == "service"

    for name, entry in data.get("skills", {}).items():
        lic = entry.get("license", "")
        if not ok(lic):
            errors.append(f"skills/community.json: '{name}' license '{lic}' is not in the allowlist; move it under 'excluded' with a reason")
        if "safety" not in entry:
            errors.append(f"skills/community.json: '{name}' has no 'safety' block")
    for name, entry in data.get("excluded", {}).items():
        if not entry.get("reason"):
            errors.append(f"skills/community.json: excluded '{name}' needs a 'reason'")
    for group in data.get("rules", {}).values():
        if isinstance(group, list):
            for n in group:
                if n not in data.get("skills", {}):
                    errors.append(f"skills/community.json: rules reference '{n}', which is not a recommended skill")

    catalog = ROOT / "mcp/catalog.json"
    if catalog.exists():
        servers = json.loads(catalog.read_text(encoding="utf-8")).get("servers", {})
        for name, entry in servers.items():
            lic = entry.get("license", "")
            if not ok(lic):
                errors.append(f"mcp/catalog.json: '{name}' license '{lic}' is not in the allowlist (or 'service')")
            if "safety" not in entry:
                errors.append(f"mcp/catalog.json: '{name}' has no 'safety' block")


def main() -> int:
    check_json()
    yamls = check_yaml()
    check_toml()
    check_skills()
    check_agents_and_commands()
    check_alias_consistency(yamls)
    check_licenses()
    if errors:
        print(f"FAILED: {len(errors)} problem(s) in {checked} checked files")
        for e in errors:
            print(" -", e)
        return 1
    print(f"OK: {checked} files checked")
    return 0


if __name__ == "__main__":
    sys.exit(main())
