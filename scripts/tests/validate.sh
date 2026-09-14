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

for f in contracts/*.md recipes/*/recipe.yaml recipes/experiments/*.yaml recipes/subrecipes/*.yaml recipes/lima/security-research.yaml recipes/instrumentation/security-research.yaml recipes/host/security-research.yaml recipes/gateway/mandatory.yaml recipes/observability/mandatory.yaml recipes/session/session-state.yaml recipes/session/learning-workflow.yaml recipes/agents/adapter-matrix.yaml recipes/agents/adapter-installation.yaml recipes/agents/goose-orchestration.yaml recipes/skills/registry.yaml recipes/mcp/registry.yaml; do
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
for p in Path('recipes/subrecipes').glob('*.yaml'):
    d=yaml.safe_load(p.read_text()); assert d.get('title') and d.get('description'), p
    assert d.get('instructions') or d.get('prompt'), p
m=yaml.safe_load(Path('recipes/agents/adapter-matrix.yaml').read_text())
assert m['reference']['agent'] == 'goose'
assert all(x in m['adapters'] for x in ('opencode','hermes','antigravity','pi'))
s=yaml.safe_load(Path('recipes/session/session-state.yaml').read_text())
assert s['agent']['selected_primary_agent'] == 'required'
assert s['agent']['reference_primary_agent'] == 'goose'
assert s['execution']['researcher_runs_workload_commands'] is False
assert s['orchestration']['specialist_roles'] == 'required'
assert s['learning']['default'] is False
h=yaml.safe_load(Path('recipes/host/security-research.yaml').read_text())
assert 'common' in h and 'platforms' in h and 'guest' in h
assert h['installation']['configure_from_recipe'] is True
for f in ['recipes/gateway/mandatory.yaml','recipes/observability/mandatory.yaml']:
    assert yaml.safe_load(Path(f).read_text()).get('required') is True, f
skill=yaml.safe_load(Path('recipes/skills/registry.yaml').read_text())
assert 'anthropic-cybersecurity-skills' in {x['id'] for x in skill.get('external', [])}
mcp=yaml.safe_load(Path('recipes/mcp/registry.yaml').read_text())
assert mcp['policy']['public_exposure'] == 'deny'
learning=yaml.safe_load(Path('recipes/session/learning-workflow.yaml').read_text())
assert learning['enabled']['default'] is False
assert learning['enabled']['session_key'] == 'learning.enabled'
assert learning['promotion_rules']['human_approval_required'] is True
print('STRUCTURAL YAML/JSON/POLICY PASS')
PY

python3 - <<'PY'
from pathlib import Path
patterns=('ai-security-lab','CrewAI','crewai','scripts/cusimanse-host.sh','scripts/agent-preflight.sh','scripts/configure-recipes.sh','scripts/goose-env.sh','turn0search','turn1search','turn2search')
roots=[Path('contracts'),Path('recipes'),Path('docs'),Path('scripts'),Path('.goosehints')]
for root in roots:
    paths=[root] if root.is_file() else root.rglob('*')
    for p in paths:
        if not p.is_file() or p.as_posix() == 'scripts/tests/validate.sh': continue
        text=p.read_text(errors='ignore')
        for pat in patterns: assert pat not in text, f'{p}: retired reference {pat}'
print('RETIRED REFERENCE SCAN PASS')
PY

if command -v goose >/dev/null 2>&1; then
  for f in recipes/*/recipe.yaml; do goose recipe validate "$f"; done
else
  echo 'Goose CLI not installed: Goose CLI validation deferred'
fi
printf '%s\n' 'VALIDATION PASS'
