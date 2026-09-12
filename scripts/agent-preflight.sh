#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
SELECTED_FILE="$ROOT/.cusimanse/primary-agent.yaml"
[ -f "$SELECTED_FILE" ] || { echo 'Agent preflight FAIL: primary adapter is not selected' >&2; exit 1; }
PRIMARY=$(awk '$1 == "primary_adapter:" {print $2}' "$SELECTED_FILE")
[ -n "$PRIMARY" ] || { echo 'Agent preflight FAIL: primary_adapter missing' >&2; exit 1; }

have() { command -v "$1" >/dev/null 2>&1; }
case "$PRIMARY" in
  goose) CMD=goose; have goose || exit 1 ;;
  opencode) CMD=opencode; have opencode || exit 1 ;;
  pi) CMD=pi; have pi || exit 1 ;;
  hermes) CMD=hermes; have hermes || { echo 'Agent preflight: hermes NOT_DEPLOYED'; exit 0; } ;;
  codex) CMD=codex; have codex || exit 1 ;;
  prime-intellect) CMD=prime-agent; have prime-agent || { echo 'Agent preflight: prime-intellect NOT_DEPLOYED'; exit 0; } ;;
  grok-build) CMD=grok; have grok || { echo 'Agent preflight: grok-build NOT_DEPLOYED'; exit 0; } ;;
  antigravity) CMD=agy; have agy || { echo 'Agent preflight: antigravity NOT_DEPLOYED'; exit 0; } ;;
  claude-code) CMD=claude; have claude || { echo 'Agent preflight: claude-code NOT_DEPLOYED'; exit 0; } ;;
  devin) CMD=provider-managed; echo 'Agent preflight: devin provider-managed'; exit 0 ;;
  *) echo "Agent preflight FAIL: unknown adapter $PRIMARY" >&2; exit 1;;
esac

test -f "$ROOT/recipes/agents/primary-agent.yaml"
test -f "$ROOT/recipes/agents/primary-shell.yaml"
test -f "$ROOT/recipes/agents/learning-loop.yaml"
test -f "$ROOT/recipes/agent-selection.yaml"
test -f "$ROOT/recipes/adapters/$PRIMARY.yaml" 2>/dev/null || [ "$PRIMARY" = devin ]
test -f "$ROOT/policies/host-policy.yaml"
test -f "$ROOT/docs/agent-shell-runbook.md"
command -v limactl >/dev/null 2>&1
printf 'Agent preflight PASS: %s shell=%s contracts available\n' "$PRIMARY" "$CMD"
