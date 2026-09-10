"""Read and update state.yaml without requiring PyYAML."""

from __future__ import annotations

from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from labctl import yamlio


HEADER = "# Deployment state — updated by labctl. Do not store secrets here.\n"


def load(path: Path) -> dict[str, Any]:
    if not path.exists():
        return {}
    data = yamlio.load(path.read_text(encoding="utf-8"))
    if not isinstance(data, dict):
        raise ValueError(f"{path} is not a mapping")
    return data


def save(path: Path, data: dict[str, Any], *, dry_run: bool) -> None:
    data = dict(data)
    data["updated_at"] = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    text = HEADER + yamlio.dump(data)
    if dry_run:
        return
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8")


def set_path(data: dict[str, Any], dotted: str, value: Any) -> None:
    parts = dotted.split(".")
    cur: Any = data
    for part in parts[:-1]:
        nxt = cur.get(part)
        if not isinstance(nxt, dict):
            nxt = {}
            cur[part] = nxt
        cur = nxt
    cur[parts[-1]] = value


def get_path(data: dict[str, Any], dotted: str, default: Any = None) -> Any:
    cur: Any = data
    for part in dotted.split("."):
        if not isinstance(cur, dict) or part not in cur:
            return default
        cur = cur[part]
    return cur
