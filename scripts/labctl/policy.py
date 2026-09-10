"""Local policy gate (Aegis stand-in) and event log (Numbat stand-in)."""

from __future__ import annotations

import json
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


DENY_ACTIONS = {
    "host-root": "Privileged host operations require explicit approval.",
    "sudo": "sudo is deny/approval-gated.",
    "credentials": "Host and cloud credentials must not enter experiment VMs.",
    "network-reconfiguration": "Host network changes are deny/approval-gated.",
    "unrestricted-mount": "Lima mounts must stay empty.",
}

ALLOW_ACTIONS = {
    "read": "Read-tier commands are allowed.",
    "project-write": "Workspace-bounded writes are allowed.",
}


def decide(action: str) -> dict[str, Any]:
    key = action.strip().lower()
    if key in DENY_ACTIONS:
        return {
            "action": key,
            "decision": "deny",
            "tier": "privileged",
            "reason": DENY_ACTIONS[key],
        }
    if key in ALLOW_ACTIONS:
        return {
            "action": key,
            "decision": "allow",
            "tier": key,
            "reason": ALLOW_ACTIONS[key],
        }
    if key in {"git", "vm"}:
        return {
            "action": key,
            "decision": "approval",
            "tier": key,
            "reason": f"{key} requires a checkpoint/approval.",
        }
    return {
        "action": key,
        "decision": "deny",
        "tier": "unknown",
        "reason": "Default deny for unknown actions.",
    }


def record(root: Path, event: dict[str, Any], *, dry_run: bool) -> Path:
    log_path = root / "events" / "numbat.jsonl"
    payload = {
        "timestamp": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        **event,
    }
    line = json.dumps(payload, sort_keys=True)
    if not dry_run:
        log_path.parent.mkdir(parents=True, exist_ok=True)
        with log_path.open("a", encoding="utf-8") as handle:
            handle.write(line + "\n")
    return log_path
