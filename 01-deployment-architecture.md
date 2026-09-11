# 01 — Deployment Architecture

![Architecture](docs/images/ai-security-lab-architecture.svg)

## Target state

```text
Markdown → Goose project recipe → modular recipes → disposable VM → evidence → verification
                         ↘ MCP / skills / audit
                         ↘ policyctl (policy + token dashboard)
```

## Boundaries

1. **Goose** is the only project orchestrator/operator/executor.
2. **Recipes** are the configuration and composition layer.
3. **MCP** exposes only registry-approved capabilities.
4. **Skills** provide reviewed instructions but never grant privilege.
5. **Audit** records capability decisions and execution outcomes.
6. **policyctl** configures host/security policy and serves the token dashboard only.
7. **Lima/QEMU** isolates untrusted workloads.
8. **Evidence** is preserved before destruction and independently verified.

## Design principle

> Markdown specifies. YAML configures. Goose executes. Policy constrains. Audit records. Evidence proves.
