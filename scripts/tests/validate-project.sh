#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
cd "$ROOT"

echo '== Repository script contract =='
for f in scripts/prerequisites.sh scripts/agent-preflight.sh scripts/install.sh scripts/goose-env.sh scripts/cusimanse-host.sh; do test -x "$f"; done
while IFS= read -r -d '' f; do test -x "$f" || { echo "FAIL: shell script is not executable: $f" >&2; exit 1; }; done < <(find scripts -type f -name '*.sh' -print0)

echo '== Recipe validation =='
bash ./scripts/tests/validate-recipes.sh

echo '== Shell syntax =='
while IFS= read -r -d '' f; do bash -n "$f"; done < <(find . -path './.git' -prune -o -type f -name '*.sh' -print0)

echo '== Architecture/integration checks =='
for required in contracts/01-deployment-architecture.md contracts/02-system-requirements.md contracts/03-deployment-runbook.md contracts/04-security-model.md contracts/05-multi-agent-operating-model.md contracts/06-observability-and-evidence.md contracts/07-experiment-framework.md contracts/08-go-install-001.md contracts/09-operations-and-maintenance.md contracts/10-validation-and-acceptance.md contracts/11-harness-reference.md contracts/blackboard-schema.md policies/host-policy.yaml cmd/policyctl/main.go cmd/policyctl/main_test.go recipes/agents/primary-agent.yaml recipes/agents/primary-shell.yaml recipes/agents/adapter-matrix.yaml recipes/agent-selection.yaml recipes/skills/registry.yaml recipes/mcp/registry.yaml recipes/mcp/connectors.yaml recipes/orchestration/langgraph.yaml recipes/orchestration/crewai.yaml docs/architecture/cusimanse-architecture.svg docs/architecture/cusimanse-architecture.mmd docs/README.md; do test -f "$required" || { echo "FAIL: missing $required" >&2; exit 1; }; done
test -f crewai/README.md
test -f docs/images/cusimanse-mascot.svg
test -f docs/images/cusimanse-logo.svg
test -f docs/images/cusimanse-architecture.png
test -f docs/images/cusimanse-workflow.png
for adapter in antigravity claude-code codex devin enterprise-claude-code enterprise-devin goose grok-build hermes opencode pi prime-intellect; do test -f "recipes/adapters/$adapter.yaml" || { echo "FAIL: missing adapter $adapter" >&2; exit 1; }; done
grep -q 'owner: project' recipes/mcp/registry.yaml
grep -q 'owner: project' recipes/skills/registry.yaml
grep -q 'interface: adapter' recipes/tools/security-research.yaml
grep -q 'crew-orchestration' cmd/policyctl/main.go
if [ -e scripts/bin/labctl ] || [ -d scripts/labctl ]; then echo 'FAIL: retired labctl remains' >&2; exit 1; fi
for legacy in profiles.yaml state.yaml skills-registry.md 01-deployment-architecture.md 02-system-requirements.md 03-deployment-runbook.md 04-security-model.md 05-multi-agent-operating-model.md 06-observability-and-evidence.md 07-experiment-framework.md 08-go-install-001.md 09-operations-and-maintenance.md 10-validation-and-acceptance.md 11-current-antigravity-reference.md blackboard-schema.md ai-security-lab-architecture.png ai-security-lab-experiment-workflow.png; do if [ -e "$legacy" ]; then echo "FAIL: legacy root file remains: $legacy" >&2; exit 1; fi; done
if grep -Rni --exclude-dir=.git --exclude='*.sum' 'ai-security-lab' . >/tmp/cusimanse-legacy-refs.txt; then echo 'FAIL: legacy ai-security-lab references remain:' >&2; cat /tmp/cusimanse-legacy-refs.txt >&2; exit 1; fi

echo '== Go validation =='
test -z "$(gofmt -l .)"
go vet ./...
go test ./...
go build ./cmd/policyctl

echo '== Policy validation =='
./policyctl validate
./policyctl check --action credentials --audit-file /tmp/cusimanse-policy-audit.jsonl >/tmp/cusimanse-policy-check.json
./policyctl check --action host-root --audit-file /tmp/cusimanse-policy-audit.jsonl >/dev/null
./policyctl check --action crew-orchestration --audit-file /tmp/cusimanse-policy-audit.jsonl >/dev/null

echo '== Optional Python tests =='
python_tests=()
while IFS= read -r -d '' f; do python_tests+=("$f"); done < <(find scripts/tests -type f -name 'test_*.py' -print0)
if command -v python3 >/dev/null 2>&1 && [ "${#python_tests[@]}" -gt 0 ]; then PYTHONPATH=scripts python3 -m unittest discover -s scripts/tests -p 'test_*.py' -v; elif [ "${#python_tests[@]}" -eq 0 ]; then echo 'SKIP: no Python unittest modules are present'; else echo 'SKIP: python3 is not installed'; fi

echo 'PASS project integration validation'
