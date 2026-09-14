#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"
export PATH="$HOME/.local/bin:$HOME/go/bin:$PATH"
fail(){ echo "RUNTIME FAIL: $*" >&2; exit 1; }

# CI proves the control plane without requiring host-installed observability services.
# Those services are integration dependencies, not prerequisites for schema/lifecycle tests.
for t in goose yq; do
  command -v "$t" >/dev/null 2>&1 || fail "$t missing"
done

python3 - <<'PY'
from pathlib import Path
import yaml

for p in [Path('recipes/go-install-001/recipe.yaml'), Path('recipes/npm-install-001/recipe.yaml')]:
    d=yaml.safe_load(p.read_text())
    assert d['title'] and d['description'] and (d.get('instructions') or d.get('prompt')), p
    assert set(d) <= {'version','title','description','instructions','prompt','activities','extensions','parameters','response','retry','settings','sub_recipes'}, p

for p in Path('recipes/experiments').glob('*.yaml'):
    d=yaml.safe_load(p.read_text())
    assert d.get('kind') == 'cusimanse-experiment', p
    assert d.get('compute',{}).get('recipe') and d.get('instrumentation',{}).get('recipe'), p
    assert d.get('workload',{}).get('execution') == 'disposable-lima-vm', p

inst=yaml.safe_load(Path('recipes/instrumentation/security-research.yaml').read_text())
assert inst['rules']['collectors_start_before_workload'] is True
assert inst['rules']['raw_evidence_immutable'] is True
host=yaml.safe_load(Path('recipes/host/security-research.yaml').read_text())
assert set(host['platforms']) >= {'linux','macos','windows_wsl2','windows_native'}
print('RUNTIME STRUCTURE PASS')
PY

for f in recipes/go-install-001/recipe.yaml recipes/npm-install-001/recipe.yaml recipes/subrecipes/*.yaml; do
  goose recipe validate "$f"
done

# Exercise the real session state machine, including rejection of an invalid transition.
sid="runtime-contract-$$"
trap 'rm -rf "runs/$sid"' EXIT
./scripts/session.sh create go-install-001 goose "$sid" >/dev/null
./scripts/session.sh checkpoint "$sid" VALIDATED
./scripts/session.sh checkpoint "$sid" PREFLIGHTED
if ./scripts/session.sh checkpoint "$sid" COMPLETE >/dev/null 2>&1; then
  fail 'invalid lifecycle transition was accepted'
fi
./scripts/session.sh checkpoint "$sid" PLANNED
./scripts/session.sh checkpoint "$sid" AWAITING_APPROVAL
./scripts/session.sh checkpoint "$sid" APPROVED
./scripts/session.sh checkpoint "$sid" PARTIAL
./scripts/session.sh verify-layout "$sid"
./scripts/session.sh hash "$sid"

grep -q '"state":"PARTIAL"' "runs/$sid/evidence/audit/events.jsonl" || fail 'lifecycle audit event missing'
test -s "runs/$sid/evidence/audit/manifest.sha256" || fail 'evidence manifest missing'
test -s "runs/$sid/provenance/manifest.sha256" || fail 'provenance manifest missing'
echo 'RUNTIME PASS: recipe validation and lifecycle/evidence functional tests'

if [ "${CUSIMANSE_RUN_VM_TEST:-0}" = 1 ]; then
  command -v limactl >/dev/null 2>&1 || fail 'limactl missing for VM test'
  name="cusimanse-runtime-$$"
  trap 'limactl delete --force "$name" >/dev/null 2>&1 || true; rm -rf "runs/$sid"' EXIT
  limactl validate recipes/lima/security-research.yaml
  limactl start --name="$name" recipes/lima/security-research.yaml
  limactl shell "$name" -- bash -lc 'go version && node --version && npm --version && strace -V && tcpdump --version >/dev/null'
  limactl delete --force "$name"
  trap 'rm -rf "runs/$sid"' EXIT
  echo 'RUNTIME PASS: Lima disposable VM smoke test'
fi
