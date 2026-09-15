#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"
fail(){ echo "INTEGRATION FAIL: $*" >&2; exit 1; }
command -v go >/dev/null 2>&1 || fail 'go missing'
for f in schemas/cusimanse.yaml schemas/experiment.schema.json host-prep/default.yaml roles/bindings.yaml recipes/goose/session.yaml; do
  [ -s "$f" ] || fail "missing $f"
done
go test ./internal/compiler ./cmd/compile ./cmd/cusimanse || fail 'Go tests failed'
go run ./cmd/compile catalog >/dev/null || fail 'catalog failed'
for id in go-install-001 npm-install-001 npm-lifecycle-001 npm-threat-001; do
  go run ./cmd/compile validate "$id" >/dev/null || fail "validate $id"
  go run ./cmd/compile resolve "$id" >/dev/null || fail "resolve $id"
  go run ./cmd/compile host-prep "$id" >/dev/null || fail "host-prep $id"
done
if go run ./cmd/compile execute npm-install-001 >/dev/null 2>&1; then
  fail 'execute without --approved unexpectedly succeeded'
fi
echo 'INTEGRATION PASS: schema + catalog + validate/resolve/host-prep + execute gate'
