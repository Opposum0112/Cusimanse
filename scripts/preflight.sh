#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export PATH="$HOME/.local/bin:$HOME/go/bin:$PATH"
VENV="$HOME/.local/share/cusimanse/venv"
RECIPE="$ROOT/recipes/host/security-research.yaml"
missing=()

[ -s "$RECIPE" ] || { echo "PREFLIGHT FAIL: host recipe missing: $RECIPE" >&2; exit 1; }
command -v yq >/dev/null 2>&1 || { echo 'PREFLIGHT FAIL: yq missing; cannot read host recipe' >&2; exit 1; }

while IFS= read -r t; do
  command -v "$t" >/dev/null 2>&1 || missing+=("command:$t")
done < <(yq -r '.required.commands[]' "$RECIPE")

[ -x "$VENV/bin/python" ] || missing+=(python-venv)
if [ -x "$VENV/bin/python" ]; then
  "$VENV/bin/python" - <<'PY' || missing+=(python-observability)
import importlib.util
for name in ('phoenix','opentelemetry','clawmetry'):
    assert importlib.util.find_spec(name), name
PY
fi

[ -d "$HOME/.local/share/cusimanse/aegis/.git" ] || missing+=(aegis)
[ -x "$HOME/.local/bin/cusimanse-aegis" ] || missing+=(aegis-launcher)
[ -f "$HOME/.config/cusimanse/litellm.yaml" ] || missing+=(litellm-config)
[ -f "$HOME/.config/cusimanse/omniroute.env" ] || missing+=(omniroute-config)
[ -f "$HOME/.config/cusimanse/observability.env" ] || missing+=(observability-config)
[ -f "$HOME/.config/cusimanse/goose.env" ] || missing+=(goose-config)
[ -f "$ROOT/recipes/lima/security-research.yaml" ] || missing+=(lima-profile)
[ -f "$ROOT/recipes/instrumentation/security-research.yaml" ] || missing+=(instrumentation-profile)
[ -f "$ROOT/recipes/session/session-state.yaml" ] || missing+=(session-state)

[ "${#missing[@]}" -eq 0 ] || { printf 'PREFLIGHT FAIL: %s\n' "${missing[*]}" >&2; exit 1; }
printf '%s\n' 'PREFLIGHT PASS: host toolchain, gateways, observability, session state and Lima experiment profiles are installed/configured.'
