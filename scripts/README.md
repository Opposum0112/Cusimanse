# Scripts

The public script surface is intentionally small:

| Command | Purpose |
|---|---|
| `./scripts/install.sh` | Single all-inclusive host installation front door |
| `./scripts/preflight.sh` | Single host/preflight entry point |
| `./scripts/tests/validate.sh` | Static project, recipe, Go and execute-bit validation |
| `./scripts/tests/runtime.sh` | Lima/QEMU disposable-VM runtime smoke validation |

Installation helpers (`prerequisites.sh`, `install-observability.sh`, `install-gateways.sh`) are implementation details called by `install.sh`; they are not separate project entry points.

The selected primary agent owns the research-session lifecycle and may use its native multi-agent/subagent capabilities. The recipes are the declarative source of truth. Markdown experiment prompts remain adapter conveniences for agents that need a prompt-shaped handoff; they do not replace the recipes or define a second configuration system.

Learning is opt-in and post-research. When selected, learning helpers are installed on the host/control plane, never automatically into the workload VM. Candidate skills are staged under `skills/candidate/`; only evidence-backed, replayed, independently verified and human-approved skills reach `skills/validated/`.

Runtime validation requires actual Lima/QEMU execution. Static validation does not establish runtime PASS.
