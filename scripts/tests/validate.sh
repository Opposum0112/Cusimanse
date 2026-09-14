#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"
export PATH="$HOME/.local/bin:$HOME/go/bin:$PATH"
fail(){ echo "VALIDATION FAIL: $*" >&2; exit 1; }
command -v go >/dev/null 2>&1 || fail 'Go is required for the capability runtime'
command -v yq >/dev/null 2>&1 || fail 'yq is required to read recipes'
for f in scripts/install.sh scripts/preflight.sh scripts/tools.sh scripts/session.sh scripts/run-experiment.sh scripts/policyctl scripts/observability.sh scripts/learningctl scripts/tests/validate.sh scripts/tests/runtime.sh scripts/tests/integration.sh; do [ -x "$f" ] || fail "script is not executable: $f"; done
for f in contracts/*.md recipes/*/recipe.yaml recipes/experiments/*.yaml recipes/profiles/registry.yaml recipes/profiles/host/*.yaml recipes/profiles/workload/*.yaml recipes/subrecipes/*.yaml recipes/lima/security-research.yaml recipes/instrumentation/security-research.yaml recipes/host/security-research.yaml recipes/gateway/mandatory.yaml recipes/observability/mandatory.yaml recipes/session/session-state.yaml recipes/session/learning-workflow.yaml recipes/agents/*.yaml recipes/skills/*.yaml recipes/skills/registry.yaml recipes/agents/role-skill-registry.json recipes/agents/role-skill-bindings.yaml recipes/mcp/registry.yaml policies/*.yaml; do [ -s "$f" ] || fail "missing/empty: $f"; done
[ -s manifest/PACKAGE-MANIFEST.json ] || fail 'package manifest missing'
[ -s docs/architecture/cusimanse-architecture.mmd ] || fail 'architecture source missing'
[ -s docs/architecture/cusimanse-architecture.svg ] || fail 'architecture image missing'
! grep -R -n 'filecite' README.md docs .agents recipes scripts 2>/dev/null || fail 'ChatGPT filecite markers leaked into repository text'
./scripts/policyctl validate >/dev/null || fail 'policy validation failed'
go test ./...
python3 - <<'PY'
from pathlib import Path
import json,yaml
json.loads(Path('manifest/PACKAGE-MANIFEST.json').read_text())
rs=json.loads(Path('recipes/agents/role-skill-registry.json').read_text())
skills={x['name']:x for x in rs['skills']}; roles={x['name']:x for x in rs['roles']}
assert skills and roles
for n,s in skills.items():
 p=Path('recipes/skills')/(n+'.yaml'); d=yaml.safe_load(p.read_text()); assert d['name']==n and d['description']==s['description'] and d['capabilities']==s['capabilities'] and d['required_tools']==s['required_tools'],p
for n,r in roles.items():
 p=Path('.agents/agents')/(n+'.yaml'); d=yaml.safe_load(p.read_text()); assert d['name']==n and d['description']==r['description'] and d['skills']==r['skills'] and d['capabilities']==r['capabilities'],p
bind=yaml.safe_load(Path('recipes/agents/role-skill-bindings.yaml').read_text());assert bind['source']=='recipes/agents/role-skill-registry.json'
for n,r in roles.items(): assert bind['roles'][n]==r['skills'],n
allowed={'version','title','description','instructions','prompt','activities','extensions','parameters','response','retry','settings','sub_recipes'}
for p in Path('recipes').glob('*/recipe.yaml'):
 d=yaml.safe_load(p.read_text());assert isinstance(d,dict) and d.get('title') and d.get('description') and (d.get('instructions') or d.get('prompt')),p;assert set(d)<=allowed,f'{p}: non-Goose fields {set(d)-allowed}'
reg=yaml.safe_load(Path('recipes/profiles/registry.yaml').read_text());assert reg['rules']['deterministic'] is True and reg['rules']['agent_may_create_profiles'] is False
assert len(reg['hosts'])==len(set(reg['hosts'])) and len(reg['workloads'])==len(set(reg['workloads']))
valid={'go-install','npm-install','npm-lifecycle','npm-threat'}
for p in Path('recipes/experiments').glob('*.yaml'):
 d=yaml.safe_load(p.read_text());assert d.get('kind')=='cusimanse-experiment',p;r=d.get('requirements',{});assert r.get('execution')=='disposable' and r.get('os')=='linux' and r.get('workload') and r.get('instrumentation'),p;assert not {'profiles','host','compute','instrumentation','workload'}&set(d),f'{p}: duplicated infrastructure fields remain'
for p in [Path(x) for x in reg['hosts']+reg['workloads']]:
 d=yaml.safe_load(p.read_text());assert d.get('kind') in {'host-profile','workload-profile'},p
 if d['kind']=='host-profile': assert d['execution']['agent_may_generate_provisioning'] is False and d['execution']['agent_may_generate_instrumentation'] is False
 else: assert d['runtime_handler'] in valid and d['agent_may_modify'] is False and d.get('requirements',{}).get('os')=='linux'
learning=yaml.safe_load(Path('recipes/session/learning-workflow.yaml').read_text());assert learning['enabled']['default'] is False and learning['promotion_rules']['human_approval_required'] is True
obs=yaml.safe_load(Path('recipes/observability/mandatory.yaml').read_text());assert obs['research_reporting']['role']=='report-generator'
print('STRUCTURAL + GO CAPABILITY + ROLE/SKILL + OBSERVABILITY + LEARNING + POLICY PASS')
PY
for f in recipes/*/recipe.yaml recipes/subrecipes/*.yaml; do goose recipe validate "$f"; done
printf '%s\n' 'VALIDATION PASS'
