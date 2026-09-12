# Agent and adapter strategy

## Decision

Cusimanse should be **agent-neutral**. Goose may remain the reference adapter, but it should not be a permanent architectural dependency. A primary operator may be selected at bootstrap from the adapter registry.

The safest target is an **evidence-bounded self-learning operator**: the agent can learn workflow improvements from verified runs, but cannot autonomously modify the security boundary, privileges, credentials, approval rules, or evidence-integrity controls.

## What the primary operator owns

1. Load the YAML project/experiment contract.
2. Resolve recipes and capabilities.
3. Plan the lifecycle.
4. Request approvals for gated actions.
5. Execute approved adapter actions.
6. Observe and collect telemetry/evidence.
7. Trigger reduction, forensics and independent verification.
8. Produce user-facing finding reports and audit records.
9. Checkpoint learning state.
10. Propose reviewed recipe/adapter improvements.

## What it must never own

- VM/OS isolation enforcement.
- Host credential access.
- Unrestricted host mounts.
- Security-policy bypass.
- Autonomous privilege escalation.
- Self-approval of privileged/destructive operations.
- Evidence truth or final verification.

## Self-learning model

Use a two-tier state model:

- **Run memory:** observations, failures, successful plans and measured token/tool cost under `runs/<run-id>/learning/`.
- **Promotable knowledge:** reviewed change proposals that can update non-security recipe defaults, routing hints, adapter command templates or evidence-reduction heuristics.

Every promotion requires reproducible evidence, validation, independent verification and human approval. Keep the base contract immutable and support rollback.

## Primary-operator candidates

| Adapter | Primary role | Expected integration | Recommendation |
|---|---|---|---|
| Goose | operator/executor | mature reference recipe | keep reference during migration |
| OpenCode | operator/executor | CLI/plugin adapter | strong candidate |
| Grok Build | operator/orchestrator | provider-specific adapter | evaluate availability first |
| Antigravity | operator/orchestrator | local/provider-specific adapter | evaluate command/API surface first |
| Pi | operator/executor | minimal programmable harness | strong candidate for custom loop |
| Codex | operator/executor | CLI/SDK-oriented adapter | strong candidate |
| Prime Intellect | self-improving operator | research-oriented adapter | promising, higher integration risk |
| Claude Code | enterprise operator | enterprise controls/secrets/audit | enterprise candidate |
| Devin | enterprise operator | provider-managed integration | enterprise candidate |

Provider or CLI names are not installers unless the adapter defines a verified installation path.

## Implementation steps when changing primary operator

### Phase 1 — select

1. Run `scripts/prerequisites.sh`.
2. Present supported adapter choices.
3. User selects exactly one primary operator.
4. Save selection to a local, non-secret configuration/recipe.
5. Install only the selected adapter and its declared dependencies.

### Phase 2 — preflight

1. Verify binary/API availability.
2. Verify provider configuration without printing secrets.
3. Verify adapter can load the common primary-agent contract.
4. Verify YAML recipe loading.
5. Verify policy configuration.
6. Verify audit and evidence paths.
7. Run a non-destructive adapter smoke test.
8. Mark unavailable features `NOT_DEPLOYED`.

### Phase 3 — controlled execution

1. Start from the YAML experiment contract.
2. Build the plan.
3. Request approvals.
4. Provision the disposable VM.
5. Start instrumentation before workload execution.
6. Execute only approved actions.
7. Capture, hash and preserve evidence.
8. Run independent verification.
9. Generate finding reports.
10. Destroy the VM after preservation.

### Phase 4 — learning

1. Compare run outcomes with prior verified runs.
2. Identify reproducible improvements.
3. Create a machine-readable change proposal.
4. Run project validation and relevant experiment replay.
5. Require human review.
6. Promote only approved non-security changes.
7. Keep rollback metadata and audit trail.

## Adapter contract shape

Each adapter recipe should declare:

- identity and status
- executable/API entry point
- installation/preflight method
- project contract path
- recipe inputs/outputs
- approval behavior
- audit behavior
- learning contract
- limitations and `NOT_DEPLOYED` conditions

All adapters consume the same experiment semantics. Adapter-specific prompts, tools and provider wiring remain behind the adapter boundary.

## Additional extensions worth evaluating

- MCP client/server integration using the existing registry.
- OpenTelemetry-based agent and runtime traces.
- Token accounting plus Ponytail-style context reduction.
- Durable run checkpoints and resumable orchestration.
- Evaluation/replay harness for adapter equivalence.
- Policy-as-code tests for adapter actions.
- Signed/hashed learning proposals and recipe promotion.
- SBOM/SLSA provenance for installed adapter components.
- Finding-specific report generation rather than only project-level reports.
- External workflow integration (for example Kestra) as a trigger/observer, never as the security boundary.

## Acceptance rule

An adapter is `PASS` only after an actual end-to-end run produces preserved evidence. Documentation and configuration alone remain `NOT_DEPLOYED` or `PARTIAL`.
