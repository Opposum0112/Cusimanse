# CrewAI Adapter

CrewAI is an optional role-based multi-agent orchestration layer for Cusimanse.

## Responsibility boundary

CrewAI coordinates specialist research roles. The **selected primary Cusimanse agent remains the project operator, executor and lifecycle authority**. CrewAI must not become a competing project controller or a security boundary.

```text
Cusimanse experiment contract
            |
   Selected primary agent
   operator / executor
            |
        CrewAI Crew
            |
 Planner · Researcher · Runtime Analyst · Forensics · Verifier
            |
       structured role results
            |
   Selected primary agent
            |
 policy + approval + Lima/QEMU enforcement
            |
 evidence -> verify -> preserve -> destroy
```

## Configuration

Use `recipes/orchestration/crewai.yaml` to declare optional participation. Reuse the provider-neutral roles, MCP registry, skills registry and tool definitions. Keep API keys and provider credentials outside Git.

CrewAI is a role layer, not the durable evidence store, VM boundary or host policy controller. LangGraph remains the optional stateful execution layer and the evidence/case store remains independent.

## Safety

- Do not grant CrewAI unrestricted host access.
- Do not pass host credentials into workloads.
- Do not bypass `policyctl` or approval gates.
- Do not allow a CrewAI role to destroy evidence or VMs directly.
- Record material CrewAI role, tool, MCP, skill and approval decisions in the audit layer.
- Missing CrewAI capabilities are `NOT_DEPLOYED`, not silently substituted.
