#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PATH="$HOME/.local/bin:$HOME/go/bin:$PATH"
required=(git bash curl python3 ruby node npm go limactl goose jq yq rg litellm omniroute numbat clawmetry)
missing=()
for t in "${required[@]}"; do command -v "$t" >/dev/null 2>&1 || missing+=("$t"); done
python3 - <<'PY'
import importlib.util,sys
missing=[name for name in ('phoenix','opentelemetry') if importlib.util.find_spec(name) is None]
if missing:
    print('Missing Python modules:', ' '.join(missing), file=sys.stderr)
    raise SystemExit(1)
PY
[ -d "$HOME/.local/share/cusimanse/aegis/.git" ] || missing+=(aegis)
[ -x "$HOME/.local/bin/cusimanse-aegis" ] || missing+=(aegis-launcher)
[ -f "$HOME/.config/cusimanse/litellm.yaml" ] || missing+=(litellm-config)
[ -f "$HOME/.config/cusimanse/omniroute.env" ] || missing+=(omniroute-config)
[ -f "$HOME/.config/cusimanse/observability.env" ] || missing+=(observability-config)
[ -f "$ROOT/recipes/lima/security-research.yaml" ] || missing+=(lima-profile)
[ -f "$ROOT/recipes/instrumentation/security-research.yaml" ] || missing+=(instrumentation-profile)
[ "${#missing[@]}" -eq 0 ] || { printf 'PREFLIGHT FAIL: %s\n' "${missing[*]}" >&2; exit 1; }
printf '%s\n' 'PREFLIGHT PASS: host toolchain, mandatory gateway, observability and Lima experiment profiles are installed.'
