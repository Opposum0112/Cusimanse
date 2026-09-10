"""Repository layout helpers."""

from __future__ import annotations

from pathlib import Path


def repo_root(start: Path | None = None) -> Path:
    """Walk parents until LICENSE + AGENTS.md + 01-deployment-architecture.md exist."""
    cur = (start or Path.cwd()).resolve()
    for candidate in [cur, *cur.parents]:
        if (
            (candidate / "LICENSE").is_file()
            and (candidate / "AGENTS.md").is_file()
            and (candidate / "01-deployment-architecture.md").is_file()
        ):
            return candidate
    raise FileNotFoundError(
        "Cannot locate the ai-security-lab repository root. "
        "Run labctl from the repo, or pass --root."
    )


def scripts_dir(root: Path) -> Path:
    return root / "scripts"


def infra_dir(root: Path) -> Path:
    return root / "infra"


def experiments_dir(root: Path) -> Path:
    return root / "experiments"
