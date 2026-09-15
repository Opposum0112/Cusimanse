# Host toolchain, gateways and observability

This document covers host bootstrap, model gateways and observability. Guest instrumentation has a single dedicated guide: `docs/INSTRUMENTATION.md`. The authoritative inventories are `recipes/host/security-research.yaml`, `recipes/gateway/mandatory.yaml`, `recipes/observability/mandatory.yaml` and `recipes/instrumentation/security-research.yaml`.

## 1. Install

From the repository root:

```bash
./scripts/install.sh
export PATH="$HOME/.local/bin:$HOME/go/bin:$PATH"
cusimanse doctor
cusimanse validate
cusimanse preflight
```

The installer supports the declared Linux, macOS and WSL2 paths. It installs the host control-plane prerequisites, Goose, model gateways, observability dependencies and Lima/QEMU where applicable. Guest instrumentation is provisioned by the disposable Linux VM recipe rather than treated as a host execution dependency.

## 2. Host command inventory

The project-wide inventory is `manifest/TOOL-INVENTORY.yaml`; host requirements are declared in `recipes/host/security-research.yaml`.

| Area | Commands | Purpose / access |
|---|---|---|
| Control/bootstrap | `git`, `bash`, `curl`, `python3`, `go` | repository, bootstrap and native Go control plane |
| Data/config | `jq`, `yq`, `rg` | configuration/data inspection and installer parsing |
| Workload tooling | `node`, `npm` | package-research tooling; reference workloads execute in the guest |
| Agent | `goose` | primary native agent operator |
| VM provider | `limactl`, QEMU | disposable compute; lifecycle normally controlled by Go runtime/agent |

Check host availability:

```bash
cusimanse tools list
cusimanse tools versions
cusimanse tools config
cusimanse tools path
```

## 3. Model gateways

The mandatory gateway recipe is `recipes/gateway/mandatory.yaml`.

| Component | Access | Data / UI | Installation / configuration |
|---|---|---|---|
| LiteLLM | `127.0.0.1:4000`; agent-facing OpenAI-compatible endpoint | model requests, routing and normalization; no public UI/listener | installed into the Cusimanse Python environment by `scripts/install.sh`; `~/.config/cusimanse/litellm.yaml` |
| OmniRoute | `127.0.0.1:20128`; upstream for LiteLLM | provider routing/fallback; localhost API | installed by the installer with pinned npm package; `~/.config/cusimanse/omniroute.env` |

Flow:

```text
agent / Goose → LiteLLM :4000 → OmniRoute :20128 → configured provider
```

Secrets are environment-only. Gateways are **not security boundaries**; policy and the Go capability API remain authoritative. Inspect configuration locations without printing secrets:

```bash
cusimanse tools config
```

## 4. Observability

The mandatory observer recipe is `recipes/observability/mandatory.yaml`.

| Observer | Access | Data / UI |
|---|---|---|
| Numbat | `cusimanse tools numbat` | `~/.numbat/cusimanse.ndjson` |
| Phoenix | browser | `http://127.0.0.1:6006` |
| OpenTelemetry | OTLP/HTTP | `http://127.0.0.1:4318` |
| ClawMetry | browser | `http://127.0.0.1:8900` |
| Aegis | `cusimanse observability status` | `~/.local/share/cusimanse/aegis/` |

```bash
cusimanse observability status
cusimanse observability phoenix
cusimanse observability clawmetry
cusimanse observability report <session-id>
```

Observers record or expose telemetry; they never authorize execution.

## 5. Lima / QEMU boundary

Lima/QEMU is the disposable-compute provider. The normal researcher interface is the Go runtime:

```bash
cusimanse resolve npm-threat-001
cusimanse --approved run npm-threat-001 <session-id>
```

For diagnostics only, the underlying commands are:

```bash
limactl validate recipes/lima/security-research.yaml
limactl start --name=cusimanse-smoke recipes/lima/security-research.yaml
limactl shell cusimanse-smoke -- bash -lc 'go version && node --version && npm --version'
limactl delete --force cusimanse-smoke
```

Do not add arbitrary mounts, credentials or external destinations. The Go runtime/agent owns the normal provision → configure → instrument → execute → collect → verify → preserve → destroy lifecycle.

Guest instrumentation and its access model are documented only in `docs/INSTRUMENTATION.md` to avoid duplicate inventories.

## 6. Configuration locations

```text
~/.config/cusimanse/
├── litellm.yaml
├── omniroute.env
├── observability.env
└── goose.env

~/.local/share/cusimanse/
├── aegis/
└── venv/

~/.numbat/cusimanse.ndjson
```

Repository configuration remains authoritative for experiments and security controls.

## 7. Native Go commands

```bash
cusimanse validate
cusimanse preflight
cusimanse policy validate
cusimanse resolve npm-threat-001
cusimanse capability list
cusimanse test
cusimanse integration-test
cusimanse doctor
```

Native Go validation, preflight and policy are authoritative. Shell is limited to bootstrap, compatibility and unavoidable external-tool access.

## 8. Session and evidence access

```bash
cusimanse session create npm-threat-001 goose <session-id>
cusimanse session status <session-id>
cusimanse session checkpoint <session-id> VALIDATED
cusimanse session hash <session-id>
cusimanse session verify-layout <session-id>
```

Evidence must be hashed and preserved before disposable compute is destroyed.
