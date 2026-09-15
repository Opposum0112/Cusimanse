# Policy and approval

CAR uses default-deny policy evaluation. A matched rule may allow an operation, require explicit approval, or deny it. Policy evaluation never executes an operation.

Approval is a first-class state: `pending`, `granted`, or `denied`. A request cannot be silently converted from `approval-required` to `denied`; execution remains blocked until an explicit grant exists.

```text
Resolved Capability
       ↓
 Policy Evaluation
   ┌───┼──────────┐
 allow approval  deny
   │      ↓        │
   │   pending     │
   │      ↓        │
   │    grant      │
   └──────┴────────→ Operation Engine
```

The LLM does not modify policy or issue approval. Approval records identify the experiment, intent, capability, operation kind, decision time, and decision-maker.
