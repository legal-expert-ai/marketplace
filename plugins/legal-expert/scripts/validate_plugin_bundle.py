#!/usr/bin/env python3
"""Run portable structural and secret-hygiene checks for the Legal Expert plugin."""

from __future__ import annotations

import json
import re
import struct
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
REQUIRED_SKILLS = {
    "research-romanian-law",
    "analyze-legal-document",
    "ocr-legal-document",
    "review-contract-changes",
    "verify-signed-document",
    "manage-legal-library",
    "legal-tabular-research",
}
FORBIDDEN_TEXT = (
    "/" + "Users/",
    "legal-expert-" + "env/backend",
    "BEGIN " + "PRIVATE KEY",
)
SECRET_PATTERNS = (
    re.compile(r"\b(?:sk|ghp|glpat)-[A-Za-z0-9_-]{16,}\b"),
    re.compile(r"\beyJ[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\b"),
)
REQUIRED_LIBRARY_TOOLS = {
    "list_document_folders",
    "list_document_bundles",
    "get_document_bundle",
    "upload_document_bundle",
    "read_document_file",
    "search_document_contents",
    "list_document_events",
    "read_agent_task_output_content",
    "read_agent_task_output_base64",
    "get_notification_preferences",
    "update_notification_preferences",
    "send_whatsapp_verification_code",
    "confirm_whatsapp_verification_code",
}
EXPECTED_LIBRARY_TOOL_COUNT = 13
OUTPUT_READER_SKILLS = {
    "analyze-legal-document",
    "manage-legal-library",
    "ocr-legal-document",
    "review-contract-changes",
    "verify-signed-document",
}
OAUTH_DIAGNOSTIC_MARKERS = (
    "**Unavailable:**",
    "**Unauthorized:**",
    "**Missing tool:**",
)
FAIL_CLOSED_MCP_URL = "https://legal-expert-backend-feat-public-mcp-agent-tasks.docker.d.com.ro/mcp"
SEMVER_PATTERN = re.compile(
    r"^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)"
    r"(?:-[0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*)?"
    r"(?:\+[0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*)?$"
)
STALE_TOOL_NAMES = {
    "list_library_folders",
    "list_bundle_files",
    "read_bundle_file",
    "get_bundle_analysis",
    "list_bundle_events",
    "begin_document_bundle_upload",
    "finalize_document_bundle_upload",
    "preview_notification_impact",
    "get_law_version_article",
    "get_law_history",
    "get_law_links",
}


def load_json(path: Path, errors: list[str]) -> dict[str, object]:
    try:
        payload = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        errors.append(f"{path.relative_to(ROOT)}: invalid JSON ({exc})")
        return {}
    if not isinstance(payload, dict):
        errors.append(f"{path.relative_to(ROOT)}: expected an object")
        return {}
    return payload


def parse_skill_frontmatter(path: Path, errors: list[str]) -> tuple[str, str]:
    text = path.read_text(encoding="utf-8")
    match = re.match(r"\A---\n(.*?)\n---\n", text, re.DOTALL)
    if not match:
        errors.append(f"{path.relative_to(ROOT)}: missing YAML frontmatter")
        return "", text
    name_match = re.search(r"^name:\s*[\"']?([^\"'\n]+)", match.group(1), re.MULTILINE)
    name = name_match.group(1).strip() if name_match else ""
    if not name:
        errors.append(f"{path.relative_to(ROOT)}: missing skill name")
    return name, text


def validate_references(path: Path, text: str, errors: list[str]) -> None:
    for target in re.findall(r"\[[^\]]+\]\(([^)#]+)(?:#[^)]+)?\)", text):
        if "://" in target or target.startswith("#"):
            continue
        resolved = (path.parent / target).resolve()
        if not resolved.is_file():
            errors.append(f"{path.relative_to(ROOT)}: missing referenced file {target}")


def validate_plugin(root: Path = ROOT) -> list[str]:
    errors: list[str] = []
    manifest = load_json(root / ".codex-plugin" / "plugin.json", errors)
    if manifest.get("name") != "legal-expert":
        errors.append("plugin manifest name must be legal-expert")
    if manifest.get("skills") != "./skills/":
        errors.append("plugin manifest must discover ./skills/")
    if manifest.get("mcpServers") != "./.mcp.json":
        errors.append("plugin manifest must reference ./.mcp.json")
    version = manifest.get("version")
    if not isinstance(version, str) or SEMVER_PATTERN.fullmatch(version) is None:
        errors.append("plugin manifest version must use strict semantic versioning")
    elif not version.startswith("0.3.0"):
        errors.append("Windows OAuth release must use the 0.3.0 semantic version")

    interface = manifest.get("interface")
    screenshots = interface.get("screenshots") if isinstance(interface, dict) else None
    if screenshots != ["./assets/product-overview.png"]:
        errors.append("plugin manifest must declare the product overview screenshot")
    else:
        screenshot_path = root / "assets" / "product-overview.png"
        try:
            with screenshot_path.open("rb") as screenshot:
                signature = screenshot.read(24)
            if signature[:8] != b"\x89PNG\r\n\x1a\n" or len(signature) != 24:
                errors.append("product overview screenshot must be a valid PNG")
            else:
                width, height = struct.unpack(">II", signature[16:24])
                if width < 1200 or height < 675:
                    errors.append("product overview screenshot must be at least 1200x675")
                if not 1.7 <= width / height <= 1.8:
                    errors.append("product overview screenshot must use a 16:9 landscape ratio")
        except OSError:
            errors.append("product overview screenshot is missing")

    mcp = load_json(root / ".mcp.json", errors)
    servers = mcp.get("mcpServers") if isinstance(mcp, dict) else None
    legal = servers.get("legal-expert") if isinstance(servers, dict) else None
    if not isinstance(legal, dict):
        errors.append(".mcp.json must define the legal-expert server")
    else:
        if legal.get("type") != "http":
            errors.append("legal-expert MCP must use native Streamable HTTP")
        if legal.get("url") != FAIL_CLOSED_MCP_URL:
            errors.append("legal-expert MCP must remain fail-closed until the production OAuth endpoint is approved")
        if set(legal) != {"type", "url"}:
            errors.append("legal-expert MCP OAuth config must not inject credentials or transport wrappers")

    skill_dirs = {path.name for path in (root / "skills").iterdir() if (path / "SKILL.md").is_file()}
    missing = sorted(REQUIRED_SKILLS - skill_dirs)
    extra_alias = "build-legal-research-table" in skill_dirs
    if missing:
        errors.append(f"missing required skills: {', '.join(missing)}")
    if extra_alias:
        errors.append("obsolete build-legal-research-table alias remains")

    for skill_dir in sorted((root / "skills").iterdir()):
        skill_md = skill_dir / "SKILL.md"
        if not skill_md.is_file():
            continue
        name, text = parse_skill_frontmatter(skill_md, errors)
        if name != skill_dir.name:
            errors.append(f"{skill_md.relative_to(root)}: name must match directory")
        for marker in OAUTH_DIAGNOSTIC_MARKERS:
            if marker not in text:
                errors.append(f"{skill_md.relative_to(root)}: missing connection diagnostic {marker}")
        metadata = skill_dir / "agents" / "openai.yaml"
        if not metadata.is_file():
            errors.append(f"{skill_dir.relative_to(root)}: missing agents/openai.yaml")
        elif f"${name}" not in metadata.read_text(encoding="utf-8"):
            errors.append(f"{metadata.relative_to(root)}: default_prompt must mention ${name}")
        validate_references(skill_md, text, errors)

    for path in root.rglob("*"):
        if not path.is_file() or ".pyc" in path.suffix:
            continue
        try:
            text = path.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            continue
        relative = path.relative_to(root)
        if "[" + "TODO:" in text:
            errors.append(f"{relative}: unresolved TODO marker")
        for forbidden in FORBIDDEN_TEXT:
            if forbidden in text:
                errors.append(f"{relative}: contains forbidden private/source path or secret marker")
        for pattern in SECRET_PATTERNS:
            if pattern.search(text):
                errors.append(f"{relative}: resembles an embedded credential")

    library_contract = (root / "skills" / "manage-legal-library" / "references" / "document-tool-contracts.md").read_text(encoding="utf-8")
    if len(REQUIRED_LIBRARY_TOOLS) != EXPECTED_LIBRARY_TOOL_COUNT:
        errors.append(
            f"document tool contract expects {EXPECTED_LIBRARY_TOOL_COUNT} tools, "
            f"but validator declares {len(REQUIRED_LIBRARY_TOOLS)}"
        )
    for tool in sorted(REQUIRED_LIBRARY_TOOLS):
        if tool not in library_contract:
            errors.append(f"document tool contract is missing {tool}")
    for skill_name in sorted(OUTPUT_READER_SKILLS):
        skill_text = (root / "skills" / skill_name / "SKILL.md").read_text(encoding="utf-8")
        for reader in ("read_agent_task_output_content", "read_agent_task_output_base64"):
            if reader not in skill_text:
                errors.append(f"skills/{skill_name}/SKILL.md is missing output reader {reader}")
    for path in (root / "skills").rglob("*.md"):
        text = path.read_text(encoding="utf-8")
        for tool in sorted(STALE_TOOL_NAMES):
            if tool in text:
                errors.append(f"{path.relative_to(root)}: contains stale MCP tool {tool}")
    if (root / "scripts" / "mcp_http_bridge.py").exists():
        errors.append("obsolete MCP HTTP bridge remains")
    tabular_root = root / "skills" / "legal-tabular-research"
    if any((tabular_root / "scripts").glob("*.py")):
        errors.append("legal-tabular-research must not require Python at runtime")
    tabular_text = (tabular_root / "SKILL.md").read_text(encoding="utf-8")
    if "scripts/" in tabular_text or "python" in tabular_text.lower():
        errors.append("legal-tabular-research must use a skill-native runtime workflow")
    return sorted(set(errors))


def main() -> int:
    errors = validate_plugin()
    if errors:
        print("Plugin bundle validation failed:")
        for error in errors:
            print(f"- {error}")
        return 1
    print("Plugin bundle validation passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
