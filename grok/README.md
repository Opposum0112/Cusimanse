# Grok Adapter

Grok can be used as an agent adapter for the AI Security Research Lab. The adapter consumes the same provider-neutral Markdown contracts and YAML recipes used by the other supported agents.

## Responsibilities

The Grok adapter may provide:

- planning and reasoning;
- execution of approved project steps;
- interaction with declared tools and MCP capabilities;
- evidence collection and analysis;
- reporting through the project's reporting contracts.

It must preserve the project's policy, audit, evidence and independent-verification semantics.

## Architecture

```text
Grok adapter
     |
     +--> Markdown contracts
     +--> recipes/*
     +--> MCP registry
     +--> skills registry
     +--> policyctl for host/security policy decisions
     |
     +--> disposable Lima/QEMU execution
     |
     +--> evidence -> reduction -> forensics -> verification
```

Grok is an adapter, **not a project controller and not a security boundary**. Do not add Grok-specific experiment semantics to shared recipes. If a capability is unavailable, record `NOT_DEPLOYED` rather than silently substituting another capability.

## Configuration

Keep Grok-specific credentials and local configuration outside Git. Reuse the provider-neutral project roles under `.agents/` and the registries under `recipes/` rather than maintaining a second copy of the project workflow.

## Security

The same controls apply to Grok as to every other adapter:

- no host credentials passed to workloads;
- no unrestricted host filesystem mounts;
- privileged/destructive actions require approval;
- policy decisions come from `policyctl`;
- evidence is preserved before VM destruction;
- important findings receive independent verification.

See the root `README.md`, `AGENTS.md`, `SECURITY.md` and `AI-DISCLAIMER.md` for the project-wide contracts.
