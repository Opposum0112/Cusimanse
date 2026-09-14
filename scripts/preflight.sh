#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"; PATH="$HOME/.local/bin:$HOME/go/bin:$PATH"
required=(git bash curl python3 ruby node npm go limactl goose jq yq rg litellm omniroute numbat)
missing=(); for t in "${required[@]}"; do command -v "$t" >/dev/null 2>&1 || missing+=("$t"); done
python3 - <<'PY'
import importlib.util,sys
m=[x for x in ('phoenix','opentelemetry') if importlib.util.find_spec(x) is None]
print('Missing Python modules: '+ ' '.join(m), file=sys.stderr) if m else None
raise SystemExit(bool(m))
PY
[ -d "$HOME/.local/share/cusimanse/aegis" ] || missing+=(aegis)
[ -f "$HOME/.config/cusimanse/litellm.yaml" ] || missing+=(litellm-config)
[ -f "$HOME/.config/cusimanse/omniroute.env" ] || missing+=(omniroute-config)
[ -f "$ROOT/recipes/lima/security-research.yaml" ] || missing+=(lima-profile)
[ -f "$ROOT/recipes/instrumentation/security-research.yaml" ] || missing+=(instrumentation-profile)
[ "${#missing[@]}" -eq 0 ] || { printf 'PREFLIGHT FAIL: %s\n' "${missing[*]}" >&2; exit 1; }
printf '%s\n' 'PREFLIGHT PASS: required host integrations and experiment profiles are installed.'
