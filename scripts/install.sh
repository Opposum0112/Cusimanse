#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

echo 'AI Security Lab — prerequisite bootstrap'

echo

echo 'The project is executed by Goose. This script only performs a read-only preflight and then launches the installation recipe.'

command -v goose >/dev/null 2>&1 || { echo 'Goose is required. Install/configure the current Goose CLI first.' >&2; exit 2; }

cd "$ROOT"
goose run --recipe recipes/install/project-bootstrap.yaml

echo
echo 'Next: run the project recipe:'
echo '  goose run --recipe recipes/goose/project.yaml --params experiment=go-install-001 --params section=project'
