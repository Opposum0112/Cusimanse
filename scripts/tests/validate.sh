#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"
export PATH="$HOME/.local/bin:$HOME/go/bin:$PATH"
fail(){ echo "VALIDATION FAIL: $*" >&2; exit 1; }

while IFS= read -r -d '' f; do
  [ -x "$f" ] || fail "not executable: $f"
  bash -n "$f" || fail "syntax error: $f"
done < <(find scripts -type f -name '*.sh' -print0)

for f in contracts/*.md recipes/*/recipe.yaml recipes/experiments/*.yaml recipes/subrecipes/*.yaml recipes/lima/security-research.yaml recipes/instrumentation/security-research.yaml recipes/host/security-research.yaml recipes/gateway/mandatory.yaml recipes/observability/mandatory.yaml recipes/session/session-state.yaml recipes/session/learning-workflow.yaml recipes/agents/adapter-matrix.yaml recipes/agents/adapter-validation.yaml recipes/agents/adapter-installation.yaml recipes/agents/goose-orchestration.yaml recipes/skills/registry.yaml recipes/mcp/registry.yaml; do
  [ -s "$f" ] || fail "missing/empty: $f"
done
for f in prompts/README.md prompts/experiments/*.md; do [ -s "$f" ] || fail "missing/empty prompt reference: $f"; done
for d in skills/candidate skills/validated; do [ -d "$d" ] || fail "missing skill staging directory: $d"; done
[ -s docs/architecture/cusimanse-architecture.svg ] || fail 'architecture SVG missing'
[ -s docs/architecture/cusimanse-architecture.mmd ] || fail 'architecture Mermaid source missing'
[ -s docs/images/cusimanse-mascot-logo.svg ] || fail 'mascot/logo image missing'
[ -s manifest/PACKAGE-MANIFEST.json ] || fail 'package manifest missing'

python3 - <<'PY'
from pathlib import Path
import json, yaml
json.loads(Path('manifest/PACKAGE-MANIFEST.json').read_text())
allowed={'version','title','description','instructions','prompt','activities','extensions','parameters','response','retry','settings','sub_recipes'}
for p in Path('recipes').glob('*/recipe.yaml'):
    d=yaml.safe_load(p.read_text()); assert isinstance(d,dict), p
    assert isinstance(d.get('title'),str) and d['title'].strip(), f'{p}: title'
    assert isinstance(d.get('description'),str) and d['description'].strip(), f'{p}: description'
    assert d.get('instructions') or d.get('prompt'), f'{p}: instructions/prompt required'
    assert set(d) <= allowed, f'{p}: non-Goose fields: {set(d)-allowed}'
for p in Path('recipes/experiments').glob('*.yaml'):
    d=yaml.safe_load(p.read_text()); assert d.get('kind') == 'cusimanse-experiment', p
    assert d.get('contract') and d.get('workload'), p
    assert d.get('compute') and d.get('instrumentation') and d.get('session'), p
    assert d['workload'].get('execution') == 'disposable-lima-vm', p

lifecycle=yaml.safe_load(Path('recipes/experiments/npm-lifecycle-001.yaml').read_text())
coverage=set(lifecycle['threat_model']['coverage'])
assert {'package-lifecycle-process','filesystem-behavior','localhost-network-behavior'} <= coverage
assert 'local-fixture-only' in lifecycle['threat_model']['limitations']

inst=yaml.safe_load(Path('recipes/instrumentation/security-research.yaml').read_text())
assert inst['rules']['collectors_start_before_workload'] is True
assert inst['rules']['raw_evidence_immutable'] is True
host=yaml.safe_load(Path('recipes/host/security-research.yaml').read_text())
assert set(host['platforms']) >= {'linux','macos','windows_wsl2','windows_native'}
assert host['installation']['remote_install_policy'] == 'download-to-temp-then-execute'
adapters=yaml.safe_load(Path('recipes/agents/adapter-validation.yaml').read_text())
for name in ('opencode','hermes','antigravity','pi'):
    assert adapters['status'][name]['state'] == 'NOT_DEPLOYED', name
assert adapters['rules']['cli_presence_is_not_pass'] is True
assert adapters['rules']['pass_requires_actual_disposable_vm_execution'] is True
print('STRUCTURAL YAML/JSON/POLICY PASS')
PY

python3 - <<'PY'
from pathlib import Path
patterns=('ai-security-lab','CrewAI','crewai','scripts/cusimanse-host.sh','scripts/agent-preflight.sh','scripts/configure-recipes.sh','scripts/goose-env.sh','turn0search','turn1search','turn2search','turn3search')
roots=[Path('contracts'),Path('recipes'),Path('docs'),Path('scripts'),Path('.goosehints')]
for root in roots:
    paths=[root] if root.is_file() else root.rglob('*')
    for p in paths:
        if not p.is_file() or p.as_posix() == 'scripts/tests/validate.sh': continue
        text=p.read_text(errors='ignore')
        for pat in patterns: assert pat not in text, f'{p}: retired/reference artifact {pat}'
print('RETIRED REFERENCE SCAN PASS')
PY

if command -v goose >/dev/null 2>&1; then
  for f in recipes/*/recipe.yaml; do goose recipe validate "$f"; done
else
  echo 'Goose CLI not installed: Goose CLI validation deferred'
fi
printf '%s\n' 'VALIDATION PASS'
