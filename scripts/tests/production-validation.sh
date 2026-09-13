#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"; cd "$ROOT"
fail(){ printf 'VALIDATION FAIL: %s\n' "$*" >&2; exit 1; }
pass(){ printf 'VALIDATION PASS: %s\n' "$*"; }
for f in docs/production-architecture.md docs/system-requirements.md recipes/campaigns/security-research-learning.yaml recipes/workflows/security-research-taskflow.yaml recipes/orchestration/langgraph.yaml recipes/agents/self-learning-primary.yaml recipes/learning/skill-promotion.yaml recipes/learning/skill-registry.yaml recipes/mcp/production-research.yaml skills/validated/evidence-pe-import-analysis/SKILL.md tools/production-research/README.md; do [ -f "$f" ] || fail "missing $f"; done
[ -f cmd/cusimanse-host/main.go ] || fail "missing Go host setup package"
for script in scripts/*.sh scripts/tests/*.sh; do [ -f "$script" ] || continue; [ -x "$script" ] || fail "missing execute bit: $script"; done
pass "architecture files and mandatory execute bits"
bash -n scripts/prerequisites.sh; bash -n scripts/tests/production-validation.sh
command -v python3 >/dev/null || fail "python3 missing"
command -v go >/dev/null || fail "go missing"
gofmt -l . | grep -q . && fail "Go formatting differences found" || true
go vet ./...
pass "shell and Go validation"
python3 - <<'PY'
import pathlib
try:
 import yaml
except ImportError: raise SystemExit('PyYAML unavailable')
for f in ['recipes/campaigns/security-research-learning.yaml','recipes/workflows/security-research-taskflow.yaml','recipes/orchestration/langgraph.yaml','recipes/agents/self-learning-primary.yaml','recipes/learning/skill-promotion.yaml','recipes/learning/skill-registry.yaml','recipes/mcp/production-research.yaml']:
 assert isinstance(yaml.safe_load(pathlib.Path(f).read_text()),dict), f
PY
pass "YAML semantic parse"
bash ./scripts/tests/validate-project.sh
[ -d experiments/go-install-001 ] || fail 'reference experiment missing'
grep -qi 'policyctl.*outside\|outside.*policyctl' docs/production-architecture.md || fail 'policy boundary missing'
grep -qi 'Lima/QEMU' docs/production-architecture.md || fail 'VM boundary missing'
grep -q 'require_independent_verification: true' recipes/learning/skill-promotion.yaml || fail 'verification gate missing'
grep -q 'OpenTelemetry' docs/system-requirements.md || fail 'OpenTelemetry requirements missing'
grep -q 'Phoenix' docs/system-requirements.md || fail 'Phoenix integration missing'
grep -q 'Numbat' docs/system-requirements.md || fail 'Numbat integration missing'
grep -q 'Aegis' docs/system-requirements.md || fail 'Aegis integration missing'
pass "host configuration, observability and security-boundary assertions"
printf '%s\n' 'Architecture validation PASS'; printf '%s\n' 'Runtime VM execution is not claimed by this static test.'
