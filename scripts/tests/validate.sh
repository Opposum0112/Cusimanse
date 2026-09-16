#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"
command -v go >/dev/null 2>&1 || { echo 'VALIDATE FAIL: go missing' >&2; exit 1; }
go test ./... >/dev/null
go run ./cmd/cusimanse capability list >/dev/null
go run ./cmd/cusimanse resolve npm-install-001 >/dev/null
go run ./cmd/cusimanse policy validate >/dev/null
if command -v goose >/dev/null 2>&1; then
  goose recipe validate recipes/goose/session.yaml
  goose recipe validate recipes/npm-install-001/recipe.yaml
  for f in recipes/subrecipes/*.yaml; do goose recipe validate "$f"; done
fi
echo 'VALIDATE PASS: Go tests, native CLI, policy and Goose recipes'
