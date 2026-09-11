#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

cd "$ROOT"
echo 'AI Security Lab — prerequisite bootstrap'
./scripts/prerequisites.sh
# shellcheck disable=SC1091
source ./scripts/goose-env.sh

echo
echo 'Prerequisite PASS'
echo 'Next: run the Goose project recipe:'
echo '  goose run --recipe recipes/goose/project.yaml --params experiment=go-install-001 --params section=project'
