"""Idempotent file writes with SHA-256."""

from __future__ import annotations

import hashlib
import os
from pathlib import Path


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def sha256_file(path: Path) -> str:
    return sha256_bytes(path.read_bytes())


def write_text(path: Path, content: str, *, dry_run: bool, executable: bool = False) -> str:
    """Write content if changed. Returns created|updated|unchanged|dry-run."""
    data = content.encode("utf-8")
    if not content.endswith("\n"):
        data = content.encode("utf-8") + b"\n"
        content = content if content.endswith("\n") else content + "\n"
        data = content.encode("utf-8")
    action = "created"
    if path.exists():
        if path.read_bytes() == data:
            return "unchanged"
        action = "updated"
    if dry_run:
        return f"dry-run:{action}"
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(data)
    if executable:
        mode = path.stat().st_mode
        path.chmod(mode | 0o111)
    return action


def ensure_dir(path: Path, *, dry_run: bool) -> str:
    if path.is_dir():
        return "unchanged"
    if dry_run:
        return "dry-run:created"
    path.mkdir(parents=True, exist_ok=True)
    return "created"


def make_executable(path: Path, *, dry_run: bool) -> None:
    if dry_run or not path.exists():
        return
    mode = path.stat().st_mode
    os.chmod(path, mode | 0o111)
