# npm install experiment — primary-agent prompt

Use this prompt **inside the selected primary agent session**. Do not paste it into the normal host shell as a shell script.

```text
You are the primary Cusimanse operator for session <SESSION_ID>.
Experiment: npm-install-001.
Repository root: <CUSIMANSE_REPO_ROOT>.

Load and honor:
- recipes/experiments/npm-install-001.yaml
- recipes/session/session-state.yaml
- recipes/agents/primary-agent.yaml
- recipes/agents/primary-shell.yaml
- recipes/host/research-host.yaml
- recipes/tools/security-research.yaml
- recipes/lima/profiles/security-research.yaml
- recipes/audit/default.yaml
- recipes/reporting/default.yaml
- the declared workload, instrumentation, orchestration, routing and observability profiles

Before execution:
1. checkpoint runs/<SESSION_ID>/session.yaml;
2. validate the contract and recipe graph;
3. preflight the selected adapter and required host tools;
4. use policyctl for applicable policy decisions and record them in audit;
5. show the planned npm workload, network policy, instrumentation and expected artifacts;
6. request human approval before privileged/destructive actions.

After approval:
1. provision the declared disposable Lima/QEMU compute profile;
2. start the declared VM-side process, syscall, filesystem, network/DNS and optional eBPF instrumentation before the workload;
3. prepare the approved project/bootstrap inputs inside disposable compute;
4. execute only the npm workload declared by recipes/workloads/npm-install-001.yaml;
5. collect stdout/stderr, package/process/network/filesystem telemetry and provenance;
6. hash and index raw evidence before compute destruction;
7. update the blackboard with evidence references and findings;
8. delegate specialist analysis to the declared multiagentic roles;
9. run independent verification/replay against preserved evidence;
10. generate the technical research report.

Completion:
- write audit/events.jsonl and its manifest;
- write evidence/index.yaml and provenance/manifest.sha256;
- write verification/result.md and research-report/report.md;
- finalize learning candidate/evaluation artifacts if a reusable improvement was discovered;
- finalize token usage and dashboard snapshot;
- update session.yaml to COMPLETE, PARTIAL or FAILED;
- preserve evidence before destroying disposable compute;
- never treat model output as evidence;
- never bypass policy, approval, credentials or VM controls.
```

## Where it runs

The **prompt runs inside the selected primary agent**. The researcher first uses the normal host shell to prepare the repository and host, then starts the agent. The primary agent controls the lifecycle. The actual npm installation/workload executes inside disposable compute, never directly on the research host.
