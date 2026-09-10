"""Tests for labctl — run with PYTHONPATH=scripts."""

from __future__ import annotations

import json
import shutil
import tempfile
import unittest
from pathlib import Path

from labctl import catalog, experiments, hashing, host, infra, policy, yamlio
from labctl.cli import main


def _fake_repo() -> Path:
    root = Path(tempfile.mkdtemp(prefix="labctl-"))
    (root / "LICENSE").write_text("MIT\n", encoding="utf-8")
    (root / "AGENTS.md").write_text("# agents\n", encoding="utf-8")
    (root / "01-deployment-architecture.md").write_text("# arch\n", encoding="utf-8")
    (root / "state.yaml").write_text("schema_version: \"1.0\"\n", encoding="utf-8")
    (root / "antigravity" / "agents").mkdir(parents=True)
    (root / "antigravity" / "agents" / "planner.md").write_text("# planner\n", encoding="utf-8")
    return root


class YamlTests(unittest.TestCase):
    def test_roundtrip(self) -> None:
        data = {"a": 1, "b": {"c": True, "d": None}, "e": ["x", "y"]}
        loaded = yamlio.load(yamlio.dump(data))
        self.assertEqual(loaded["a"], 1)
        self.assertEqual(loaded["b"]["c"], True)
        self.assertEqual(loaded["e"], ["x", "y"])


class CatalogTests(unittest.TestCase):
    def test_twelve_stages_and_experiments(self) -> None:
        self.assertEqual(len(catalog.STAGES), 12)
        self.assertEqual(len(catalog.EXPERIMENTS), 12)
        self.assertEqual(catalog.stage_by_id("08").experiment_id, "go-install-001")
        self.assertEqual(catalog.experiment_by_id("go-install-001").vm_profile, "security-research")


class PolicyTests(unittest.TestCase):
    def test_default_deny_host_root(self) -> None:
        self.assertEqual(policy.decide("host-root")["decision"], "deny")
        self.assertEqual(policy.decide("read")["decision"], "allow")
        self.assertEqual(policy.decide("git")["decision"], "approval")


class InitTests(unittest.TestCase):
    def tearDown(self) -> None:
        if hasattr(self, "root"):
            shutil.rmtree(self.root, ignore_errors=True)

    def test_init_writes_stack_and_experiments(self) -> None:
        self.root = _fake_repo()
        rc = main(["--root", str(self.root), "init"])
        self.assertEqual(rc, 0)
        self.assertTrue((self.root / "infra" / "lima" / "security-research.yaml").is_file())
        lima = (self.root / "infra" / "lima" / "security-research.yaml").read_text(encoding="utf-8")
        self.assertIn("mounts: []", lima)
        gateway = (self.root / "infra" / "gateway" / "docker-compose.yml").read_text(encoding="utf-8")
        self.assertIn("127.0.0.1:4000", gateway)
        obs = (self.root / "infra" / "observability" / "docker-compose.yml").read_text(encoding="utf-8")
        self.assertIn("127.0.0.1:6006", obs)
        self.assertTrue((self.root / "experiments" / "go-install-001" / "run.sh").is_file())
        self.assertTrue((self.root / "experiments" / "stage-04-security-model" / "experiment.yaml").is_file())
        for spec in catalog.EXPERIMENTS:
            self.assertTrue((self.root / "experiments" / spec.id / "experiment.yaml").is_file(), spec.id)
        manifest = json.loads((self.root / "PACKAGE-MANIFEST.json").read_text(encoding="utf-8"))
        self.assertGreater(len(manifest["files"]), 20)

    def test_dry_run_writes_nothing(self) -> None:
        self.root = _fake_repo()
        rc = main(["--root", str(self.root), "--dry-run", "init"])
        self.assertEqual(rc, 0)
        self.assertFalse((self.root / "infra" / "lima").exists())


class HostTests(unittest.TestCase):
    def test_preflight_has_summary(self) -> None:
        root = Path(__file__).resolve().parents[2]
        # This file lives in scripts/tests — parents[2] is repo if present.
        if not (root / "LICENSE").is_file():
            self.skipTest("not running inside the lab repo")
        result = host.preflight(root)
        self.assertIn(result["summary"], {"PASS", "PARTIAL", "FAIL"})
        names = {c["name"] for c in result["checks"]}
        self.assertIn("architecture-x86_64", names)


class HashingTests(unittest.TestCase):
    def test_inventory_skips_git(self) -> None:
        self.root = _fake_repo()
        try:
            infra.materialize(self.root, dry_run=False)
            inv = hashing.inventory(self.root)
            paths = [f["path"] for f in inv["files"]]
            self.assertTrue(any(p.startswith("infra/") for p in paths))
            self.assertFalse(any(p.startswith(".git/") for p in paths))
        finally:
            shutil.rmtree(self.root, ignore_errors=True)


if __name__ == "__main__":
    unittest.main()
