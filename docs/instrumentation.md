# Instrumentation (strace and Sysdig)

The operator does not run CLI tools. It proposes a **named capability**. The host adapter runs `strace` or `sysdig` inside the disposable VM with parameters the runtime already checked.

| Skill | Capability | What the operator may set |
|---|---|---|
| process-strace | `instrumentation.strace` | `target`: `npm` \| `node` \| `workload`; `durationSeconds` 1–120; `outputPath` under `/workspace/` |
| runtime-sysdig | `instrumentation.sysdig` | `profile`: `process` \| `network` \| `file`; `durationSeconds` 1–120; `outputPath` under `/workspace/` |

Free-form argv, Sysdig filters, or paths outside `/workspace` are rejected before any adapter runs.

Example proposal:

```json
{
  "intent": "trace npm during install",
  "capability": "instrumentation.strace",
  "parameters": {
    "target": "npm",
    "durationSeconds": 30,
    "outputPath": "/workspace/evidence/strace.out"
  },
  "complete": false
}
```

Add both names to that lab’s `allowed_capabilities` and policy, and register an adapter that execs the CLI **inside** the Lima VM. The starter lab host only validates parameters and records a placeholder evidence URI.
