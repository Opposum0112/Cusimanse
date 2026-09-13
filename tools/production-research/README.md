# Production Research Tool Stack

Optional tools grouped by function:

| Group | Tools |
|---|---|
| State/orchestration | Python, LangGraph |
| Retrieval | embeddings + optional Chroma/Qdrant client |
| Data | SQLite, jq, yq, ripgrep |
| Runtime observation | OpenTelemetry Python packages |
| Binary/static analysis | file, binutils, strings, objdump, strace, lsof |
| Network analysis | tcpdump, tshark where supported |
| Detection | YARA where supported |
| Agent adapters | Prime Agent, Hermes (user/provider managed) |
| Existing runtime | Lima, QEMU, Goose |

The prerequisite script installs safe/common host utilities when `CUSIMANSE_INSTALL_PRODUCTION_PROFILE=1` is set. Heavy language/model tooling and agent provider configuration remain explicit so the host does not unexpectedly download large runtimes or consume credentials.

The tool list is a capability inventory, not a statement that every tool is required for every experiment. Missing optional capability is `NOT_DEPLOYED`.
