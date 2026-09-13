#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ADAPTER="${CUSIMANSE_PRIMARY_ADAPTER:-}"
OBS_STATUS="${CUSIMANSE_OBSERVABILITY_STATUS:-}"
AGENT_STATUS="${CUSIMANSE_AGENT_STATUS:-}"
python3 - "$ROOT" "$ADAPTER" "$OBS_STATUS" "$AGENT_STATUS" <<'PY'
from pathlib import Path
import sys
root, adapter, obs, agent = map(str, sys.argv[1:])
# Deliberately performs narrow key replacement only; recipes remain reviewable YAML.
def patch(path, replacements):
    p=Path(path)
    if not p.exists(): return
    s=p.read_text()
    for key,val in replacements.items():
        import re
        pattern=rf'(?m)^{re.escape(key)}:\s*.*$'
        if re.search(pattern,s): s=re.sub(pattern,f'{key}: {val}',s,count=1)
        else: s += f'\n{key}: {val}\n'
    p.write_text(s)
if adapter:
    patch(Path(root)/'recipes/agents/self-learning-primary.yaml', {'selected_adapter': adapter})
if obs:
    for name in ('numbat','aegis'):
        patch(Path(root)/f'recipes/observability/{name}.yaml', {'status': obs})
if agent:
    patch(Path(root)/'recipes/agents/self-learning-primary.yaml', {'installation_status': agent})
PY
