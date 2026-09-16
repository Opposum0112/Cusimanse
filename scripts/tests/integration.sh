#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"
fail(){ echo "INTEGRATION FAIL: $*" >&2; exit 1; }
command -v go >/dev/null 2>&1 || fail 'go missing'
for f in \
  schemas/cusimanse.yaml \
  experiments/npm-install-001.yaml \
  recipes/experiments/npm-install-001.yaml \
  recipes/npm-install-001/recipe.yaml \
  recipes/goose/session.yaml \
  policies/host-policy.yaml \
  cmd/cusimanse/main.go
do
  [ -s "$f" ] || fail "missing $f"
done
go test ./... >/dev/null || fail 'Go tests failed'
go run ./cmd/cusimanse capability list >/dev/null || fail 'capability list failed'
go run ./cmd/cusimanse resolve npm-install-001 >/dev/null || fail 'resolve failed'
go run ./cmd/cusimanse policy validate >/dev/null || fail 'policy validation failed'
go run ./cmd/cusimanse run npm-install-001 >/dev/null 2>&1 && fail 'run without --approved unexpectedly succeeded'
if command -v goose >/dev/null 2>&1; then
  goose recipe validate recipes/goose/session.yaml >/dev/null || fail 'Goose session recipe invalid'
  goose recipe validate recipes/npm-install-001/recipe.yaml >/dev/null || fail 'Goose npm-install recipe invalid'
  for f in recipes/subrecipes/*.yaml; do
    goose recipe validate "$f" >/dev/null || fail "invalid Goose subrecipe: $f"
  done
else
  echo 'INTEGRATION NOTE: goose not on PATH; recipe files checked for presence only'
fi
echo 'INTEGRATION PASS: schema + native CLI + policy + approval gate + Goose recipes'
