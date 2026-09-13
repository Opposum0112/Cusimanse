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
for required in policies/host-policy.yaml cmd/policyctl/main.go cmd/policyctl/main_test.go recipes/agents/primary-agent.yaml recipes/agents/primary-shell.yaml recipes/agents/adapter-matrix.yaml recipes/agent-selection.yaml recipes/skills/registry.yaml recipes/mcp/registry.yaml recipes/mcp/connectors.yaml recipes/orchestration/langgraph.yaml recipes/orchestration/crewai.yaml docs/architecture/cusimanse-architecture.svg docs/ARCHITECTURE-REFACTOR-RUNBOOK.md; do test -f "$required" || { echo "FAIL: missing $required" >&2; exit 1; }; done
test -f crewai/README.md
test -f docs/images/cusimanse-crew-orchestration.svg
for adapter in antigravity claude-code codex devin enterprise-claude-code enterprise-devin goose grok-build hermes opencode pi prime-intellect; do test -f "recipes/adapters/$adapter.yaml" || { echo "FAIL: missing adapter $adapter" >&2; exit 1; }; done
grep -q 'owner: project' recipes/mcp/registry.yaml
grep -q 'owner: project' recipes/skills/registry.yaml
grep -q 'interface: adapter' recipes/tools/security-research.yaml
grep -q 'crew-orchestration' cmd/policyctl/main.go
if [ -e scripts/bin/labctl ] || [ -d scripts/labctl ]; then echo 'FAIL: retired labctl remains' >&2; exit 1; fi
for legacy in profiles.yaml state.yaml skills-registry.md; do if [ -e "$legacy" ]; then echo "FAIL: retired root file remains: $legacy" >&2; exit 1; fi; done

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
