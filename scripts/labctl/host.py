"""Host preflight probes from 02-system-requirements.md and 10-validation."""

from __future__ import annotations

import os
import platform
import shutil
import subprocess
from pathlib import Path
from typing import Any


COMMANDS = [
    "git",
    "python3",
    "go",
    "jq",
    "yq",
    "rg",
    "qemu-system-x86_64",
    "limactl",
    "docker",
    "podman",
    "curl",
    "sha256sum",
    "strace",
    "lsof",
    "tcpdump",
    "tshark",
    "bpftrace",
    "mitmproxy",
]


def _run(cmd: list[str]) -> tuple[int, str]:
    try:
        proc = subprocess.run(cmd, capture_output=True, text=True, check=False, timeout=8)
    except (FileNotFoundError, subprocess.TimeoutExpired) as exc:
        return 127, str(exc)
    out = (proc.stdout or proc.stderr or "").strip()
    return proc.returncode, out


def mem_gb() -> float | None:
    info = Path("/proc/meminfo")
    if not info.exists():
        return None
    for line in info.read_text(encoding="utf-8").splitlines():
        if line.startswith("MemTotal:"):
            kb = int(line.split()[1])
            return round(kb / 1024 / 1024, 2)
    return None


def disk_gb(path: Path) -> float | None:
    try:
        usage = shutil.disk_usage(path)
    except OSError:
        return None
    return round(usage.free / 1024 / 1024 / 1024, 2)


def kvm_available() -> bool:
    return Path("/dev/kvm").exists() and os.access("/dev/kvm", os.R_OK | os.W_OK)


def which(name: str) -> str | None:
    return shutil.which(name)


def command_report() -> dict[str, dict[str, Any]]:
    report: dict[str, dict[str, Any]] = {}
    for name in COMMANDS:
        path = which(name)
        version = None
        if path:
            code, out = _run([name, "--version"])
            if code != 0:
                code, out = _run([name, "-version"])
            version = (out.splitlines() or [""])[0][:200] if out else None
        report[name] = {"present": bool(path), "path": path, "version": version}
    return report


def facts(root: Path) -> dict[str, Any]:
    uname = platform.uname()
    cmds = command_report()
    container = "docker" if cmds["docker"]["present"] else (
        "podman" if cmds["podman"]["present"] else None
    )
    return {
        "system": uname.system,
        "release": uname.release,
        "machine": uname.machine,
        "processor": uname.processor,
        "python": platform.python_version(),
        "hostname": platform.node(),
        "cpu_count": os.cpu_count(),
        "ram_gb": mem_gb(),
        "free_disk_gb": disk_gb(root),
        "kvm": kvm_available(),
        "container_runtime": container,
        "commands": cmds,
    }


def preflight(root: Path) -> dict[str, Any]:
    info = facts(root)
    checks = []

    def add(name: str, ok: bool, detail: str, required: bool = True) -> None:
        checks.append(
            {
                "name": name,
                "ok": ok,
                "required": required,
                "detail": detail,
                "status": "PASS" if ok else ("FAIL" if required else "NOT_DEPLOYED"),
            }
        )

    machine = str(info["machine"]).lower()
    add("architecture-x86_64", machine in {"x86_64", "amd64"}, f"machine={info['machine']}")
    ram = info["ram_gb"]
    add("ram-16gb-class", ram is not None and ram >= 8, f"ram_gb={ram}")
    if ram is not None and ram < 14:
        checks[-1]["detail"] += " (16 GB host recommended; continuing with reduced budget)"
    disk = info["free_disk_gb"]
    add("disk-50gb", disk is not None and disk >= 20, f"free_disk_gb={disk}")
    add("kvm", bool(info["kvm"]), " /dev/kvm accessible" if info["kvm"] else "/dev/kvm missing")
    add("git", info["commands"]["git"]["present"], str(info["commands"]["git"]["path"]))
    add("python3", info["commands"]["python3"]["present"], str(info["commands"]["python3"]["version"]))
    add(
        "qemu",
        info["commands"]["qemu-system-x86_64"]["present"],
        str(info["commands"]["qemu-system-x86_64"]["version"]),
        required=False,
    )
    add(
        "lima",
        info["commands"]["limactl"]["present"],
        str(info["commands"]["limactl"]["version"]),
        required=False,
    )
    add(
        "container-runtime",
        info["container_runtime"] is not None,
        str(info["container_runtime"]),
        required=False,
    )
    add("go", info["commands"]["go"]["present"], str(info["commands"]["go"]["version"]), required=False)

    required_failed = [c for c in checks if c["required"] and not c["ok"]]
    optional_missing = [c for c in checks if (not c["required"]) and not c["ok"]]
    if required_failed:
        summary = "FAIL"
    elif optional_missing:
        summary = "PARTIAL"
    else:
        summary = "PASS"

    return {"summary": summary, "facts": info, "checks": checks}
