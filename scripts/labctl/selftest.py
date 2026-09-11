"""Deterministic tests for the Python controller.

These tests intentionally avoid installing software or starting VMs/containers.
They validate the controller's catalog and policy contracts and the dry-run
materialization path used by CI.
"""

from __future__ import annotations

import tempfile
from pathlib import Path

from labctl import experiments, infra, policy
from labctl.catalog import EXPERIMENTS, STAGES, experiment_by_id, stage_by_id


def run() -> int:
    failures: list[str] = []

    def check(name: str, condition: bool) -> None:
        print(f"{'PASS' if condition else 'FAIL'}  {name}")
        if not condition:
            failures.append(name)

    check("12 experiment specs", len(EXPERIMENTS) == 12)
    check("12 stages", len(STAGES) == 12)

    for spec in EXPERIMENTS:
        check(f"experiment resolves: {spec.id}", experiment_by_id(spec.id).id == spec.id)
    for stage in STAGES:
        check(f"stage resolves: {stage.id}", stage_by_id(stage.id).id == stage.id)

    check("credentials denied", policy.decide("credentials")["decision"] == "deny")
    check("host-root denied", policy.decide("host-root")["decision"] == "deny")
    check("read allowed", policy.decide("read")["decision"] == "allow")

    with tempfile.TemporaryDirectory(prefix="labctl-selftest-") as tmp:
        root = Path(tmp)
        infra_actions = infra.materialize(root, dry_run=True)
        experiment_actions = experiments.materialize_all(root, dry_run=True)
        check("infra dry-run has actions", bool(infra_actions))
        check("experiment dry-run has actions", bool(experiment_actions))
        check("dry-run writes no README", not (root / "README.md").exists())
        check("dry-run writes no experiment files", not (root / "experiments").exists())

    if failures:
        print(f"self-test: FAIL ({len(failures)} failure(s))")
        return 2
    print("self-test: PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(run())
