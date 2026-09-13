#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ADAPTER="${CUSIMANSE_PRIMARY_ADAPTER:-}"
python3 - "$ROOT" "$ADAPTER" <<'PY'
from pathlib import Path
import re,sys,shutil
root,adapter=sys.argv[1:]
def patch(path,replacements):
    p=Path(path)
    if not p.exists(): return
    s=p.read_text()
    for key,val in replacements.items():
        pat=rf'(?m)^{re.escape(key)}:\s*.*$'
        line=f'{key}: {val}'
        s=re.sub(pat,line,s,count=1) if re.search(pat,s) else s+f'\n{line}\n'
    p.write_text(s)
if adapter and adapter != 'none':
    installed=bool(shutil.which(adapter))
    patch(Path(root)/'recipes/agents/self-learning-primary.yaml', {'selected_adapter':adapter,'installation_status':'DEPLOYED' if installed else 'NOT_DEPLOYED'})
for name in ('numbat','aegis'):
    installed=bool(shutil.which(name))
    patch(Path(root)/f'recipes/observability/{name}.yaml', {'status':'DEPLOYED' if installed else 'NOT_DEPLOYED'})
PY
