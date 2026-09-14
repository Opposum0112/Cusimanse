#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"
export PATH="$HOME/.local/bin:$HOME/go/bin:$PATH"
fail(){ echo "VALIDATION FAIL: $*" >&2; exit 1; }

# Search only for references that are forbidden in the current Goose-centered branch.
forbidden='ai-security-lab|CrewAI|crewai|infra/|ARCHITECTURE-REFACTOR|scripts/cusimanse-host|scripts/agent-preflight|scripts/configure-recipes|scripts/goose-env|recipes/adapters|recipes/gateways|recipes/routing|recipes/orchestration'
if grep -RInE "$forbidden" README.md .goosehints contracts recipes docs scripts 2>/dev/null; then
  fail 'stale or retired architecture references remain'
fi

for f in scripts/*.sh scripts/tests/*.sh; do
  [ -x "$f" ] || fail "not executable: $f"
  bash -n "$f" || fail "syntax error: $f"
done

for f in contracts/*.md \
  recipes/go-install-001/recipe.yaml \
  recipes/npm-install-001/recipe.yaml \
  recipes/subrecipes/*.yaml \
  recipes/lima/security-research.yaml \
  recipes/instrumentation/security-research.yaml \
  recipes/host/security-research.yaml \
  recipes/gateway/mandatory.yaml \
  recipes/observability/mandatory.yaml \
  recipes/session/session-state.yaml \
  recipes/session/learning-workflow.yaml; do
  [ -s "$f" ] || fail "missing/empty: $f"
done

python3 - <<'PY'
from pathlib import Path
import yaml
for p in Path('recipes').glob('**/*.yaml'):
    d = yaml.safe_load(p.read_text())
    assert isinstance(d, dict), p
    if p.name == 'recipe.yaml':
        assert d.get('version') and d.get('title') and d.get('description'), p
        assert d.get('instructions') or d.get('prompt'), p
print('YAML PASS')
PY

command -v goose >/dev/null 2>&1 || fail 'goose is required for validation'
for f in recipes/go-install-001/recipe.yaml recipes/npm-install-001/recipe.yaml recipes/subrecipes/*.yaml; do
  goose recipe validate "$f"
done

command -v limactl >/dev/null 2>&1 || fail 'limactl is required for validation'
limactl validate recipes/lima/security-research.yaml

grep -Fq 'required: true' recipes/gateway/mandatory.yaml || fail 'gateway not mandatory'
grep -Fq 'required: true' recipes/observability/mandatory.yaml || fail 'observability not mandatory'
grep -Fq 'learning.enabled = true' README.md || fail 'learning enablement missing'
grep -Fq 'session-state.yaml' README.md || fail 'session state documentation missing'
grep -Fq 'Container Use may be added' README.md || fail 'optional Container Use statement missing'
grep -Fq 'scripts/tools.sh list' README.md || fail 'host tool access documentation missing'
grep -Fq 'recipe-defined workload' README.md || fail 'recipe-driven workload documentation missing'

printf '%s\n' 'VALIDATION PASS'
