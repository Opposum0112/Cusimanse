"""Document-mapped stages, experiments, and stack layout.

IDs match 01–11 plus runbook phase 0 (bootstrap). Each stage can
materialize files, run host probes, and emit an experiment directory.
"""

from __future__ import annotations

from dataclasses import dataclass, field


@dataclass(frozen=True)
class Stage:
    id: str
    name: str
    document: str
    runbook_phase: str
    summary: str
    experiment_id: str
    vm_profile: str | None
    apply_installs: tuple[str, ...] = ()


@dataclass(frozen=True)
class ExperimentSpec:
    id: str
    stage: str
    document: str
    name: str
    objective: str
    hypothesis: str
    target: str
    vm_profile: str | None
    network_policy: str
    instrumentation: tuple[str, ...]
    success: tuple[str, ...]
    notes: str = ""
    extra_files: dict[str, str] = field(default_factory=dict)


STAGES: tuple[Stage, ...] = (
    Stage(
        id="00",
        name="repo-bootstrap",
        document="03-deployment-runbook.md",
        runbook_phase="Phase 0 — Repository bootstrap",
        summary="Create the repository layout (infra, policies, blackboard, experiments).",
        experiment_id="stage-00-repo-bootstrap",
        vm_profile=None,
    ),
    Stage(
        id="01",
        name="architecture",
        document="01-deployment-architecture.md",
        runbook_phase="Architecture contract",
        summary="Materialize plane layout and harness-router config from the architecture.",
        experiment_id="stage-01-architecture",
        vm_profile=None,
    ),
    Stage(
        id="02",
        name="host-preflight",
        document="02-system-requirements.md",
        runbook_phase="Phase 1 — Host preflight",
        summary="Probe CPU, RAM, disk, KVM, QEMU, Lima, and baseline tools.",
        experiment_id="stage-02-host-preflight",
        vm_profile=None,
    ),
    Stage(
        id="03",
        name="runbook-stack",
        document="03-deployment-runbook.md",
        runbook_phase="Phases 2–5 — Harnesses, Lima/QEMU, container runtime",
        summary="Write Lima profiles and container-runtime selection files.",
        experiment_id="stage-03-runbook-stack",
        vm_profile="minimal",
        apply_installs=("qemu", "lima", "docker-or-podman"),
    ),
    Stage(
        id="04",
        name="security-model",
        document="04-security-model.md",
        runbook_phase="Security controls",
        summary="Write permission tiers, mount denylist, and local policy gate.",
        experiment_id="stage-04-security-model",
        vm_profile=None,
    ),
    Stage(
        id="05",
        name="multi-agent",
        document="05-multi-agent-operating-model.md",
        runbook_phase="Phase 12 — Agent configuration",
        summary="Write blackboard contract, harness router, and agent role files.",
        experiment_id="stage-05-multi-agent",
        vm_profile=None,
    ),
    Stage(
        id="06",
        name="observability",
        document="06-observability-and-evidence.md",
        runbook_phase="Phases 10–11 — OTel/Phoenix and instrumentation",
        summary="Write localhost-only Phoenix/OTel compose and capture helpers.",
        experiment_id="stage-06-observability",
        vm_profile=None,
        apply_installs=("otel-phoenix",),
    ),
    Stage(
        id="07",
        name="experiment-framework",
        document="07-experiment-framework.md",
        runbook_phase="Experiment contract",
        summary="Install the experiment directory contract and shared shell helpers.",
        experiment_id="stage-07-experiment-framework",
        vm_profile=None,
    ),
    Stage(
        id="08",
        name="go-install-001",
        document="08-go-install-001.md",
        runbook_phase="Phase 13 — First integration test",
        summary="Wire packages/labprobe as the pinned go-install-001 target.",
        experiment_id="go-install-001",
        vm_profile="security-research",
        apply_installs=("go",),
    ),
    Stage(
        id="09",
        name="operations",
        document="09-operations-and-maintenance.md",
        runbook_phase="Operations",
        summary="Daily health probes: git, disk, VMs, compose stacks.",
        experiment_id="stage-09-operations",
        vm_profile=None,
    ),
    Stage(
        id="10",
        name="acceptance",
        document="10-validation-and-acceptance.md",
        runbook_phase="Phase 14 / acceptance matrix",
        summary="Run the seven-level acceptance matrix and write a scorecard.",
        experiment_id="stage-10-acceptance",
        vm_profile=None,
    ),
    Stage(
        id="11",
        name="antigravity",
        document="11-current-antigravity-reference.md",
        runbook_phase="Phase 2 — Antigravity CLI",
        summary="Install workspace agent/skill/MCP templates; never silent curl|bash.",
        experiment_id="stage-11-antigravity",
        vm_profile=None,
        apply_installs=("antigravity",),
    ),
)


def stage_by_id(stage_id: str) -> Stage:
    for stage in STAGES:
        if stage.id == stage_id or stage.name == stage_id or stage.experiment_id == stage_id:
            return stage
    known = ", ".join(s.id for s in STAGES)
    raise KeyError(f"Unknown stage {stage_id!r}. Known: {known}")


INSTRUMENTATION_FULL = (
    "process",
    "syscall",
    "filesystem",
    "dns",
    "network",
    "packet",
    "security-events",
)


EXPERIMENTS: tuple[ExperimentSpec, ...] = (
    ExperimentSpec(
        id="stage-00-repo-bootstrap",
        stage="00",
        document="03-deployment-runbook.md",
        name="Repository layout bootstrap",
        objective="Create the directory contract required by the deployment runbook.",
        hypothesis="labctl init produces a complete, hashed layout without secrets.",
        target="python3 -m labctl init",
        vm_profile=None,
        network_policy="none",
        instrumentation=("filesystem",),
        success=(
            "infra/, policies/, blackboard/, experiments/ exist",
            "no secret files written",
            "PACKAGE-MANIFEST hashes match generated files",
        ),
    ),
    ExperimentSpec(
        id="stage-01-architecture",
        stage="01",
        document="01-deployment-architecture.md",
        name="Architecture plane contract",
        objective="Confirm every architecture plane has a corresponding infra artifact.",
        hypothesis="Harness-neutral routing can be represented as committed YAML without selecting a single vendor as the security boundary.",
        target="python3 -m labctl stage run 01",
        vm_profile=None,
        network_policy="none",
        instrumentation=("filesystem",),
        success=(
            "infra/harness-router.yaml exists",
            "each plane listed in 01-deployment-architecture.md has a file under infra/",
        ),
    ),
    ExperimentSpec(
        id="stage-02-host-preflight",
        stage="02",
        document="02-system-requirements.md",
        name="Host preflight",
        objective="Measure whether the host can run one Lima VM with headroom on 16 GB RAM.",
        hypothesis="A failing preflight is more valuable than a silent install on an undersized host.",
        target="python3 -m labctl preflight",
        vm_profile=None,
        network_policy="none",
        instrumentation=("process", "filesystem"),
        success=(
            "architecture recorded",
            "RAM and disk recorded",
            "QEMU/Lima presence recorded as PASS, PARTIAL, or NOT_DEPLOYED",
        ),
    ),
    ExperimentSpec(
        id="stage-03-runbook-stack",
        stage="03",
        document="03-deployment-runbook.md",
        name="Lima/QEMU and container runtime files",
        objective="Materialize disposable VM profiles and a single container runtime choice.",
        hypothesis="Empty host mounts plus qemu vmType are enough to boot a disposable experiment VM.",
        target="python3 -m labctl stage run 03",
        vm_profile="minimal",
        network_policy="restricted",
        instrumentation=("process", "filesystem"),
        success=(
            "infra/lima/{minimal,default,security-research}.yaml exist",
            "mounts: [] in every profile",
            "container runtime recorded in state.yaml",
        ),
    ),
    ExperimentSpec(
        id="stage-04-security-model",
        stage="04",
        document="04-security-model.md",
        name="Permission tiers and mount denylist",
        objective="Encode the threat model as a local policy gate that agents can query.",
        hypothesis="Privileged operations (sudo, host mounts, credentials) default to deny.",
        target="python3 -m labctl policy check --action host-root",
        vm_profile=None,
        network_policy="none",
        instrumentation=("security-events",),
        success=(
            "host-root denied by default",
            "read-tier allowed",
            "policy events append to JSONL",
        ),
    ),
    ExperimentSpec(
        id="stage-05-multi-agent",
        stage="05",
        document="05-multi-agent-operating-model.md",
        name="Blackboard and harness routing",
        objective="Create structured agent handoff artifacts instead of copied chat history.",
        hypothesis="A planner → reviewer → executor chain can run against blackboard files alone.",
        target="python3 -m labctl stage run 05",
        vm_profile=None,
        network_policy="none",
        instrumentation=("filesystem",),
        success=(
            "blackboard examples exist",
            "infra/harness-router.yaml maps each role",
            "findings.jsonl schema matches AGENTS.md",
        ),
    ),
    ExperimentSpec(
        id="stage-06-observability",
        stage="06",
        document="06-observability-and-evidence.md",
        name="AI and runtime observability stack",
        objective="Stand up localhost-only Phoenix + OTel collector files and capture helpers.",
        hypothesis="Binding 127.0.0.1 prevents accidental public exposure of traces.",
        target="python3 -m labctl stack up --stack observability --dry-run",
        vm_profile=None,
        network_policy="localhost-only",
        instrumentation=("process", "network"),
        success=(
            "compose binds 127.0.0.1",
            "no secrets in compose files",
            "evidence helpers hash artifacts",
        ),
    ),
    ExperimentSpec(
        id="stage-07-experiment-framework",
        stage="07",
        document="07-experiment-framework.md",
        name="Experiment directory contract",
        objective="Verify every experiment has the required files from doc 07.",
        hypothesis="A generator can keep 12 experiments consistent with the contract.",
        target="python3 -m labctl experiment list",
        vm_profile=None,
        network_policy="none",
        instrumentation=("filesystem",),
        success=(
            "each experiment has experiment.yaml, README, capture/run/cleanup",
            "VM experiments have lima.yaml",
        ),
    ),
    ExperimentSpec(
        id="go-install-001",
        stage="08",
        document="08-go-install-001.md",
        name="Pinned Go package installation observation",
        objective="Observe a pinned in-repo Go install (packages/labprobe) inside a disposable Lima/QEMU VM.",
        hypothesis="The install produces correlated process, filesystem, DNS and network evidence that matches Go module behavior.",
        target="go install github.com/Opposum0112/ai-security-lab/packages/labprobe@v0.1.0",
        vm_profile="security-research",
        network_policy="controlled",
        instrumentation=INSTRUMENTATION_FULL,
        success=(
            "workload ran in the disposable VM",
            "evidence captured, hashed, reduced",
            "independent verification recorded",
            "VM deleted after evidence preservation",
            "result committed to Git",
        ),
        notes=(
            "Default mode copies packages/labprobe into the VM and installs from the local path "
            "so a private GitHub repo still works. Networked module-proxy mode is opt-in."
        ),
    ),
    ExperimentSpec(
        id="stage-09-operations",
        stage="09",
        document="09-operations-and-maintenance.md",
        name="Daily operations probe",
        objective="Inspect git, disk, VM inventory and compose health without changing the stack.",
        hypothesis="Layered troubleshooting (host → QEMU → Lima → MCP → gateway) localizes failures faster than a full restart.",
        target="python3 -m labctl doctor",
        vm_profile=None,
        network_policy="none",
        instrumentation=("process", "filesystem"),
        success=("report written under reports/", "no secrets in the report"),
    ),
    ExperimentSpec(
        id="stage-10-acceptance",
        stage="10",
        document="10-validation-and-acceptance.md",
        name="Seven-level acceptance matrix",
        objective="Score host, execution, agent, security, model, observability and experiment levels.",
        hypothesis="NOT_DEPLOYED is a valid honest state and must not be reported as PASS.",
        target="python3 -m labctl accept",
        vm_profile=None,
        network_policy="none",
        instrumentation=("filesystem",),
        success=("scorecard YAML written", "each check is PASS, PARTIAL, FAIL, or NOT_DEPLOYED"),
    ),
    ExperimentSpec(
        id="stage-11-antigravity",
        stage="11",
        document="11-current-antigravity-reference.md",
        name="Antigravity workspace templates",
        objective="Install project agents, skills and MCP stubs without running the upstream installer.",
        hypothesis="Workspace files can be version-controlled independently of the CLI binary.",
        target="python3 -m labctl stage run 11",
        vm_profile=None,
        network_policy="none",
        instrumentation=("filesystem",),
        success=(
            ".agents/agents and .agents/skills populated from antigravity/",
            "installer command printed, not executed, unless --apply --i-accept-third-party-installer",
        ),
    ),
)


def experiment_by_id(exp_id: str) -> ExperimentSpec:
    for spec in EXPERIMENTS:
        if spec.id == exp_id:
            return spec
    known = ", ".join(e.id for e in EXPERIMENTS)
    raise KeyError(f"Unknown experiment {exp_id!r}. Known: {known}")
