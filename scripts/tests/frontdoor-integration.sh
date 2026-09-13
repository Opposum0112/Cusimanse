#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"; cd "$ROOT"
fail(){ printf 'Frontdoor integration FAIL: %s\n' "$*" >&2; exit 1; }
for f in scripts/cusimanse-host.sh scripts/prerequisites.sh scripts/install-observability.sh scripts/configure-recipes.sh scripts/agent-preflight.sh; do [ -f "$f" ] || fail "missing $f"; bash -n "$f" || fail "shell syntax: $f"; done
command -v go >/dev/null 2>&1 || fail 'Go unavailable'
go test ./...
go build ./cmd/cusimanse-host
go build ./cmd/policyctl
command -v ruby >/dev/null 2>&1 || fail 'Ruby unavailable for YAML validation'
ruby -e 'require "yaml"; Dir["recipes/**/*.yaml"].each { |f| YAML.load_file(f); }; puts "recipe YAML PASS"'
printf '%s\n' 'Frontdoor integration PASS: Go frontdoor, scripts, policyctl and recipes'
