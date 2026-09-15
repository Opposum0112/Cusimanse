# Runtime implementation and phased migration

Cusimanse is an agent-operated research platform, not an agent replacement. The agent owns research intelligence; the Go runtime owns controlled capability execution.

## Boundary

```text
Researcher intent
      ↓
Goose / agent + Summon specialists
      ↓  intent, hypothesis, capability request
Cusimanse Go runtime
      ├─ requirements/profile resolution
      ├─ policy decision
      ├─ execution plan
      ├─ capability registry
      ├─ lifecycle state machine
      └─ evidence/preservation gate
      ↓
Lima/QEMU + fixed workloads + instrumentation
      ↓
evidence + observations
      ↓
agent analysis → verification → report
```

The governing rule is: **the agent decides what research to do; Cusimanse decides whether and how that research may execute.** Agent adapters must not bypass the capability boundary.

## Ten runtime completion workstreams

1. **Typed runtime contracts** — stable models for experiments, requirements, profiles, capabilities, policy decisions, sessions, evidence, observations and run results.
2. **Native lifecycle engine** — resolve → provision → configure → execute → collect → verify → report → preserve → destroy, with cancellation and failure handling.
3. **Native Go policy engine** — evaluate allow/approval/deny decisions from the declarative policy source; keep `policyctl` as a compatibility CLI until parity is proven.
4. **Native recipe/profile resolution** — produce an immutable execution plan from experiment requirements and trusted registered profiles; reject unresolved or ambiguous plans.
5. **Real capabilities** — model Lima/QEMU, workloads, instrumentation and evidence operations behind a capability interface. External binaries may remain audited adapters where OS APIs are preferable to reimplementation.
6. **Single execution engine** — agents submit capability requests to one runtime path; no competing orchestration authority is introduced.
7. **Transactional evidence** — collection must flush, hash and verify preservation before destruction is allowed. Failed experiments should preserve partial evidence where possible.
8. **Runtime observability** — emit experiment/session/run/agent/role/skill/capability/workload/trace/timestamp correlation fields without storing secrets.
9. **Agent integration** — Goose is the native reference operator; Summon provides specialist delegation; OpenCode, Hermes, Antigravity and Pi remain adapters that hand off intent to the same runtime.
10. **Shell reduction and cleanup** — retain shell for bootstrap and unavoidable external tools, remove duplicate registries and `init()` interception as native Go paths reach parity.

## Phased implementation

### Phase 1 — Core contracts and safety

- `internal/model`: domain contracts.
- `internal/policy`: fail-closed policy decision API.
- `internal/recipes`: deterministic YAML loading and validation.
- `internal/profiles`: trusted profile resolution.
- `internal/session`: session store/state persistence.
- `internal/evidence`: hashing, manifests and preservation verification.

### Phase 2 — Execution engine

- `internal/execution`: immutable execution plans and lifecycle state machine.
- capability registry and request/result contracts.
- context cancellation, timeouts and failure transitions.
- policy gates before every privileged or external capability.

### Phase 3 — Infrastructure adapters

- Lima/QEMU provisioning adapter.
- fixed workload handlers for Go/npm.
- process/syscall/filesystem/network instrumentation adapters.
- deterministic configuration and guest inventory checks.

### Phase 4 — Evidence and reproducibility

- evidence collector and provenance records.
- SHA-256 manifests and independent verification.
- preservation gate before destruction.
- report inputs derived only from preserved evidence and declared requirements.

### Phase 5 — Agent integration

- Goose native recipe and Summon path.
- explicit adapter contract for other agents.
- role/skill selection remains agent-side; authority remains runtime-side.
- learning stays disabled by default and cannot mutate policy, profiles or containment.

### Phase 6 — Cleanup and convergence

- eliminate duplicate operational registry definitions.
- make `policyctl`, `session.sh` and related helpers compatibility wrappers over tested Go APIs where practical.
- remove `ops.go` `init()` command interception after all callers use explicit Go routing.
- keep scripts only where they are genuinely better suited to bootstrap/OS integration.

## Critical invariants

The test suite should permanently enforce that:

- denied actions never execute a capability;
- approval-required actions cannot execute without explicit approval;
- unknown actions fail closed;
- no unresolved or ambiguous profile can produce an execution plan;
- destroy cannot occur directly after execution/reporting;
- evidence preservation must precede destruction;
- partial/failed runs attempt evidence collection;
- cancellation reaches the active capability;
- agent-generated infrastructure cannot become trusted configuration;
- learning cannot grant privileges or alter the base security boundary.

## Migration strategy

Use a strangler pattern rather than a rewrite:

```text
              Cusimanse Go runtime
                    /       \
          native capability  legacy adapter
                    \       /
                     same contracts
                         ↓
                    same policy
                         ↓
                    same evidence
```

Existing shell helpers are therefore treated as implementation adapters during migration, not as a second architecture. Each replacement should first gain equivalent tests, then become the primary path, then leave the old helper only as a compatibility surface.
