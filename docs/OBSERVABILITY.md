# Observability and research reporting

Cusimanse keeps agent telemetry separate from experiment evidence.

> Goose observes the agent; Cusimanse observes the experiment.

## Observability planes

| Plane | Tooling | Primary output | Access |
|---|---|---|---|
| Agent/LLM telemetry | Goose + OpenTelemetry | traces, spans, model/tool events | `runs/<session-id>/observability/` plus configured OTLP backend |
| LLM trace UI | Phoenix | traces and spans | `http://127.0.0.1:6006` when Phoenix is running |
| Session/token view | ClawMetry | Goose sessions and token/cost-oriented visibility | `http://127.0.0.1:8900` when ClawMetry is running |
| Security monitoring | Numbat | NDJSON monitoring records | `$HOME/.numbat/cusimanse.ndjson` |
| Independent observer | Aegis | observer data | `$HOME/.local/share/cusimanse/aegis/` |
| Export/transport | OpenTelemetry | OTLP telemetry | `http://127.0.0.1:4318` by default |

These services are observers/gateways, not containment boundaries. The Lima/QEMU guest remains the execution boundary.

## Start and inspect

Install/configure the stack first:

```bash
./scripts/install.sh
./scripts/preflight.sh
./scripts/tools.sh observability
```

The installer writes non-secret endpoints to `~/.config/cusimanse/observability.env`.

```bash
source ~/.config/cusimanse/observability.env
```

### Numbat reports

Numbat records are kept in:

```text
~/.numbat/cusimanse.ndjson
```

Inspect the stream with:

```bash
./scripts/tools.sh numbat
jq -c '.' ~/.numbat/cusimanse.ndjson
```

Cusimanse does not treat a monitoring record as final evidence until it is associated with the session and preserved by the evidence workflow.

### Phoenix traces

Phoenix is configured as an OTEL-compatible telemetry destination. With Phoenix running locally, open:

```text
http://127.0.0.1:6006
```

Use the session/run correlation fields to connect agent traces with a research run. The canonical correlation set is:

```text
experiment_id, session_id, run_id, agent_id, role, skill,
capability, workload_id, trace_id, timestamp
```

If Phoenix is not running, the experiment must not invent traces. The session records the observability status as unavailable/partial.

### ClawMetry token usage

ClawMetry is the Goose-session/token visibility plane. When its UI is running, open:

```text
http://127.0.0.1:8900
```

For a reproducible run, preserve a token-usage snapshot under:

```text
runs/<session-id>/observability/token-usage.yaml
```

The snapshot should include provider/model, input tokens, output tokens, total tokens, estimated cost when available, timestamp, and the associated `session_id`/`trace_id`. Never place API keys in the snapshot.

## Research report generation

`report-generator` is a first-class role. It consumes the research requirements, preserved evidence, specialist analyses and independent verification; it does not create new execution authority.

Expected output:

```text
runs/<session-id>/research-report/report.md
runs/<session-id>/research-report/report.yaml
```

The report should answer the declared research question, distinguish observed facts from interpretation, state confidence and limitations, link conclusions to evidence, and record whether the result is complete or partial.

Recommended sequence:

```text
requirements
   ↓
evidence collection
   ↓
parallel specialist analysis
   ├── runtime
   ├── forensics
   └── detection
   ↓
independent verification
   ↓
report-generator
   ↓
preserve report + provenance
   ↓
destroy disposable compute
```

## Learning loop

Learning is disabled by default. A completed and independently verified experiment can produce a candidate reusable skill. The candidate must be replayed and independently verified before a researcher approves promotion into `skills/validated/`.

```text
verified experience
      ↓
 candidate skill
      ↓
 authorized replay
      ↓
 evaluation + independent verification
      ↓
 human approval
      ↓
 skills/validated/
```

A learned skill cannot alter the base contract, security policy, trusted profiles, or execution boundary.
