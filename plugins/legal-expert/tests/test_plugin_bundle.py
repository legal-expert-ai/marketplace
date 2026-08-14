from __future__ import annotations

import importlib.util
import json
import struct
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def load_module(path: Path, name: str):
    spec = importlib.util.spec_from_file_location(name, path)
    assert spec and spec.loader
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


class PluginBundleTest(unittest.TestCase):
    def test_repository_passes_portable_validation(self) -> None:
        validator = load_module(ROOT / "scripts" / "validate_plugin_bundle.py", "bundle_validator")
        self.assertEqual([], validator.validate_plugin(ROOT))

    def test_exact_skill_set_has_no_legacy_tabular_alias(self) -> None:
        skill_names = {path.name for path in (ROOT / "skills").iterdir() if (path / "SKILL.md").is_file()}
        self.assertIn("legal-tabular-research", skill_names)
        self.assertNotIn("build-legal-research-table", skill_names)

    def test_mcp_uses_native_oauth_http_and_fails_closed_without_production_url(self) -> None:
        payload = json.loads((ROOT / ".mcp.json").read_text(encoding="utf-8"))
        server = payload["mcpServers"]["legal-expert"]
        self.assertEqual({"type", "url"}, set(server))
        self.assertEqual("http", server["type"])
        self.assertEqual("https://legal-expert-backend-feat-public-mcp-agent-tasks.docker.d.com.ro/mcp", server["url"])
        self.assertFalse((ROOT / "scripts" / "mcp_http_bridge.py").exists())

    def test_manifest_uses_windows_oauth_release_semver(self) -> None:
        payload = json.loads((ROOT / ".codex-plugin" / "plugin.json").read_text(encoding="utf-8"))
        self.assertEqual("0.3.0-beta.2", payload["version"])

    def test_manifest_includes_a_valid_product_screenshot(self) -> None:
        payload = json.loads((ROOT / ".codex-plugin" / "plugin.json").read_text(encoding="utf-8"))
        screenshots = payload["interface"]["screenshots"]
        self.assertEqual(["./assets/product-overview.png"], screenshots)

        screenshot_path = ROOT / screenshots[0].removeprefix("./")
        with screenshot_path.open("rb") as screenshot:
            header = screenshot.read(24)
        self.assertEqual(b"\x89PNG\r\n\x1a\n", header[:8])
        width, height = struct.unpack(">II", header[16:24])
        self.assertGreaterEqual(width, 1200)
        self.assertGreaterEqual(height, 675)
        self.assertGreaterEqual(width / height, 1.7)
        self.assertLessEqual(width / height, 1.8)

    def test_all_skills_distinguish_connection_failures(self) -> None:
        validator = load_module(ROOT / "scripts" / "validate_plugin_bundle.py", "bundle_diagnostics_validator")
        for skill_dir in (ROOT / "skills").iterdir():
            skill_md = skill_dir / "SKILL.md"
            if not skill_md.is_file():
                continue
            text = skill_md.read_text(encoding="utf-8")
            for marker in validator.OAUTH_DIAGNOSTIC_MARKERS:
                self.assertIn(marker, text)

    def test_tabular_research_has_no_python_runtime_dependency(self) -> None:
        tabular_root = ROOT / "skills" / "legal-tabular-research"
        self.assertEqual([], list((tabular_root / "scripts").glob("*.py")))
        skill_text = (tabular_root / "SKILL.md").read_text(encoding="utf-8").lower()
        self.assertNotIn("scripts/", skill_text)
        self.assertNotIn("python", skill_text)

    def test_document_contract_uses_only_current_tool_names(self) -> None:
        validator = load_module(ROOT / "scripts" / "validate_plugin_bundle.py", "bundle_tool_validator")
        text = (ROOT / "skills" / "manage-legal-library" / "references" / "document-tool-contracts.md").read_text(encoding="utf-8")
        self.assertEqual(13, validator.EXPECTED_LIBRARY_TOOL_COUNT)
        self.assertEqual(validator.EXPECTED_LIBRARY_TOOL_COUNT, len(validator.REQUIRED_LIBRARY_TOOLS))
        for tool in validator.REQUIRED_LIBRARY_TOOLS:
            self.assertIn(tool, text)
        for tool in validator.STALE_TOOL_NAMES:
            self.assertNotIn(tool, text)

    def test_agent_output_skills_route_text_and_binary_content(self) -> None:
        validator = load_module(ROOT / "scripts" / "validate_plugin_bundle.py", "bundle_output_validator")
        for skill_name in validator.OUTPUT_READER_SKILLS:
            text = (ROOT / "skills" / skill_name / "SKILL.md").read_text(encoding="utf-8")
            self.assertIn("read_agent_task_output_content", text)
            self.assertIn("read_agent_task_output_base64", text)


if __name__ == "__main__":
    unittest.main()
