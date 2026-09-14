#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"; cd "$ROOT"
fail(){ echo "VALIDATION FAIL: $*" >&2; exit 1; }
forbidden='ai-security-lab|CrewAI|crewai|policyctl|infra/|blackboard/|recipes/adapters|recipes/agent-selection|recipes/orchestration|recipes/session|recipes/workloads|recipes/reporting|recipes/gateways|recipes/routing|scripts/prerequisites|scripts/agent-preflight|scripts/install-gateways|scripts/install-observability|scripts/token-dashboard|scripts/verify-run|ARCHITECTURE-REFACTOR|goose-docs.ai'
if grep -RInE "$forbidden" --exclude-dir=.git --exclude='*.svg' . >/tmp/cusimanse-stale.txt 2>/dev/null; then cat /tmp/cusimanse-stale.txt; fail 'stale or duplicate references remain'; fi
for f in scripts/*.sh scripts/tests/*.sh; do [ -x "$f" ] || fail "not executable: $f"; bash -n "$f" || fail "syntax error: $f"; done
for f in contracts/*.md recipes/go-install-001/recipe.yaml recipes/npm-install-001/recipe.yaml recipes/subrecipes/*.yaml recipes/lima/security-research.yaml recipes/instrumentation/security-research.yaml recipes/host/security-research.yaml recipes/gateway/mandatory.yaml recipes/observability/mandatory.yaml; do [ -s "$f" ] || fail "missing/empty: $f"; done
python3 - <<'PY'
from pathlib import Path
import yaml
files=list(Path('recipes').glob('**/*.yaml'))
for p in files:
 d=yaml.safe_load(p.read_text())
 if p.name.endswith('recipe.yaml') or 'subrecipes' in p.parts:
  assert d.get('version') and d.get('title') and d.get('description')
  assert d.get('instructions') or d.get('prompt')
print(f'YAML PASS: {len(files)} recipe/profile files parsed')
PY
if command -v goose >/dev/null 2>&1; then for f in recipes/go-install-001/recipe.yaml recipes/npm-install-001/recipe.yaml recipes/subrecipes/*.yaml; do goose recipe validate "$f"; done; else fail 'goose is required for validation'; fi
command -v limactl >/dev/null 2>&1 || fail 'limactl missing'
grep -Fq 'required: true' recipes/gateway/mandatory.yaml || fail 'gateway not mandatory'
grep -Fq 'required: true' recipes/observability/mandatory.yaml || fail 'observability not mandatory'
grep -Fq 'Lima' README.md || fail 'README missing Lima workflow'
grep -Fq 'Container Use is optional' README.md || fail 'README missing optional Container Use statement'
printf '%s\n' 'VALIDATION PASS'
