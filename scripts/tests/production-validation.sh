#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

fail() { printf 'PRODUCTION VALIDATION FAIL: %s\n' "$*" >&2; exit 1; }
pass() { printf 'PRODUCTION VALIDATION PASS: %s\n' "$*"; }

for f in \
  docs/production-architecture.md \
  docs/runtime-architecture.md \
  recipes/campaigns/security-research-learning.yaml \
  recipes/workflows/security-research-taskflow.yaml \
  recipes/orchestration/langgraph.yaml \
  recipes/agents/self-learning-primary.yaml \
  recipes/learning/skill-promotion.yaml \
  recipes/learning/skill-registry.yaml \
  recipes/mcp/production-research.yaml \
  skills/validated/evidence-pe-import-analysis/SKILL.md \
  tools/production-research/README.md; do
  [ -f "$f" ] || fail "missing $f"
done
pass "production architecture files present"

bash -n scripts/prerequisites.sh
bash -n scripts/tests/production-validation.sh
pass "shell syntax"

if command -v python3 >/dev/null 2>&1; then
  python3 - <<'PY'
import pathlib
try:
    import yaml
except ImportError:
    print('PyYAML unavailable: YAML semantic parse is NOT_DEPLOYED')
    raise SystemExit(0)
files = [
 'recipes/campaigns/security-research-learning.yaml',
 'recipes/workflows/security-research-taskflow.yaml',
 'recipes/orchestration/langgraph.yaml',
 'recipes/agents/self-learning-primary.yaml',
 'recipes/learning/skill-promotion.yaml',
 'recipes/learning/skill-registry.yaml',
 'recipes/mcp/production-research.yaml',
]
for f in files:
    data = yaml.safe_load(pathlib.Path(f).read_text())
    assert isinstance(data, dict), f
print('YAML semantic parse PASS')
PY
else
  fail "python3 is required for production validation"
fi

if command -v go >/dev/null 2>&1; then
  gofmt -l . | grep -q . && fail "Go formatting differences found"
  go vet ./...
  pass "Go format and vet"
else
  fail "Go is required for integration validation"
fi

./scripts/tests/validate-project.sh
[ -f recipes/goose/project.yaml ] || fail 'existing Goose recipe missing'
[ -f experiments/go-install-001.yaml ] || [ -d experiments/go-install-001 ] || fail 'existing reference experiment missing'
grep -q 'policyctl.*outside\|outside.*policyctl' docs/production-architecture.md || fail 'policyctl boundary not documented'
grep -q 'Lima/QEMU' docs/production-architecture.md || fail 'VM boundary not documented'
grep -q 'require_independent_verification: true' recipes/learning/skill-promotion.yaml || fail 'verification gate missing'
pass "existing architecture compatibility assertions"

printf '%s\n' 'Production architecture integration validation PASS'
printf '%s\n' 'Runtime VM execution is not claimed by this static test.'
