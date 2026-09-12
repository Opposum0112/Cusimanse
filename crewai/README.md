# CrewAI Adapter

CrewAI is an optional role-based multi-agent orchestration integration for Cusimanse.

## Responsibility boundary

CrewAI coordinates specialist research roles. **Goose remains the primary Cusimanse operator, executor and lifecycle orchestrator.** CrewAI must not become a competing project controller or a security boundary.

```text
Cusimanse experiment contract
            |
          Goose
 primary operator/executor
            |
        CrewAI Crew
            |
  +---------+---------+---------+
  |         |         |         |
Planner  Researcher  Forensics  Verifier
            |
       structured results
            |
          Goose
            |
   VM/cloud enforcement
            |
 evidence -> verify -> preserve -> destroy
```

## Configuration

Use `recipes/orchestration/crewai.yaml` to declare CrewAI participation. Reuse the provider-neutral roles, MCP registry, skills registry and tool definitions. Keep API keys and provider credentials outside Git.

CrewAI supports role-based agents, Crews and Flows. Cusimanse uses those capabilities only inside its declared orchestration boundary; the final execution authority remains with Goose and the Cusimanse policy/approval lifecycle.

## Safety

- Do not grant CrewAI unrestricted host access.
- Do not pass host credentials into workloads.
- Do not bypass `policyctl` or approval gates.
- Do not allow a CrewAI role to destroy evidence or VMs directly.
- Record material CrewAI role, tool, MCP, skill and approval decisions in the audit layer.
- Missing CrewAI capabilities are `NOT_DEPLOYED`, not silently substituted.

See `AGENTS.md`, `05-multi-agent-operating-model.md` and `recipes/orchestration/crewai.yaml`.
