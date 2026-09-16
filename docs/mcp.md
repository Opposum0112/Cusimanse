# Cusimanse as an MCP server

Cusimanse exposes a harness-neutral MCP adapter so an MCP-capable AI agent can operate a research session without importing Cusimanse internals.

## Architecture

```text
Any MCP-capable agent / harness
            |
            | MCP
            v
     Cusimanse MCP server
            |
            | OperatorPort
            v
     CAR / CARGateway
            |
            v
 contract -> capability -> policy/approval -> runtime -> compute -> evidence
```

MCP is the **interoperability boundary**, not the security boundary. The MCP server never exposes arbitrary shell execution.

## Install

For a published package:

```bash
npm install -g @cusimanse/agent-runtime
```

Or use it from a checked-out repository:

```bash
npm install
npm run build
```

## Start an MCP server

Bind an MCP server to a validated recipe:

```bash
cusimanse mcp recipes/examples/npm-install.yaml \
  --runtime local \
  --provider mock
```

The process uses MCP stdio transport, which is suitable for local agent hosts that launch MCP servers as child processes.

The npm script equivalent is:

```bash
npm run mcp -- recipes/examples/npm-install.yaml --runtime local --provider mock
```

## Exposed MCP tools

| Tool | Purpose |
|---|---|
| `research_state` | Read the current research state |
| `research_evidence` | Read recorded evidence references |
| `research_propose` | Submit a structured research proposal |

`research_propose` is the only MCP operation that can request execution. It accepts a `ReasoningProposal` and delegates to `OperatorPort.submitProposal()`. Cusimanse then performs its normal contract, capability, policy, approval, runtime, compute, and evidence flow.

There is intentionally no `execute_shell`, unrestricted command runner, or generic process tool in the MCP surface.

## Harness configuration pattern

A generic MCP-capable harness can launch the server as a stdio process. Conceptually:

```json
{
  "mcpServers": {
    "cusimanse": {
      "command": "cusimanse",
      "args": [
        "mcp",
        "/absolute/path/to/recipe.yaml",
        "--runtime",
        "local",
        "--provider",
        "mock"
      ]
    }
  }
}
```

Exact configuration syntax varies by harness. The stable integration contract is MCP stdio; the harness does not need to know the TypeScript implementation.

## Agent loop

```text
1. Agent reads research_state.
2. Agent reasons about the research question.
3. Agent calls research_propose with the next declared capability.
4. Cusimanse validates and governs the proposal.
5. Runtime executes only what is permitted.
6. Agent reads research_state / research_evidence.
7. Agent continues or finishes.
```

This preserves the intended division of responsibility:

- **Agent/harness:** reasoning and research direction.
- **MCP:** interoperability.
- **Cusimanse:** governed execution and state/evidence lifecycle.
- **Runtime:** execution orchestration.
- **Compute provider:** execution environment.
- **labprobe:** guest instrumentation.

## Library integration

A custom Node.js harness can consume the same adapter directly:

```ts
import { createCusimanseMcpServer, serveCusimanseMcp } from "@cusimanse/agent-runtime/mcp";

const server = createCusimanseMcpServer(operatorPort);
await serveCusimanseMcp(operatorPort);
```

The `operatorPort` is deliberately typed as the harness-neutral `OperatorPort`, so MCP does not depend on `CARGateway` or a particular agent framework.

## Distribution roadmap

The first distribution target is an npm package with a `cusimanse mcp` CLI and stdio transport. A later distribution can add an MCP Bundle (`.mcpb`) or a separately hosted Streamable HTTP deployment without changing the `OperatorPort` contract.
