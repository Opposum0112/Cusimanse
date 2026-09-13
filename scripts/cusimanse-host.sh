#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
set +e
go run ./cmd/cusimanse-host "$@"
rc=$?
set -e
bash "$ROOT/scripts/enrich-host-state.sh" || true
exit "$rc"
