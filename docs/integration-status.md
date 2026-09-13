# Integrated architecture-refactor status

This branch integrates the architecture-refactor, agent-and-adapter, skills-and-mcp, and crew-orchestration workstreams.

## Integration contract

- exactly one selected primary agent owns the operator lifecycle for a case
- Goose remains the reference adapter, not a permanent dependency
- skills and MCP are declared capability/integration layers, not security boundaries
- CrewAI is optional specialist-role orchestration and cannot bypass the primary agent
- LangGraph is optional stateful execution; durable evidence remains independent
- `policyctl` remains outside the agent control plane
- Lima/QEMU disposable VMs and host/OS controls remain the workload security boundary
- all architecture and research diagrams are retained

## Validation

The repository validation suite covers shell syntax, ShellCheck, Go formatting, Go vet, recipe parsing, project contracts, policy checks and Go tests. Runtime VM acceptance still requires an actual disposable-VM experiment and preserved evidence.
