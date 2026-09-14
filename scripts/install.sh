#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$ROOT"
echo 'Cusimanse — host install (prerequisites + policyctl + observability + gateways)'
./scripts/prerequisites.sh
bash "$ROOT/scripts/install-gateways.sh"
if ! command -v go >/dev/null 2>&1; then
  echo 'Go is required to build policyctl' >&2
  exit 1
fi
go build -o "$ROOT/policyctl" ./cmd/policyctl
./policyctl validate
mkdir -p "$HOME/.local/bin"
ln -sf "$ROOT/scripts/token-dashboard.sh" "$HOME/.local/bin/cusimanse-token-dashboard"
chmod +x "$ROOT/scripts/token-dashboard.sh" "$ROOT/scripts/install-gateways.sh"
bash -n "$ROOT/scripts/token-dashboard.sh" "$ROOT/scripts/install-gateways.sh"
printf '\nInstall PASS (host prerequisites + policyctl + observability/token tooling + model gateway configuration).\n'
echo 'Session token dashboard command: cusimanse-token-dashboard'
echo 'Gateways: LiteLLM (localhost:4000) and OmniRoute (localhost:20128) when configured.'
echo 'This installer configures gateways but does not start an agent, VM, or gateway server.'
echo 'Configure model/provider credentials outside this repository (no API keys in git).'
printf '\nNext:\n'
echo '  ./scripts/preflight.sh'
echo '  cusimanse-token-dashboard'
echo '  bash ./scripts/tests/validate.sh'
echo '  bash ./scripts/tests/runtime.sh # requires CUSIMANSE_LIMA_PROFILE'
echo '  goose'
