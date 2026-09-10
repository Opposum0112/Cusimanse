"""SHA-256 inventory helper."""

from __future__ import annotations

import json
from pathlib import Path

from labctl.files import sha256_file

SKIP_DIRS = {".git", "__pycache__", ".venv", "node_modules", ".lima"}


def inventory(root: Path) -> dict:
    files = []
    for path in sorted(root.rglob("*")):
        if not path.is_file():
            continue
        if any(part in SKIP_DIRS for part in path.parts):
            continue
        rel = path.relative_to(root).as_posix()
        if rel == "PACKAGE-MANIFEST.json":
            continue
        files.append({"path": rel, "sha256": sha256_file(path), "bytes": path.stat().st_size})
    return {
        "package": "ai-security-lab",
        "license": "MIT",
        "spdx": "MIT",
        "files": files,
    }


def write_manifest(root: Path, *, dry_run: bool) -> Path:
    data = inventory(root)
    path = root / "PACKAGE-MANIFEST.json"
    text = json.dumps(data, indent=2) + "\n"
    if not dry_run:
        path.write_text(text, encoding="utf-8")
    return path
