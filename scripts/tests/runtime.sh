#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"
export PATH="$HOME/.local/bin:$HOME/go/bin:$PATH"

for t in goose limactl numbat omniroute litellm clawmetry; do
  command -v "$t" >/dev/null 2>&1 || { echo "RUNTIME FAIL: $t missing"; exit 1; }
done

VENV="$HOME/.local/share/cusimanse/venv"
[ -x "$VENV/bin/python" ] || { echo 'RUNTIME FAIL: Cusimanse Python environment missing'; exit 1; }
"$VENV/bin/python" - <<'PY'
import importlib.util
for name in ('phoenix','opentelemetry','clawmetry'):
    assert importlib.util.find_spec(name), name
PY

for f in recipes/go-install-001/recipe.yaml recipes/npm-install-001/recipe.yaml recipes/subrecipes/*.yaml; do
  goose recipe validate "$f"
done
limactl validate recipes/lima/security-research.yaml

if [ "${CUSIMANSE_RUN_VM_TEST:-0}" = 1 ]; then
  name="cusimanse-runtime-$$"
  trap 'limactl delete --force "$name" >/dev/null 2>&1 || true' EXIT
  limactl start --name="$name" recipes/lima/security-research.yaml
  limactl shell "$name" -- bash -lc 'go version && node --version && npm --version && strace -V && tcpdump --version >/dev/null'
  limactl delete --force "$name"
  trap - EXIT
  echo 'RUNTIME PASS: Lima disposable VM smoke test'
else
  echo 'RUNTIME NOT_DEPLOYED: set CUSIMANSE_RUN_VM_TEST=1 to execute the disposable VM smoke test'
fi
