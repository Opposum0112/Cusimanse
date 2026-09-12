#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
cd "$ROOT"
echo '== Recipe validation =='
bash ./scripts/tests/validate-recipes.sh
echo '== Shell syntax =='
while IFS= read -r -d '' f; do bash -n "$f"; done < <(find . -path './.git' -prune -o -type f -name '*.sh' -print0)
echo '== Architecture checks =='
if [ -e scripts/bin/labctl ] || [ -d scripts/labctl ]; then echo 'FAIL: retired labctl remains' >&2; exit 1; fi
for legacy in profiles.yaml state.yaml skills-registry.md; do if [ -e "$legacy" ]; then echo "FAIL: retired root file remains: $legacy" >&2; exit 1; fi; done
test -f policies/host-policy.yaml
test -f cmd/policyctl/main.go
test -f cmd/policyctl/main_test.go
test -f recipes/goose/project.yaml
test -f recipes/agents/primary-agent.yaml
test -f recipes/agents/primary-shell.yaml
test -f recipes/agents/learning-loop.yaml
test -f recipes/agents/adapter-matrix.yaml
test -f recipes/agent-selection.yaml
for adapter in goose opencode grok-build antigravity pi hermes codex prime-intellect; do test -f "recipes/adapters/$adapter.yaml"; done
test -f recipes/adapters/claude-code.yaml
test -f recipes/adapters/devin.yaml
test -f docs/agent-and-adapter-strategy.md
test -f docs/agent-shell-runbook.md
grep -q 'shell_driven: true' recipes/agents/primary-agent.yaml
grep -q 'shell_is_authoritative_operator: true' recipes/agents/primary-agent.yaml
grep -q 'primary-agent-shell' recipes/agents/primary-shell.yaml
grep -q 'owner: project' recipes/mcp/registry.yaml
grep -q 'owner: project' recipes/skills/registry.yaml
grep -q 'interface: adapter' recipes/tools/security-research.yaml
echo '== Go validation =='
test -z "$(gofmt -l .)"
go vet ./...
go test ./...
go build ./cmd/policyctl
echo '== Policy validation =='
./policyctl validate
./policyctl check --action credentials --audit-file /tmp/cusimanse-policy-audit.jsonl >/tmp/cusimanse-policy-check.json
./policyctl check --action host-root --audit-file /tmp/cusimanse-policy-audit.jsonl >/dev/null
echo '== Optional Python tests =='
python_tests=(); while IFS= read -r -d '' f; do python_tests+=("$f"); done < <(find scripts/tests -type f -name 'test_*.py' -print0)
if command -v python3 >/dev/null 2>&1 && [ "${#python_tests[@]}" -gt 0 ]; then PYTHONPATH=scripts python3 -m unittest discover -s scripts/tests -p 'test_*.py' -v; elif [ "${#python_tests[@]}" -eq 0 ]; then echo 'SKIP: no Python unittest modules are present'; else echo 'SKIP: python3 is not installed'; fi
echo 'PASS project validation'
