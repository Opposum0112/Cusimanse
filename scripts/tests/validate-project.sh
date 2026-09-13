#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
cd "$ROOT"

fail(){ echo "FAIL: $*" >&2; exit 1; }
pass(){ echo "PASS: $*"; }

# Project result semantics: PASS is complete static validation; PARTIAL means
# the project is structurally valid but a declared optional capability is absent;
# FAIL means a required project contract is broken.
project_status=PASS
mark_partial(){ project_status=PARTIAL; echo "PARTIAL: $*"; }

for f in scripts/prerequisites.sh scripts/agent-preflight.sh scripts/install.sh scripts/goose-env.sh scripts/cusimanse-host.sh; do test -x "$f" || fail "required script is not executable: $f"; done
while IFS= read -r -d '' f; do test -x "$f" || fail "shell script is not executable: $f"; done < <(find scripts -type f -name '*.sh' -print0)
bash ./scripts/tests/validate-recipes.sh
while IFS= read -r -d '' f; do bash -n "$f" || fail "shell syntax: $f"; done < <(find . -path './.git' -prune -o -type f -name '*.sh' -print0)

for required in contracts/01-deployment-architecture.md contracts/02-system-requirements.md contracts/03-deployment-runbook.md contracts/04-security-model.md contracts/05-multi-agent-operating-model.md contracts/06-observability-and-evidence.md contracts/07-experiment-framework.md contracts/08-go-install-001.md contracts/09-operations-and-maintenance.md contracts/10-validation-and-acceptance.md contracts/11-harness-reference.md contracts/12-npm-install-001.md contracts/blackboard-schema.md policies/host-policy.yaml cmd/policyctl/main.go cmd/policyctl/main_test.go recipes/agents/primary-agent.yaml recipes/agents/primary-shell.yaml recipes/agents/adapter-matrix.yaml recipes/agent-selection.yaml recipes/skills/registry.yaml recipes/mcp/registry.yaml recipes/mcp/connectors.yaml recipes/orchestration/langgraph.yaml recipes/orchestration/crewai.yaml recipes/orchestration/taskflow.yaml recipes/session/session-state.yaml recipes/session/learning-workflow.yaml recipes/observability/token-dashboard.yaml recipes/observability/agent-observability.yaml recipes/host/research-host.yaml recipes/tools/security-research.yaml manifest/PACKAGE-MANIFEST.json docs/architecture/cusimanse-architecture.svg docs/architecture/cusimanse-architecture.mmd docs/README.md docs/system-requirements.md docs/prompts/go-install-001.md docs/prompts/npm-install-001.md; do test -f "$required" || fail "missing $required"; done

test -f crewai/README.md || fail 'missing CrewAI integration documentation'
test -f docs/images/cusimanse-mascot.svg || fail 'missing mascot'
test -f docs/images/cusimanse-logo.svg || fail 'missing logo'
python3 -m json.tool manifest/PACKAGE-MANIFEST.json >/dev/null || fail 'invalid package manifest'
grep -q '^module github.com/Opposum0112/Cusimanse/packages/labprobe$' packages/labprobe/go.mod || fail 'wrong labprobe module path'
grep -q 'host_inventory_source:' recipes/tools/security-research.yaml || fail 'host inventory source missing'
grep -q 'agent-observability' recipes/agents/adapter-matrix.yaml || fail 'agent observability not connected to adapter registry'
for adapter in antigravity claude-code codex devin enterprise-claude-code enterprise-devin goose grok-build hermes opencode pi prime-intellect; do test -f "recipes/adapters/$adapter.yaml" || fail "missing adapter $adapter"; done
if [ -e scripts/bin/labctl ] || [ -d scripts/labctl ]; then fail 'retired labctl remains'; fi
if [ -d infra ]; then fail 'retired duplicate infra tree remains'; fi
for legacy in profiles.yaml state.yaml skills-registry.md PACKAGE-MANIFEST.json ai-security-lab-architecture.png ai-security-lab-experiment-workflow.png; do [ ! -e "$legacy" ] || fail "legacy root file remains: $legacy"; done
legacy_project='ai-'"security-lab"
if grep -Rni --exclude-dir=.git --exclude='*.sum' "$legacy_project" . >/tmp/cusimanse-legacy-refs.txt; then cat /tmp/cusimanse-legacy-refs.txt >&2; fail 'legacy project references remain'; fi
[ ! -e docs/research-workflow.md ] || fail 'duplicate research workflow remains'
[ ! -e docs/images/cusimanse-architecture.png ] || fail 'duplicate architecture image remains'
[ ! -e docs/images/cusimanse-workflow.png ] || fail 'duplicate workflow image remains'

grep -q 'session_id' recipes/session/session-state.yaml
grep -q 'host_profile: required' recipes/session/session-state.yaml
grep -q 'compute_profile: required' recipes/session/session-state.yaml
grep -q 'dashboard_refresh_required_at_session_end: true' recipes/session/session-state.yaml
grep -q 'independent_verification' recipes/session/learning-workflow.yaml
grep -q 'human_approval_required: true' recipes/session/learning-workflow.yaml
grep -q 'when:' recipes/session/learning-workflow.yaml
grep -q 'where:' recipes/session/learning-workflow.yaml
grep -qi 'normal host shell' docs/prompts/go-install-001.md
grep -q 'npm-install-001' docs/prompts/npm-install-001.md

gofmt -l . | grep -q '^$' || fail 'Go formatting differences found'
go vet ./... || fail 'go vet failed'
go test ./... || fail 'go test failed'
go build ./cmd/policyctl || fail 'policyctl build failed'
./policyctl validate || fail 'policy validation failed'
./policyctl check --action credentials --audit-file /tmp/cusimanse-policy-audit.jsonl >/tmp/cusimanse-policy-check.json || fail 'policy check failed'
./policyctl check --action host-root --audit-file /tmp/cusimanse-policy-audit.jsonl >/dev/null || fail 'host-root policy check failed'
./policyctl check --action crew-orchestration --audit-file /tmp/cusimanse-policy-audit.jsonl >/dev/null || fail 'crew policy check failed'

# Optional observability providers are installed by the all-inclusive installer;
# preflight records unavailable optional backends as PARTIAL rather than FAIL.
for tool in numbat aegis; do command -v "$tool" >/dev/null 2>&1 || mark_partial "$tool is NOT_DEPLOYED"; done
python3 -c 'import importlib.util; raise SystemExit(0 if importlib.util.find_spec("phoenix") and importlib.util.find_spec("opentelemetry") else 1)' || mark_partial 'Phoenix/OpenTelemetry is NOT_DEPLOYED'

pass "project integration validation"
echo "PROJECT STATUS: $project_status"
[ "$project_status" = PASS ] || [ "$project_status" = PARTIAL ]
