"""Generate per-stage experiment directories from catalog specs."""

from __future__ import annotations

from pathlib import Path

from labctl.catalog import EXPERIMENTS, ExperimentSpec
from labctl.files import ensure_dir, write_text
from labctl import yamlio


def _readme(spec: ExperimentSpec) -> str:
    vm = spec.vm_profile or "none (host-side)"
    success = "\n".join(f"- {item}" for item in spec.success)
    instruments = ", ".join(spec.instrumentation)
    notes = f"\n\n{spec.notes}\n" if spec.notes else "\n"
    return f"""# {spec.id}

{spec.name}

- **Stage:** `{spec.stage}`
- **Document:** `{spec.document}`
- **VM profile:** {vm}
- **Network policy:** `{spec.network_policy}`
- **Instrumentation:** {instruments}

## Objective

{spec.objective}

## Hypothesis

{spec.hypothesis}

## Target

```bash
{spec.target}
```
{notes}
## Success criteria

{success}

## Procedure

1. `./scripts/bin/labctl stage run {spec.stage}`
2. Review `experiment.yaml` before any `--apply`.
3. Start capture **before** the target command.
4. Preserve and hash evidence before deleting a VM.
5. Do not mount host credentials.

See `{spec.document}` for the authoritative procedure.
"""


def _hypothesis(spec: ExperimentSpec) -> str:
    return f"""# Hypothesis

{spec.hypothesis}

## Falsify if

- The target runs on the host instead of the documented execution plane.
- Evidence is missing, unhashed, or overwritten.
- A component is reported PASS when it was NOT_DEPLOYED.
"""


def _manifest(spec: ExperimentSpec) -> dict:
    return {
        "id": spec.id,
        "name": spec.name,
        "objective": spec.objective,
        "hypothesis": spec.hypothesis,
        "document": spec.document,
        "stage": spec.stage,
        "target": {"command": spec.target},
        "vm_profile": spec.vm_profile,
        "network_policy": spec.network_policy,
        "instrumentation": list(spec.instrumentation),
        "evidence": {"raw": True, "reduced": True, "hashes": True},
        "verification": {"independent_agent": True},
        "cleanup": {"delete_vm_after_evidence_preservation": bool(spec.vm_profile)},
        "success_criteria": list(spec.success),
    }


def _lima(spec: ExperimentSpec) -> str:
    profile = spec.vm_profile or "minimal"
    memory = "2GiB"
    disk = "20GiB" if profile != "minimal" else "12GiB"
    return f"""# Generated Lima template for {spec.id}
# Profile: {profile}. mounts MUST stay empty.
vmType: qemu
cpus: 2
memory: "{memory}"
disk: "{disk}"
mounts: []
containerd:
  system: false
  user: false
images:
  - location: "https://cloud-images.ubuntu.com/releases/24.04/release/ubuntu-24.04-server-cloudimg-amd64.img"
    arch: "x86_64"
networks:
  - lima: user-v2
ssh:
  localPort: 0
  loadDotSSHPubKeys: false
"""


def _setup(spec: ExperimentSpec) -> str:
    return f"""#!/usr/bin/env bash
set -euo pipefail
echo "setup {spec.id}"
echo "Host-side setup only. Untrusted work belongs in a disposable VM."
"""


def _baseline(spec: ExperimentSpec) -> str:
    return f"""#!/usr/bin/env bash
set -euo pipefail
echo "baseline {spec.id} $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "Collect process, network and filesystem baselines before the target command."
"""


def _capture(spec: ExperimentSpec) -> str:
    tools = " ".join(spec.instrumentation)
    return f"""#!/usr/bin/env bash
set -euo pipefail
echo "capture {spec.id}"
echo "Instrumentation: {tools}"
echo "Start collectors BEFORE the target. Prefer VM-side strace/tcpdump."
echo "Do not capture host credential files."
"""


def _run(spec: ExperimentSpec) -> str:
    if spec.id == "go-install-001":
        return """#!/usr/bin/env bash
set -euo pipefail
# Runs INSIDE the disposable VM (or prints the plan on the host).
ROOT="${LAB_ROOT:-/lab}"
PROBE="${ROOT}/packages/labprobe"
echo "go-install-001 target: in-repo packages/labprobe"
if [[ ! -d "${PROBE}" ]]; then
  echo "labprobe sources not found at ${PROBE}"
  echo "Copy packages/labprobe into the VM before running. Example:"
  echo "  limactl start --name go-install-001 experiments/go-install-001/lima.yaml"
  echo "  limactl copy packages/labprobe go-install-001:/tmp/labprobe"
  echo "  limactl shell go-install-001 -- bash -lc 'cd /tmp/labprobe && go install .'"
  exit 1
fi
cd "${PROBE}"
go version
go env GOPROXY GOSUMDB GOMODCACHE
# Local module: observes compiler/install without requiring a public GitHub repo.
GOPROXY=off go install .
command -v labprobe >/dev/null && labprobe || "$(go env GOPATH)/bin/labprobe"
"""
    return f"""#!/usr/bin/env bash
set -euo pipefail
echo "run {spec.id}"
echo "Approved target:"
echo "  {spec.target}"
echo "Refusing to execute unreviewed commands. Pass --apply via labctl after review."
"""


def _cleanup(spec: ExperimentSpec) -> str:
    return f"""#!/usr/bin/env bash
set -euo pipefail
echo "cleanup {spec.id}"
echo "1. Preserve and hash evidence"
echo "2. Stop captures"
echo "3. Stop and delete the disposable Lima VM if one was used"
echo "4. Confirm no secrets leaked into Git"
"""


def materialize_one(root: Path, spec: ExperimentSpec, *, dry_run: bool) -> list[dict[str, str]]:
    base = root / "experiments" / spec.id
    actions = [{"path": str(base.relative_to(root)) + "/", "action": ensure_dir(base, dry_run=dry_run)}]
    for sub in ("analysis", "reports", "manifests"):
        actions.append(
            {
                "path": str((base / sub).relative_to(root)) + "/",
                "action": ensure_dir(base / sub, dry_run=dry_run),
            }
        )
        actions.append(
            {
                "path": str((base / sub / ".gitkeep").relative_to(root)),
                "action": write_text(base / sub / ".gitkeep", "", dry_run=dry_run),
            }
        )

    files = {
        "README.md": _readme(spec),
        "hypothesis.md": _hypothesis(spec),
        "experiment.yaml": yamlio.dump(_manifest(spec)),
        "setup.sh": _setup(spec),
        "baseline.sh": _baseline(spec),
        "capture.sh": _capture(spec),
        "run.sh": _run(spec),
        "cleanup.sh": _cleanup(spec),
    }
    if spec.vm_profile:
        files["lima.yaml"] = _lima(spec)
    files.update(spec.extra_files)
    for name, content in files.items():
        path = base / name
        actions.append(
            {
                "path": str(path.relative_to(root)),
                "action": write_text(
                    path, content, dry_run=dry_run, executable=name.endswith(".sh")
                ),
            }
        )
    return actions


def materialize_all(root: Path, *, dry_run: bool) -> list[dict[str, str]]:
    actions: list[dict[str, str]] = []
    for spec in EXPERIMENTS:
        actions.extend(materialize_one(root, spec, dry_run=dry_run))
    return actions
