#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

echo 'Cusimanse — all-inclusive host installer'
./scripts/prerequisites.sh
./scripts/install-observability.sh
bash "$ROOT/scripts/install-gateways.sh"

go build -o "$ROOT/policyctl" ./cmd/policyctl
./policyctl validate
mkdir -p "$HOME/.local/bin"
ln -sf "$ROOT/scripts/token-dashboard.sh" "$HOME/.local/bin/cusimanse-token-dashboard"
chmod +x "$ROOT/scripts/token-dashboard.sh" "$ROOT/scripts/install-observability.sh" "$ROOT/scripts/install-gateways.sh"
bash -n "$ROOT/scripts"/*.sh "$ROOT/scripts/tests"/*.sh

printf '\nInstall PASS: host foundation, policyctl, observability and optional gateways prepared.\n'
echo 'Optional providers that are unavailable remain NOT_DEPLOYED/PARTIAL.'
echo 'No agent, VM or gateway server is started by this installer.'
echo 'Keep model/provider credentials outside this repository.'
printf '\nNext:\n'
echo '  ./scripts/preflight.sh'
echo '  cusimanse-token-dashboard'
echo '  ./scripts/tests/validate.sh'
echo '  ./scripts/tests/runtime.sh   # requires Lima/QEMU and a suitable host'
echo '  Select one primary agent, then provide the experiment recipe and/or its declared prompt adapter.'
