#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export PATH="$HOME/.local/bin:$HOME/go/bin:$PATH"
RECIPE="$ROOT/recipes/host/security-research.yaml"
VENV="$HOME/.local/share/cusimanse/venv"
missing=()
[ -s "$RECIPE" ] || { echo "PREFLIGHT FAIL: host recipe missing" >&2; exit 1; }
command -v yq >/dev/null 2>&1 || { echo 'PREFLIGHT FAIL: yq missing' >&2; exit 1; }
OS="$(uname -s)"
case "$OS" in
  Linux) platform=linux ;;
  Darwin) platform=macos ;;
  MINGW*|MSYS*|CYGWIN*) platform=windows_native ;;
  *) platform=windows_wsl2 ;;
esac
if [ "$platform" = windows_native ]; then
  echo 'PREFLIGHT NOT_READY: native Windows is supported for agent/repository operations; use WSL2 for Lima reference experiments.' >&2
  exit 2
fi
while IFS= read -r t; do [ -z "$t" ] || command -v "$t" >/dev/null 2>&1 || missing+=("host-command:$t"); done < <(yq -r '.common.commands[]' "$RECIPE")
while IFS= read -r t; do [ -z "$t" ] || command -v "$t" >/dev/null 2>&1 || missing+=("platform-command:$t"); done < <(yq -r '.platforms["'"$platform"'"].commands[]' "$RECIPE" 2>/dev/null)
[ -x "$VENV/bin/python" ] || missing+=(python-venv)
if [ -x "$VENV/bin/python" ]; then "$VENV/bin/python" - <<'PY' || missing+=(python-observability)
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
printf 'PREFLIGHT PASS: platform=%s host capabilities, mandatory gateways/observability and experiment profiles are ready.\n' "$platform"
