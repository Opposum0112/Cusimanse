# Runtime orchestration

The runtime composes the deterministic CAR boundaries into one execution cycle:

```text
IR → plan → resolve capability → evaluate policy
                         ↓
                deny / approval / allow
                         ↓
                  operation engine
                         ↓
                    adapter execute
                         ↓
                 observe + evidence
                         ↓
                   reason (optional)
```

An adapter is resolved only after policy evaluation and an allowed operation is moved to `running`. Approval-required operations are persisted as pending and are never sent to an adapter during the cycle.

The reasoner is called after observation and receives runtime-owned state. Its proposal is data only and must enter the normal compiler/planner/policy path before it can cause execution.
