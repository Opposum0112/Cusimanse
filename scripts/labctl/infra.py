"""Materialize infrastructure files and optionally start localhost compose stacks."""

from __future__ import annotations

import shutil
import subprocess
from pathlib import Path
from typing import Any

from labctl.files import ensure_dir, write_text
from labctl.templates import INFRA_FILES, SHELL_COMMON, SHELL_EVIDENCE


LAYOUT_DIRS = (
    "infra/lima",
    "infra/gateway",
    "infra/observability",
    "infra/mcp",
    "infra/aegis",
    "infra/numbat",
    "infra/instrumentation",
    "policies",
    "blackboard",
    "agents",
    "skills",
    "gateways",
    "vm",
    "experiments",
    "evidence",
    "reports",
    "manifests",
    "events",
    "scripts/lib",
    "scripts/bin",
    "packages/labprobe",
    ".agents/agents",
    ".agents/skills",
)


def materialize(root: Path, *, dry_run: bool) -> list[dict[str, str]]:
    actions: list[dict[str, str]] = []
    for rel in LAYOUT_DIRS:
        path = root / rel
        actions.append({"path": rel + "/", "action": ensure_dir(path, dry_run=dry_run)})
        gitkeep = path / ".gitkeep"
        if rel.split("/")[0] in {"evidence", "events"}:
            # evidence/* is gitignored; keep a placeholder only at top-level evidence/
            if rel in {"evidence", "events"}:
                actions.append(
                    {"path": str(gitkeep.relative_to(root)), "action": write_text(gitkeep, "", dry_run=dry_run)}
                )
        elif not any(path.glob("*")) or True:
            if rel not in {"packages/labprobe", ".agents/agents", ".agents/skills"}:
                pass

    for rel, content in INFRA_FILES.items():
        path = root / rel
        executable = rel.endswith(".sh")
        actions.append(
            {
                "path": rel,
                "action": write_text(path, content, dry_run=dry_run, executable=executable),
            }
        )

    actions.append(
        {
            "path": "scripts/lib/common.sh",
            "action": write_text(root / "scripts/lib/common.sh", SHELL_COMMON, dry_run=dry_run),
        }
    )
    actions.append(
        {
            "path": "scripts/lib/evidence.sh",
            "action": write_text(root / "scripts/lib/evidence.sh", SHELL_EVIDENCE, dry_run=dry_run),
        }
    )

    _sync_agents(root, actions, dry_run=dry_run)
    return actions


def _sync_agents(root: Path, actions: list[dict[str, str]], *, dry_run: bool) -> None:
    src_agents = root / "antigravity" / "agents"
    src_skills = root / "antigravity" / "skills"
    dst_agents = root / ".agents" / "agents"
    dst_skills = root / ".agents" / "skills"
    dst_agents.mkdir(parents=True, exist_ok=True) if not dry_run else None
    dst_skills.mkdir(parents=True, exist_ok=True) if not dry_run else None
    mapping = []
    if src_agents.is_dir():
        for path in src_agents.glob("*.md"):
            mapping.append((path, dst_agents / path.name))
    if src_skills.is_dir():
        for path in src_skills.glob("*.md"):
            mapping.append((path, dst_skills / path.name))
    mcp_src = root / "antigravity" / "mcp_config.example.json"
    if mcp_src.exists():
        mapping.append((mcp_src, root / ".agents" / "mcp_config.json"))
    for src, dst in mapping:
        rel = str(dst.relative_to(root))
        actions.append(
            {
                "path": rel,
                "action": write_text(dst, src.read_text(encoding="utf-8"), dry_run=dry_run),
            }
        )


COMPOSE_STACKS = {
    "gateway": Path("infra/gateway"),
    "observability": Path("infra/observability"),
}


def compose(root: Path, stack: str, action: str, *, apply: bool) -> dict[str, Any]:
    if stack not in COMPOSE_STACKS:
        raise KeyError(f"Unknown stack {stack!r}. Known: {', '.join(COMPOSE_STACKS)}")
    directory = root / COMPOSE_STACKS[stack]
    compose_file = directory / "docker-compose.yml"
    if not compose_file.exists():
        return {"stack": stack, "status": "NOT_DEPLOYED", "detail": "compose file missing; run labctl init"}
    runtime = shutil.which("docker") or shutil.which("podman")
    if not runtime:
        return {
            "stack": stack,
            "status": "NOT_DEPLOYED",
            "detail": "neither docker nor podman is on PATH",
        }
    cmd = [runtime, "compose", "-f", str(compose_file), action]
    if runtime.endswith("podman"):
        cmd = [runtime, "compose", "-f", str(compose_file), action]
    if not apply:
        return {"stack": stack, "status": "dry-run", "command": cmd, "bind": "127.0.0.1"}
    proc = subprocess.run(cmd, cwd=directory, capture_output=True, text=True, check=False)
    return {
        "stack": stack,
        "status": "PASS" if proc.returncode == 0 else "FAIL",
        "command": cmd,
        "returncode": proc.returncode,
        "stdout": (proc.stdout or "")[-2000:],
        "stderr": (proc.stderr or "")[-2000:],
    }
