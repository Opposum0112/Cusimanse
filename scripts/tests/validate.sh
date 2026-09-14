#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"
status=PASS
fail(){ status=FAIL; echo "FAIL: $*" >&2; exit 1; }
partial(){ status=PARTIAL; echo "PARTIAL: $*"; }
trap 'echo "PROJECT STATUS: $status"' EXIT

# Repository-wide execute-bit and shell-syntax gate for every tracked shell script.
while IFS= read -r -d '' f; do
  [ -x "$f" ] || fail "shell script is not executable: $f"
  bash -n "$f" || fail "shell syntax: $f"
done < <(find . -type f -name '*.sh' -not -path './.git/*' -print0)
echo 'PASS: all repository .sh files have execute bit and valid shell syntax'

# Every recipe is parsed, and every contract Markdown file must be present/non-empty.
bash "$ROOT/scripts/tests/validate-recipes.sh" || fail 'recipe validation failed'
contract_count=0
while IFS= read -r -d '' f; do
  contract_count=$((contract_count + 1))
  [ -s "$f" ] || fail "empty contract/document: $f"
done < <(find "$ROOT/contracts" -type f -name '*.md' -print0)
[ "$contract_count" -gt 0 ] || fail 'no contract Markdown files found'
echo "PASS: $contract_count contract Markdown files are present and non-empty"

for required in contracts/01-deployment-architecture.md contracts/04-security-model.md contracts/05-multi-agent-operating-model.md contracts/06-observability-and-evidence.md contracts/07-experiment-framework.md contracts/08-go-install-001.md contracts/12-npm-install-001.md contracts/blackboard-schema.md policies/host-policy.yaml cmd/policyctl/main.go cmd/policyctl/main_test.go recipes/agents/primary-agent.yaml recipes/agents/primary-shell.yaml recipes/agents/adapter-matrix.yaml recipes/agent-selection.yaml recipes/skills/registry.yaml recipes/mcp/registry.yaml recipes/orchestration/langgraph.yaml recipes/orchestration/taskflow.yaml recipes/session/session-state.yaml recipes/session/learning-workflow.yaml recipes/observability/token-dashboard.yaml recipes/observability/aegis.yaml recipes/agent-monitoring/observability.yaml recipes/host/research-host.yaml recipes/tools/security-research.yaml recipes/gateways/model-gateways.yaml manifest/PACKAGE-MANIFEST.json docs/architecture/cusimanse-architecture.svg docs/architecture/cusimanse-architecture.mmd docs/README.md docs/prompts/go-install-001.md docs/prompts/npm-install-001.md; do test -f "$required" || fail "missing $required"; done

# Retired/duplicate architecture must not reappear.
[ ! -d crewai ] || fail 'retired CrewAI integration remains'
[ ! -e recipes/orchestration/crewai.yaml ] || fail 'retired CrewAI recipe remains'
[ ! -d infra ] || fail 'retired duplicate infra tree remains'
for legacy in profiles.yaml state.yaml skills-registry.md PACKAGE-MANIFEST.json; do [ ! -e "$legacy" ] || fail "legacy root file remains: $legacy"; done
legacy_project='ai-'"security-lab"; if grep -Rni --exclude-dir=.git --exclude='*.sum' "$legacy_project" . >/tmp/cusimanse-legacy-refs.txt; then cat /tmp/cusimanse-legacy-refs.txt >&2; fail 'legacy project references remain'; fi
[ ! -e docs/research-workflow.md ] || fail 'duplicate research workflow remains'
[ ! -e docs/images/cusimanse-architecture.png ] || fail 'duplicate architecture image remains'
[ ! -e docs/images/cusimanse-workflow.png ] || fail 'duplicate workflow image remains'

# Core orchestration, learning and boundary invariants.
grep -q 'native-agent-capabilities' recipes/session/session-state.yaml || fail 'native agent orchestration not declared'
grep -q 'specialist_roles: required' recipes/session/session-state.yaml || fail 'specialist role recipes are not required'
grep -q 'competing_frameworks: false' recipes/session/session-state.yaml || fail 'competing orchestrator policy missing'
grep -q 'enabled: opt_in' recipes/session/learning-workflow.yaml || fail 'learning must be opt-in'
grep -q 'candidate_library: skills/candidate/' recipes/session/learning-workflow.yaml || fail 'candidate skill library missing'
grep -q 'promotion_target: skills/validated/' recipes/session/learning-workflow.yaml || fail 'validated skill target missing'
grep -q 'human_approval_required: true' recipes/session/learning-workflow.yaml || fail 'human approval missing'
grep -q 'provider: antropos17/Aegis' recipes/observability/aegis.yaml || fail 'Aegis provider is incorrect'
grep -q 'independent-os-level-observer' recipes/observability/aegis.yaml || fail 'Aegis role is incorrect'
grep -q 'enforcement: monitor-only' recipes/observability/aegis.yaml || fail 'Aegis must remain monitor-only'
grep -q 'agent-observability' recipes/agent-monitoring/observability.yaml || fail 'agent observability recipe missing'
grep -q 'gateway_is_security_boundary: false' recipes/gateways/model-gateways.yaml || fail 'gateway boundary invariant missing'
grep -q 'public_exposure: deny' recipes/mcp/registry.yaml || fail 'MCP public exposure policy missing'
grep -q 'MCP connectors cannot expand the VM/OS security boundary' recipes/mcp/registry.yaml || fail 'MCP boundary invariant missing'
grep -q 'skills are instructions, not security boundaries' recipes/skills/registry.yaml || fail 'skill boundary invariant missing'
grep -q 'is_security_boundary: false' recipes/orchestration/taskflow.yaml || fail 'Taskflow boundary invariant missing'
grep -q 'ai_output_is_not_evidence' recipes/orchestration/langgraph.yaml || fail 'LangGraph evidence invariant missing'
grep -q 'gateways_are_not_security_boundary: true' recipes/routing/default.yaml || fail 'routing gateway boundary invariant missing'
grep -q 'required_end_state:' recipes/observability/token-dashboard.yaml || fail 'token dashboard lifecycle contract missing'
echo 'PASS: optional-layer recipes and security invariants are connected'

# Go, policyctl and policy boundary validation.
if [ -n "$(gofmt -l .)" ]; then gofmt -l .; fail 'Go formatting differences found'; fi
go vet ./... || fail 'go vet failed'
go test ./... || fail 'go test failed'
go build ./cmd/policyctl || fail 'policyctl build failed'
./policyctl validate || fail 'policy validation failed'
./policyctl check --action credentials --audit-file /tmp/cusimanse-policy-audit.jsonl >/tmp/cusimanse-policy-check.json || fail 'credentials policy check failed'
./policyctl check --action host-root --audit-file /tmp/cusimanse-policy-audit.jsonl >/dev/null || fail 'host-root policy check failed'
./policyctl check --action vm --audit-file /tmp/cusimanse-policy-audit.jsonl >/dev/null || fail 'VM policy check failed'
./policyctl check --action git-write --audit-file /tmp/cusimanse-policy-audit.jsonl >/dev/null || fail 'git-write policy check failed'
if ./policyctl check --action unknown-action --audit-file /tmp/cusimanse-policy-audit.jsonl >/dev/null 2>&1; then fail 'unknown policy action was accepted'; fi
grep -q 'credentials' /tmp/cusimanse-policy-check.json || fail 'policy decision output missing action'
grep -q '"decision":"deny"' /tmp/cusimanse-policy-check.json || fail 'credential policy did not deny'
echo 'PASS: policyctl boundary, decisions and audit path'

# Optional capability status is reported separately from core project status.
command -v numbat >/dev/null 2>&1 || partial 'Numbat is NOT_DEPLOYED'
[ -f "$HOME/.local/share/cusimanse/aegis/package.json" ] || partial 'Aegis source checkout is NOT_DEPLOYED'
python3 -c 'import importlib.util; raise SystemExit(0 if importlib.util.find_spec("phoenix") and importlib.util.find_spec("opentelemetry") else 1)' || partial 'Phoenix/OpenTelemetry is NOT_DEPLOYED'
[ -f "$ROOT/recipes/agent-monitoring/observability.yaml" ] || fail 'agent observability recipe missing'
if [ ! -f "$HOME/.config/cusimanse/litellm.yaml" ]; then partial 'LiteLLM is NOT_DEPLOYED'; fi
if [ ! -f "$HOME/.config/cusimanse/omniroute.yaml" ]; then partial 'OmniRoute is NOT_DEPLOYED'; fi
if ! command -v taskflow >/dev/null 2>&1; then partial 'Taskflow is NOT_DEPLOYED (learning helper)'; fi
if ! python3 -c 'import importlib.util; raise SystemExit(0 if importlib.util.find_spec("langgraph") else 1)' >/dev/null 2>&1; then partial 'LangGraph is NOT_DEPLOYED (learning helper)'; fi

echo 'PASS: project static integration validation'
