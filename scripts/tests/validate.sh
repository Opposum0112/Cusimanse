#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"
status=PASS
fail(){ status=FAIL; echo "FAIL: $*" >&2; exit 1; }
partial(){ status=PARTIAL; echo "PARTIAL: $*"; }
trap 'echo "PROJECT STATUS: $status"' EXIT

# Repository-wide execute-bit and shell-syntax gate.
while IFS= read -r -d '' f; do [ -x "$f" ] || fail "shell script is not executable: $f"; bash -n "$f" || fail "shell syntax: $f"; done < <(find scripts -type f -name '*.sh' -print0)

bash "$ROOT/scripts/tests/validate-recipes.sh" || fail 'recipe validation failed'
for required in contracts/01-deployment-architecture.md contracts/04-security-model.md contracts/05-multi-agent-operating-model.md contracts/06-observability-and-evidence.md contracts/07-experiment-framework.md contracts/08-go-install-001.md contracts/12-npm-install-001.md contracts/blackboard-schema.md policies/host-policy.yaml cmd/policyctl/main.go cmd/policyctl/main_test.go recipes/agents/primary-agent.yaml recipes/agents/primary-shell.yaml recipes/agents/adapter-matrix.yaml recipes/agent-selection.yaml recipes/skills/registry.yaml recipes/mcp/registry.yaml recipes/orchestration/langgraph.yaml recipes/orchestration/taskflow.yaml recipes/session/session-state.yaml recipes/session/learning-workflow.yaml recipes/observability/token-dashboard.yaml recipes/observability/aegis.yaml recipes/agent-monitoring/observability.yaml recipes/host/research-host.yaml recipes/tools/security-research.yaml manifest/PACKAGE-MANIFEST.json docs/architecture/cusimanse-architecture.svg docs/architecture/cusimanse-architecture.mmd docs/README.md docs/prompts/go-install-001.md docs/prompts/npm-install-001.md; do test -f "$required" || fail "missing $required"; done
[ -d crewai ] && fail 'retired CrewAI integration remains'
[ -e recipes/orchestration/crewai.yaml ] && fail 'retired CrewAI recipe remains'
[ -d infra ] && fail 'retired duplicate infra tree remains'
for legacy in profiles.yaml state.yaml skills-registry.md PACKAGE-MANIFEST.json; do [ ! -e "$legacy" ] || fail "legacy root file remains: $legacy"; done
legacy_project='ai-'"security-lab"; if grep -Rni --exclude-dir=.git --exclude='*.sum' "$legacy_project" . >/tmp/cusimanse-legacy-refs.txt; then cat /tmp/cusimanse-legacy-refs.txt >&2; fail 'legacy project references remain'; fi
[ ! -e docs/research-workflow.md ] || fail 'duplicate research workflow remains'
[ ! -e docs/images/cusimanse-architecture.png ] || fail 'duplicate architecture image remains'
[ ! -e docs/images/cusimanse-workflow.png ] || fail 'duplicate workflow image remains'

grep -q 'native-agent-capabilities' recipes/session/session-state.yaml || fail 'native agent orchestration not declared'
grep -q 'competing_frameworks: false' recipes/session/session-state.yaml || fail 'competing orchestrator policy missing'
grep -q 'enabled: opt_in' recipes/session/learning-workflow.yaml || fail 'learning must be opt-in'
grep -q 'candidate_library: skills/candidate/' recipes/session/learning-workflow.yaml || fail 'candidate skill library missing'
grep -q 'promotion_target: skills/validated/' recipes/session/learning-workflow.yaml || fail 'validated skill target missing'
grep -q 'human_approval_required: true' recipes/session/learning-workflow.yaml || fail 'human approval missing'
grep -q 'provider: antropos17/Aegis' recipes/observability/aegis.yaml || fail 'Aegis provider is incorrect'
grep -q 'independent-os-level-observer' recipes/observability/aegis.yaml || fail 'Aegis role is incorrect'
grep -q 'agent-observability' recipes/agent-monitoring/observability.yaml || fail 'agent observability recipe missing'

gofmt -l . | grep -q '^$' || fail 'Go formatting differences found'
go vet ./... || fail 'go vet failed'
go test ./... || fail 'go test failed'
go build ./cmd/policyctl || fail 'policyctl build failed'
./policyctl validate || fail 'policy validation failed'
./policyctl check --action credentials --audit-file /tmp/cusimanse-policy-audit.jsonl >/tmp/cusimanse-policy-check.json || fail 'credentials policy check failed'
./policyctl check --action host-root --audit-file /tmp/cusimanse-policy-audit.jsonl >/dev/null || fail 'host-root policy check failed'
./policyctl check --action vm --audit-file /tmp/cusimanse-policy-audit.jsonl >/dev/null || fail 'VM policy check failed'

command -v numbat >/dev/null 2>&1 || partial 'Numbat is NOT_DEPLOYED'
[ -f "$HOME/.local/share/cusimanse/aegis/package.json" ] || partial 'Aegis source checkout is NOT_DEPLOYED'
python3 -c 'import importlib.util; raise SystemExit(0 if importlib.util.find_spec("phoenix") and importlib.util.find_spec("opentelemetry") else 1)' || partial 'Phoenix/OpenTelemetry is NOT_DEPLOYED'

echo 'PASS: project static integration validation'
