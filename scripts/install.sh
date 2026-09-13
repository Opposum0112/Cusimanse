#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$ROOT"
echo 'Cusimanse — host install (preflight + policyctl + agent observability)'
./scripts/prerequisites.sh
# shellcheck disable=SC1091
source ./scripts/goose-env.sh
if [ -f "$HOME/.config/cusimanse/token-optimization.env" ]; then
  # shellcheck disable=SC1091
  source "$HOME/.config/cusimanse/token-optimization.env"
fi
if ! command -v go >/dev/null 2>&1; then
  echo 'Go is required to build policyctl' >&2
  exit 1
fi
go build -o "$ROOT/policyctl" ./cmd/policyctl
./policyctl validate
mkdir -p "$HOME/.local/bin"
ln -sf "$ROOT/scripts/token-dashboard.sh" "$HOME/.local/bin/cusimanse-token-dashboard"
chmod +x "$ROOT/scripts/token-dashboard.sh"
./scripts/token-dashboard.sh --help >/dev/null 2>&1 || true
printf '\nInstall PASS (host tools + policyctl + governance/token tooling).\n'
echo 'Session token dashboard command: cusimanse-token-dashboard'
echo 'Dashboard is localhost-only by default and reads the session usage ledger configured at installation time.'
echo 'This installer does not start an agent, VM, or dashboard server.'
echo 'Configure model/provider credentials outside this repository (no API keys in git).'
printf '\nNext:\n'
echo '  source ./scripts/goose-env.sh'
echo '  source "$HOME/.config/cusimanse/token-optimization.env"'
echo '  cusimanse-token-dashboard'
echo '  bash ./scripts/tests/validate-project.sh'
echo '  goose run --recipe recipes/install/project-bootstrap.yaml'
echo '  goose run --recipe recipes/goose/project.yaml --params experiment=go-install-001 --params section=project'
