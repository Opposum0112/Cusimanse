# Capability Registry and Resolver

Commit 5 establishes the deterministic capability boundary between normalized CAR intents and later operation/adapters.

## Flow

```text
CapabilityIntent
      ↓
CapabilityRegistry
      ↓
Deterministic resolution
      ↓
ResolvedCapability
      ↓
Policy / approval / operation engine
```

## Capability descriptor

A registered capability declares:

- `name` — stable capability identifier, such as `vm.create` or `workload.npm.install`.
- `version` — capability contract version.
- `operationKinds` — operation categories the capability can produce.
- `description` — optional human-readable documentation.
- `validateParameters` — optional deterministic parameter validation hook.
- `metadata` — optional non-executable metadata for downstream runtime components.

The registry deliberately does **not** contain shell commands, credentials, adapter instances, or arbitrary executable callbacks.

## Resolution guarantees

`CapabilityRegistry.resolve()`:

1. performs exact-name lookup;
2. rejects unknown capabilities;
3. validates parameters when a descriptor provides a validator;
4. returns the descriptor and original parameters;
5. performs no execution or authorization.

Duplicate registration is rejected rather than silently replacing an existing definition.

`list()` returns descriptors in lexicographic name order, providing deterministic registry inspection.

## Security boundary

Capability resolution is not authorization. A resolved capability still has to pass the CAR policy and approval state machine before an operation can reach an adapter.

```text
Recipe
  ↓
Compiler
  ↓
IR
  ↓
Planner
  ↓
Capability resolution   ← Commit 5
  ↓
Policy + approval       ← later
  ↓
Operation               ← later
  ↓
Adapter                 ← later
```

This keeps the registry declarative and prevents capability lookup from becoming an execution escape hatch.
