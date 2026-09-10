"""Command-line interface for labctl."""

from __future__ import annotations

import argparse
import json
import shutil
import sys
from pathlib import Path
from typing import Any

from labctl import __version__, accept, experiments, hashing, host, infra, policy, statefile, yamlio
from labctl.catalog import EXPERIMENTS, STAGES, experiment_by_id, stage_by_id
from labctl.paths import repo_root


def _json(data: Any) -> None:
    json.dump(data, sys.stdout, indent=2, default=str)
    sys.stdout.write("\n")


def _print_actions(actions: list[dict[str, str]]) -> None:
    counts: dict[str, int] = {}
    for item in actions:
        counts[item["action"]] = counts.get(item["action"], 0) + 1
        print(f"  {item['action']:18} {item['path']}")
    print("summary:", ", ".join(f"{k}={v}" for k, v in sorted(counts.items())))


def _root(args: argparse.Namespace) -> Path:
    if getattr(args, "root", None):
        return Path(args.root).resolve()
    return repo_root()


def cmd_status(args: argparse.Namespace) -> int:
    root = _root(args)
    state = statefile.load(root / "state.yaml")
    facts = host.facts(root)
    payload = {
        "labctl": __version__,
        "root": str(root),
        "state": state,
        "host": {
            "system": facts["system"],
            "machine": facts["machine"],
            "ram_gb": facts["ram_gb"],
            "free_disk_gb": facts["free_disk_gb"],
            "kvm": facts["kvm"],
            "container_runtime": facts["container_runtime"],
        },
    }
    if args.json:
        _json(payload)
    else:
        print(f"labctl {__version__}")
        print(f"root: {root}")
        print(f"host: {facts['system']} {facts['machine']} ram={facts['ram_gb']}G disk={facts['free_disk_gb']}G kvm={facts['kvm']}")
        print(f"experiment: {state.get('experiment', {})}")
        print(f"execution: {state.get('execution', {})}")
    return 0


def cmd_stages(_args: argparse.Namespace) -> int:
    print(f"{'ID':<4} {'NAME':<22} {'DOC':<34} EXPERIMENT")
    for stage in STAGES:
        print(f"{stage.id:<4} {stage.name:<22} {stage.document:<34} {stage.experiment_id}")
    return 0


def cmd_init(args: argparse.Namespace) -> int:
    root = _root(args)
    dry = bool(args.dry_run)
    print(f"materializing stack under {root} (dry_run={dry})")
    actions = infra.materialize(root, dry_run=dry)
    actions.extend(experiments.materialize_all(root, dry_run=dry))
    _print_actions(actions)
    if not dry:
        hashing.write_manifest(root, dry_run=False)
        state = statefile.load(root / "state.yaml")
        statefile.set_path(state, "git.dirty", True)
        statefile.save(root / "state.yaml", state, dry_run=False)
    else:
        print("dry-run: no files written")
    return 0


def cmd_preflight(args: argparse.Namespace) -> int:
    root = _root(args)
    result = host.preflight(root)
    if args.json:
        _json(result)
    else:
        print(f"preflight: {result['summary']}")
        for check in result["checks"]:
            flag = "ok " if check["ok"] else "NO "
            req = "required" if check["required"] else "optional"
            print(f"  [{flag}] {check['name']:<22} {req:<8} {check['detail']}")
        if not args.apply:
            print("state.yaml not updated (pass --apply to record facts)")
    if args.apply:
        state = statefile.load(root / "state.yaml")
        facts = result["facts"]
        statefile.set_path(state, "host.architecture", facts["machine"])
        statefile.set_path(state, "host.ram_gb", facts["ram_gb"])
        statefile.set_path(state, "host.free_disk_gb", facts["free_disk_gb"])
        statefile.set_path(state, "host.virtualization", "kvm" if facts["kvm"] else "unknown")
        statefile.set_path(
            state,
            "execution.qemu",
            "installed" if facts["commands"]["qemu-system-x86_64"]["present"] else "not-installed",
        )
        statefile.set_path(
            state,
            "execution.lima",
            "installed" if facts["commands"]["limactl"]["present"] else "not-installed",
        )
        if facts["container_runtime"]:
            statefile.set_path(state, "execution.container_runtime", facts["container_runtime"])
        statefile.save(root / "state.yaml", state, dry_run=False)
        print("recorded host facts in state.yaml")
    return 0 if result["summary"] != "FAIL" else 2


def cmd_stage(args: argparse.Namespace) -> int:
    root = _root(args)
    tokens = args.id if isinstance(args.id, list) else [args.id]
    if tokens and tokens[0] in {"run", "show"}:
        tokens = tokens[1:]
    if not tokens:
        print("labctl stage: missing stage id", file=sys.stderr)
        return 2
    stage = stage_by_id(tokens[0])
    dry = bool(args.dry_run)
    print(f"stage {stage.id} {stage.name}")
    print(f"  document: {stage.document}")
    print(f"  runbook:  {stage.runbook_phase}")
    print(f"  summary:  {stage.summary}")
    spec = experiment_by_id(stage.experiment_id)
    actions = infra.materialize(root, dry_run=dry)
    actions.extend(experiments.materialize_one(root, spec, dry_run=dry))
    _print_actions(actions)

    if stage.id == "02":
        return cmd_preflight(args)
    if stage.id == "04":
        for action in ("read", "host-root", "credentials", "unrestricted-mount"):
            decision = policy.decide(action)
            print(f"  policy {action}: {decision['decision']} — {decision['reason']}")
            policy.record(root, decision, dry_run=dry)
    if stage.id == "10":
        return cmd_accept(args)
    if stage.id == "11" and args.apply and getattr(args, "i_accept_third_party_installer", False):
        print("Refusing to pipe curl | bash. Official installer:")
        print("  curl -fsSL https://antigravity.google/cli/install.sh | bash")
        print("Run that yourself after reviewing the script. Templates are already copied to .agents/")
    elif stage.id == "11":
        print("Antigravity CLI installer is NOT executed by labctl.")
        print("Templates synced to .agents/. Official docs: https://antigravity.google/docs/cli/install/")

    if args.apply:
        state = statefile.load(root / "state.yaml")
        statefile.set_path(state, f"stages.{stage.name}", "materialized")
        statefile.save(root / "state.yaml", state, dry_run=False)
    return 0


def cmd_stack(args: argparse.Namespace) -> int:
    root = _root(args)
    if args.stack_command == "files":
        actions = infra.materialize(root, dry_run=bool(args.dry_run))
        _print_actions(actions)
        return 0
    stack = args.name
    action = "up" if args.stack_command == "up" else "down"
    result = infra.compose(root, stack, action, apply=args.apply)
    _json(result) if args.json else print(result)
    if result.get("status") == "FAIL":
        return 1
    return 0


def cmd_experiment(args: argparse.Namespace) -> int:
    root = _root(args)
    if args.exp_command == "list":
        print(f"{'ID':<28} {'STAGE':<6} VM")
        for spec in EXPERIMENTS:
            print(f"{spec.id:<28} {spec.stage:<6} {spec.vm_profile or '-'}")
        return 0
    spec = experiment_by_id(args.id)
    if args.exp_command == "init":
        actions = experiments.materialize_one(root, spec, dry_run=bool(args.dry_run))
        _print_actions(actions)
        return 0
    # run
    exp_dir = root / "experiments" / spec.id
    run_sh = exp_dir / "run.sh"
    print(f"experiment {spec.id}")
    print(f"  document: {spec.document}")
    print(f"  target:   {spec.target}")
    print(f"  vm:       {spec.vm_profile or 'host-side'}")
    if not run_sh.exists():
        print("missing run.sh — run: ./scripts/bin/labctl init")
        return 1
    if spec.vm_profile and not shutil.which("limactl"):
        print("limactl not installed: status=NOT_DEPLOYED")
        print("Install Lima/QEMU, then review experiments/%s/lima.yaml" % spec.id)
        return 0
    if not args.apply:
        print(f"dry-run: would execute {run_sh}")
        print("pass --apply after security review to run the script")
        return 0
    import subprocess

    proc = subprocess.run(["bash", str(run_sh)], check=False)
    return proc.returncode


def cmd_accept(args: argparse.Namespace) -> int:
    root = _root(args)
    result = accept.evaluate(root)
    out = root / "reports" / "acceptance-scorecard.yaml"
    text = yamlio.dump(result)
    if not args.dry_run:
        out.parent.mkdir(parents=True, exist_ok=True)
        out.write_text(text, encoding="utf-8")
        print(f"wrote {out}")
    if args.json:
        _json(result)
    else:
        print(f"acceptance overall: {result['overall']}  preflight: {result['preflight']}")
        for level in result["levels"]:
            print(f"  L{level['level']} {level['name']:<16} {level['summary']}")
            for check in level["checks"]:
                print(f"      {check['status']:<14} {check['id']}: {check['detail']}")
    return 0 if result["overall"] != "FAIL" else 2


def cmd_doctor(args: argparse.Namespace) -> int:
    args.json = getattr(args, "json", False)
    rc = cmd_preflight(args)
    print("---")
    cmd_accept(args)
    print("---")
    root = _root(args)
    print("git:", "ok" if (root / ".git").exists() else "missing")
    print("lima:", shutil.which("limactl") or "NOT_DEPLOYED")
    print("docker:", shutil.which("docker") or "NOT_DEPLOYED")
    print("podman:", shutil.which("podman") or "NOT_DEPLOYED")
    return rc


def cmd_policy(args: argparse.Namespace) -> int:
    root = _root(args)
    decision = policy.decide(args.action)
    path = policy.record(root, decision, dry_run=not args.apply)
    print(yamlio.dump(decision).rstrip())
    print(f"event_log: {path} ({'appended' if args.apply else 'dry-run'})")
    return 0 if decision["decision"] != "deny" else 3


def cmd_hash(args: argparse.Namespace) -> int:
    root = _root(args)
    path = hashing.write_manifest(root, dry_run=bool(args.dry_run))
    data = hashing.inventory(root)
    print(f"{len(data['files'])} files  manifest={path}  dry_run={bool(args.dry_run)}")
    return 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="labctl",
        description="Create and operate the AI Security Research Lab stack (docs 01–11).",
    )
    parser.add_argument("--root", help="Repository root (auto-detected)")
    parser.add_argument("--json", action="store_true", help="JSON output where applicable")
    parser.add_argument(
        "--apply",
        action="store_true",
        help="Start processes, record live host state, or execute experiment scripts",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Preview file writes without touching the repository",
    )
    parser.add_argument("--version", action="version", version=f"labctl {__version__}")
    sub = parser.add_subparsers(dest="command", required=True)

    sub.add_parser("status", help="Show state.yaml and host facts")
    sub.add_parser("stages", help="List document-mapped stages")
    sub.add_parser("init", help="Materialize infra stack + every stage experiment")
    sub.add_parser("preflight", help="Host checks from document 02")
    sub.add_parser("accept", help="Acceptance matrix from document 10")
    sub.add_parser("doctor", help="Preflight + acceptance + runtime inventory")
    sub.add_parser("hash", help="Rewrite PACKAGE-MANIFEST.json")

    st = sub.add_parser("stage", help="Run one document stage")
    st.add_argument(
        "id",
        nargs="+",
        help="Stage id (00-11, name, or experiment id). Optional leading 'run'.",
    )
    st.add_argument(
        "--i-accept-third-party-installer",
        action="store_true",
        help="Acknowledge the Antigravity installer (still not auto-run)",
    )

    sk = sub.add_parser("stack", help="Infrastructure compose stacks")
    sk_sub = sk.add_subparsers(dest="stack_command", required=True)
    sk_sub.add_parser("files", help="Write infra/* only")
    up = sk_sub.add_parser("up", help="docker/podman compose up (localhost)")
    up.add_argument("name", choices=sorted(infra.COMPOSE_STACKS))
    down = sk_sub.add_parser("down", help="docker/podman compose down")
    down.add_argument("name", choices=sorted(infra.COMPOSE_STACKS))

    ex = sub.add_parser("experiment", help="Stage experiments")
    ex_sub = ex.add_subparsers(dest="exp_command", required=True)
    ex_sub.add_parser("list", help="List generated experiments")
    ex_init = ex_sub.add_parser("init", help="Write one experiment directory")
    ex_init.add_argument("id")
    ex_run = ex_sub.add_parser("run", help="Show or execute an experiment run.sh")
    ex_run.add_argument("id")

    pol = sub.add_parser("policy", help="Local policy gate (document 04)")
    pol_sub = pol.add_subparsers(dest="policy_command", required=True)
    chk = pol_sub.add_parser("check")
    chk.add_argument("--action", required=True, help="read|project-write|git|vm|host-root|credentials|...")

    return parser


def main(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    # policy check uses nested command
    if args.command == "policy":
        return cmd_policy(args)
    handlers = {
        "status": cmd_status,
        "stages": cmd_stages,
        "init": cmd_init,
        "preflight": cmd_preflight,
        "stage": cmd_stage,
        "stack": cmd_stack,
        "experiment": cmd_experiment,
        "accept": cmd_accept,
        "doctor": cmd_doctor,
        "hash": cmd_hash,
    }
    try:
        return handlers[args.command](args)
    except KeyError as exc:
        parser.error(str(exc))
        return 2
    except FileNotFoundError as exc:
        print(f"labctl: {exc}", file=sys.stderr)
        return 2
