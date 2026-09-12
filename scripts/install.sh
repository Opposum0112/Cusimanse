#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$ROOT"
echo 'Cusimanse — host install (preflight + policyctl + primary adapter selection)'
./scripts/prerequisites.sh

if ! command -v go >/dev/null 2>&1; then
  echo 'Go is required to build policyctl' >&2
  exit 1
fi

go build -o "$ROOT/policyctl" ./cmd/policyctl
./policyctl validate

PRIMARY='unknown'
if [ -f "$ROOT/.cusimanse/primary-agent.yaml" ]; then
  PRIMARY=$(awk '$1 == "primary_adapter:" {print $2}' "$ROOT/.cusimanse/primary-agent.yaml")
fi

echo
echo "Install PASS (host tools + policyctl). Primary adapter: ${PRIMARY:-unknown}."
echo 'Provider credentials must remain outside this repository.'
echo
echo 'Next:'
echo '  bash ./scripts/tests/validate-project.sh'
echo '  ./scripts/agent-preflight.sh'
echo '  goose run --recipe recipes/install/project-bootstrap.yaml  # only when Goose is selected'
echo '  use the selected adapter to execute the YAML project contract'
