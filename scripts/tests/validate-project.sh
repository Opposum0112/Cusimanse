#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
cd "$ROOT"
./scripts/tests/validate-recipes.sh
while IFS= read -r -d '' f; do bash -n "$f"; done < <(find . -path './.git' -prune -o -type f -name '*.sh' -print0)
if [ -e scripts/bin/labctl ] || [ -d scripts/labctl ]; then echo 'FAIL: retired labctl remains' >&2; exit 1; fi
test -f policies/host-policy.yaml
test -f cmd/policyctl/main.go
gofmt -d cmd/policyctl/main.go
go test ./...
go build ./cmd/policyctl
./policyctl validate
./policyctl check --action credentials --audit-file /tmp/ai-security-lab-policy-audit.jsonl >/tmp/ai-security-lab-policy-check.json
./policyctl check --action host-root --audit-file /tmp/ai-security-lab-policy-audit.jsonl >/dev/null
if command -v python3 >/dev/null 2>&1; then PYTHONPATH=scripts python3 -m unittest discover -s scripts/tests -p 'test_*.py' -v; fi
echo 'PASS project validation'
