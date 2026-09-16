# Lab: npm-install-day0

Workload example for researchers. Question: what does a pinned `npm install` do on disposable compute?

## Files in this folder

| File | Required | Purpose |
|---|---|---|
| `contract.yaml` | yes | Frozen experiment law |
| `policy.yaml` | yes | allow / deny per capability |
| `fixtures/package.json` | yes | Subject under test (pinned) |
| this README | yes | How to run this lab |

Do **not** add `run.sh`, API keys, or extra operator tools.

## Roles and skills (from `skills/registry.yaml`)

| Role | Skill | Capability to propose |
|---|---|---|
| supply-chain-researcher | npm-install-research | `workload.npm.install` |
| threat-researcher / detection-engineer | network-observation | `network.observe` |
| forensics-analyst | process-observation | `evidence.collect` |

Any harness may play those roles. The harness only fills `{ intent, capability, parameters, complete }`.

## Run

1. Compile and serve the operator ABI from a host that imports `@cusimanse/agent-runtime` (`createLab({ gateway: true })` or `CARGateway`).
2. Copy `fixtures/package.json` into the VM `/workspace` via the `workload.npm.install` adapter (not via an agent shell).
3. Point your operator at `http://127.0.0.1:8787`.
4. Propose, in order: install → network.observe → evidence.collect → `complete: true` (or `vm.destroy` after evidence exists).
5. Off-allowlist names (e.g. `host.shell`) must return `not_in_contract_allowlist`.
