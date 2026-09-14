#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"
export PATH="$HOME/.local/bin:$HOME/go/bin:$PATH"
fail(){ echo "VALIDATION FAIL: $*" >&2; exit 1; }
for f in scripts/*.sh scripts/tests/*.sh; do
  if [ "$f" != scripts/session.sh ]; then [ -x "$f" ] || fail "not executable: $f"; fi
  bash -n "$f" || fail "syntax error: $f"
done
for f in contracts/*.md recipes/go-install-001/recipe.yaml recipes/npm-install-001/recipe.yaml recipes/npm-lifecycle-001/recipe.yaml recipes/experiments/*.yaml recipes/subrecipes/*.yaml recipes/lima/security-research.yaml recipes/instrumentation/security-research.yaml recipes/host/security-research.yaml recipes/gateway/mandatory.yaml recipes/observability/mandatory.yaml recipes/session/session-state.yaml recipes/session/learning-workflow.yaml recipes/agents/adapter-matrix.yaml recipes/agents/adapter-installation.yaml recipes/agents/goose-orchestration.yaml recipes/skills/registry.yaml recipes/mcp/registry.yaml; do [ -s "$f" ] || fail "missing/empty: $f"; done
for f in prompts/README.md prompts/experiments/*.md; do [ -s "$f" ] || fail "missing/empty prompt reference: $f"; done
for d in skills/candidate skills/validated; do [ -d "$d" ] || fail "missing skill staging directory: $d"; done
[ -x scripts/run-experiment.sh ] || fail 'experiment runner must be executable'
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
    d=yaml.safe_load(p.read_text())
    for key in ('title','description','instructions'):
        assert isinstance(d.get(key), str) and d[key].strip(), f'{p}: {key}'
    assert set(d) <= allowed, f'{p}: non-Goose top-level fields: {set(d)-allowed}'
for p in Path('recipes/experiments').glob('*.yaml'):
    d=yaml.safe_load(p.read_text()); assert d.get('kind') == 'cusimanse-experiment', p
    assert d.get('contract') and d.get('workload'), p
print('YAML/JSON/GOOSE SCHEMA PASS')
PY
if command -v goose >/dev/null 2>&1; then for f in recipes/*/recipe.yaml; do goose recipe validate "$f"; done; else echo 'Goose CLI not installed: Goose runtime validation deferred'; fi
python3 - <<'PY'
from pathlib import Path
import yaml
m=yaml.safe_load(Path('recipes/agents/adapter-matrix.yaml').read_text())
assert m['reference']['agent'] == 'goose'
for name in ('opencode','hermes','antigravity','pi'): assert name in m['adapters']
print('AGENT MATRIX PASS')
PY
grep -Fq 'required: true' recipes/gateway/mandatory.yaml || fail 'gateway is not mandatory'
grep -Fq 'required: true' recipes/observability/mandatory.yaml || fail 'observability is not mandatory'
grep -Fq 'default: false' recipes/session/learning-workflow.yaml || fail 'learning must default off'
grep -Fq 'session_key: learning.enabled' recipes/session/learning-workflow.yaml || fail 'learning enable key missing'
grep -Fq 'how_to_enable:' recipes/session/learning-workflow.yaml || fail 'learning instructions missing'
grep -Fq 'configure_from_recipe: true' recipes/host/security-research.yaml || fail 'host recipe install declaration missing'
grep -Fq 'recipes/agents/adapter-matrix.yaml' recipes/session/session-state.yaml || fail 'adapter matrix linkage missing'
grep -Fq 'anthropic-cybersecurity-skills' recipes/skills/registry.yaml || fail 'external skill registry missing'
grep -Fq 'public_exposure: deny' recipes/mcp/registry.yaml || fail 'MCP exposure policy missing'
grep -Fq 'role_definitions: .agents/agents/' recipes/agents/goose-orchestration.yaml || fail 'Goose role definitions missing'
grep -Fq 'native-agent-subagents-and-skills' recipes/agents/goose-orchestration.yaml || fail 'Goose native orchestration missing'
grep -Fq 'optional_adapters:' recipes/agents/adapter-installation.yaml || fail 'adapter installer options missing'
grep -Fq 'CUSIMANSE_INSTALL_ADAPTERS' recipes/agents/adapter-installation.yaml || fail 'adapter noninteractive install missing'
printf '%s\n' 'VALIDATION PASS'
