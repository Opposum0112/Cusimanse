# Cusimanse as a universal MCP server

Cusimanse exposes a harness-neutral MCP adapter so an MCP-capable AI agent can operate a governed security-research session without importing Cusimanse internals.

The intended model is:

```text
DeepSeek / Antigravity / Grok / Codex / Claude / custom agent
                              |
                              | MCP
                              v
                       Cusimanse MCP
                              |
                        OperatorPort
                              |
                              v
                   contract -> capability
                              |
                       policy / approval
                              |
                           runtime
                              |
                       compute provider
                              |
                          labprobe
                              |
                       evidence + state
```

The **agent is the operator**. MCP is the interoperability layer. Cusimanse remains the governed execution boundary.

## Project-level MCP configuration

The repository includes `.agents/mcp_config.json` for project-aware MCP-capable agent hosts that support this convention. It points at the repository's built CLI:

```json
{
  "mcpServers": {
    "cusimanse": {
      "command": "node",
      "args": ["./dist/bin/cli.js", "mcp"]
    }
  }
}
```

Build the project before starting the server:

```bash
npm install
npm run build
```

The project-level configuration intentionally starts the **generic** MCP server. A recipe is supplied later through the `create_research_session` tool instead of being hard-coded into the agent configuration.

## Start the generic MCP server

```bash
cusimanse mcp
```

For development directly from the repository, the equivalent is:

```bash
npm run mcp
```

A recipe can still be preloaded for deterministic single-experiment workflows:

```bash
cusimanse mcp recipes/examples/npm-install.yaml \
  --runtime local \
  --provider mock
```

Both modes use MCP stdio transport and are suitable for local agent hosts that launch MCP servers as child processes.

## MCP tool surface

The generic server exposes:

| Tool | Purpose |
|---|---|
| `create_research_session` | Validate a declarative recipe and create a governed session |
| `research_state` | Read current state for a session |
| `research_evidence` | Read recorded evidence references |
| `research_propose` | Submit a structured next research proposal |
| `complete_research` | Mark a session complete |

`research_propose` is the only MCP operation that requests execution. It accepts a strict `ReasoningProposal` and delegates to the harness-neutral operator interface. Execution remains behind contract, capability, policy, approval, runtime, compute, and evidence handling.

There is intentionally no `execute_shell`, unrestricted command runner, or generic process tool in the MCP surface.

## Generic agent loop

```text
1. Agent calls create_research_session(recipe).
2. Agent calls research_state(experimentId).
3. Agent reasons about the research question.
4. Agent calls research_propose(experimentId, proposal).
5. Cusimanse validates and governs the proposal.
6. Runtime executes only what is permitted.
7. Agent reads research_state / research_evidence.
8. Agent proposes the next justified operation.
9. Agent calls complete_research when the research is complete.
```

This makes the same MCP server usable by different AI operators without adding vendor-specific execution paths.

## DeepSeek Harness

DeepSeek Harness can connect an external MCP server through its MCP client plugin. Configure a stdio server entry whose command launches the built Cusimanse CLI. The conceptual configuration is:

```yaml
- id: mcp-cusimanse
  name: '@deepseek-ai/dsh-mcp-client'
  config:
    serverName: cusimanse
    transport: stdio
    command: node
    args:
      - /absolute/path/to/Cusimanse/dist/bin/cli.js
      - mcp
```

The model can then use the Cusimanse MCP tools as harness tools. Keep the research instructions explicit: use Cusimanse for all research operations, do not execute arbitrary commands directly, and treat Cusimanse policy/approval results as authoritative for execution.

## Antigravity

For an Antigravity project, use the project-level MCP configuration supported by the host and point it at:

```text
node ./dist/bin/cli.js mcp
```

After `npm run build`, the repository's `.agents/mcp_config.json` provides the corresponding project-local server declaration.

## Grok

For Grok CLI/agent environments that support local MCP servers, register the same command:

```text
node /absolute/path/to/Cusimanse/dist/bin/cli.js mcp
```

The MCP server is independent of the Grok model or agent implementation. Grok remains the operator while Cusimanse controls the research execution boundary.

## Security model

MCP configuration is **discovery/configuration**, not authorization.

The security-relevant path is:

```text
MCP tool call
     |
     v
OperatorPort
     |
     v
recipe / contract validation
     |
     v
capability resolution
     |
     v
policy + approval
     |
     v
runtime
     |
     v
isolated compute
     |
     v
labprobe + evidence
```

Do not turn a harness adapter into an unrestricted shell bridge. A model's reasoning is never authorization.

## Library integration

A custom Node.js harness can consume the same adapter directly:

```ts
import { createCusimanseMcpServer, serveCusimanseMcp } from "@cusimanse/agent-runtime/mcp";

const server = createCusimanseMcpServer(operatorPort);
await serveCusimanseMcp(operatorPort);
```

The adapter depends on the harness-neutral `OperatorPort`, not on a specific AI framework.

## Distribution roadmap

Current target: npm package + `cusimanse mcp` + stdio transport + project-level configuration.

Future targets can add Streamable HTTP and an MCP Bundle (`.mcpb`) without changing the `OperatorPort` governance contract.
