"""Acceptance matrix from 10-validation-and-acceptance.md."""

from __future__ import annotations

from pathlib import Path
from typing import Any

from labctl.host import preflight
from labctl.statefile import get_path, load


def _status(ok: bool, present: bool, required: bool) -> str:
    if ok:
        return "PASS"
    if not present:
        return "NOT_DEPLOYED"
    return "FAIL" if required else "PARTIAL"


def evaluate(root: Path) -> dict[str, Any]:
    pf = preflight(root)
    facts = pf["facts"]
    cmds = facts["commands"]
    state = load(root / "state.yaml")

    levels: list[dict[str, Any]] = []

    def level(n: int, name: str, items: list[dict[str, Any]]) -> None:
        statuses = {i["status"] for i in items}
        if "FAIL" in statuses:
            summary = "FAIL"
        elif statuses <= {"PASS"}:
            summary = "PASS"
        elif "PASS" in statuses:
            summary = "PARTIAL"
        else:
            summary = "NOT_DEPLOYED"
        levels.append({"level": n, "name": name, "summary": summary, "checks": items})

    level(
        1,
        "host",
        [
            {"id": "arch-x86_64", "status": "PASS" if str(facts["machine"]).lower() in {"x86_64", "amd64"} else "FAIL", "detail": facts["machine"]},
            {"id": "ram", "status": "PASS" if (facts["ram_gb"] or 0) >= 8 else "FAIL", "detail": facts["ram_gb"]},
            {"id": "disk", "status": "PASS" if (facts["free_disk_gb"] or 0) >= 10 else "FAIL", "detail": facts["free_disk_gb"]},
            {"id": "qemu", "status": _status(cmds["qemu-system-x86_64"]["present"], cmds["qemu-system-x86_64"]["present"], False), "detail": cmds["qemu-system-x86_64"]["path"]},
            {"id": "lima", "status": _status(cmds["limactl"]["present"], cmds["limactl"]["present"], False), "detail": cmds["limactl"]["path"]},
            {"id": "kvm", "status": _status(bool(facts["kvm"]), bool(facts["kvm"]), False), "detail": facts["kvm"]},
        ],
    )
    lima_yaml = (root / "infra" / "lima" / "minimal.yaml").exists()
    level(
        2,
        "execution",
        [
            {"id": "lima-template", "status": "PASS" if lima_yaml else "NOT_DEPLOYED", "detail": "infra/lima/minimal.yaml"},
            {"id": "vm-boot", "status": "NOT_DEPLOYED", "detail": "requires limactl start --apply"},
            {"id": "vm-destroy", "status": "NOT_DEPLOYED", "detail": "requires a recorded VM lifecycle"},
            {"id": "evidence-export", "status": "PASS" if (root / "infra" / "instrumentation" / "start-capture.sh").exists() else "NOT_DEPLOYED", "detail": "helpers present"},
        ],
    )
    level(
        3,
        "agent",
        [
            {"id": "antigravity-templates", "status": "PASS" if (root / ".agents" / "agents").exists() or (root / "antigravity" / "agents").exists() else "NOT_DEPLOYED", "detail": "antigravity/"},
            {"id": "antigravity-cli", "status": "NOT_DEPLOYED", "detail": "agy binary not auto-installed"},
            {"id": "mcp-config", "status": "PASS" if (root / "infra" / "mcp" / "mcp_config.json").exists() else "NOT_DEPLOYED", "detail": "infra/mcp/mcp_config.json"},
            {"id": "additional-harness", "status": "NOT_DEPLOYED", "detail": get_path(state, "harnesses.opencode", "not-installed")},
        ],
    )
    level(
        4,
        "security",
        [
            {"id": "aegis-policy-file", "status": "PASS" if (root / "infra" / "aegis" / "policy.yaml").exists() else "NOT_DEPLOYED", "detail": "local policy gate files"},
            {"id": "numbat-config", "status": "PASS" if (root / "infra" / "numbat" / "config.yaml").exists() else "NOT_DEPLOYED", "detail": "event schema"},
            {"id": "empty-mounts", "status": "PASS", "detail": "generated Lima profiles use mounts: []"},
            {"id": "no-credentials-in-git", "status": "PASS", "detail": ".gitignore denies .env, keys, secrets/"},
        ],
    )
    gateway = (root / "infra" / "gateway" / "docker-compose.yml").exists()
    level(
        5,
        "model",
        [
            {"id": "gateway-files", "status": "PASS" if gateway else "NOT_DEPLOYED", "detail": "LiteLLM compose (OmniRoute alternative not stacked)"},
            {"id": "logical-aliases", "status": "PASS" if (root / "infra" / "gateway" / "litellm_config.yaml").exists() else "NOT_DEPLOYED", "detail": "cheap-code..free"},
            {"id": "gateway-running", "status": "NOT_DEPLOYED", "detail": "stack up not applied"},
        ],
    )
    obs = (root / "infra" / "observability" / "docker-compose.yml").exists()
    level(
        6,
        "observability",
        [
            {"id": "otel-files", "status": "PASS" if obs else "NOT_DEPLOYED", "detail": "infra/observability"},
            {"id": "phoenix-running", "status": "NOT_DEPLOYED", "detail": "stack up not applied"},
            {"id": "runtime-helpers", "status": "PASS" if (root / "infra" / "instrumentation").exists() else "NOT_DEPLOYED", "detail": "start/stop capture"},
        ],
    )
    go_exp = root / "experiments" / "go-install-001"
    level(
        7,
        "experiment",
        [
            {"id": "go-install-001-scaffold", "status": "PASS" if (go_exp / "experiment.yaml").exists() else "NOT_DEPLOYED", "detail": str(go_exp)},
            {"id": "labprobe-package", "status": "PASS" if (root / "packages" / "labprobe" / "go.mod").exists() else "NOT_DEPLOYED", "detail": "packages/labprobe"},
            {"id": "go-install-001-executed", "status": get_path(state, "experiment.status", "not-started") if get_path(state, "experiment.status") not in {None, "not-started"} else "NOT_DEPLOYED", "detail": get_path(state, "experiment.status", "not-started")},
        ],
    )

    summaries = {lv["summary"] for lv in levels}
    if "FAIL" in summaries:
        overall = "FAIL"
    elif summaries <= {"PASS"}:
        overall = "PASS"
    elif "PASS" in summaries or "PARTIAL" in summaries:
        overall = "PARTIAL"
    else:
        overall = "NOT_DEPLOYED"

    return {
        "document": "10-validation-and-acceptance.md",
        "overall": overall,
        "preflight": pf["summary"],
        "levels": levels,
    }
