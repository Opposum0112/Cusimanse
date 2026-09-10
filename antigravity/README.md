# Antigravity CLI Integration

Antigravity CLI is a first-class harness in this lab.

Official installation:

```bash
curl -fsSL https://antigravity.google/cli/install.sh | bash
```

Launch:

```bash
agy
```

Useful capabilities for this project include:
- custom agents
- background subagents
- MCP
- plugins
- skills
- hooks
- terminal sandbox
- permissions

Use Antigravity as a harness, not as the sole security boundary.

Recommended workspace extension layout:

```text
.agents/
├── agents/
├── skills/
└── mcp_config.json
```

Keep project-specific configuration in Git. Keep credentials out of Git.
