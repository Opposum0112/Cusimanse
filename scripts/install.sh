#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

cd "$ROOT"
echo 'Cusimanse — host install (preflight + policyctl)'
./scripts/prerequisites.sh
# shellcheck disable=SC1091
source ./scripts/goose-env.sh

if ! command -v go >/dev/null 2>&1; then
  echo 'Go is required to build policyctl' >&2
  exit 1
fi

go build -o "$ROOT/policyctl" ./cmd/policyctl
./policyctl validate

echo
echo 'Install PASS (host tools + policyctl). This script does not start Goose or a VM.'
echo 'Configure the Goose model/provider outside this repository (no API keys in git).'
echo
echo 'Next:'
echo '  source ./scripts/goose-env.sh'
echo '  bash ./scripts/tests/validate-project.sh'
echo '  goose run --recipe recipes/install/project-bootstrap.yaml'
echo '  goose run --recipe recipes/goose/project.yaml --params experiment=go-install-001 --params section=project'
