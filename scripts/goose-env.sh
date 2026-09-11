#!/usr/bin/env bash
# Source this file before running Goose from a fresh shell.
# It does not install software or expose credentials.

export AI_SECURITY_LAB_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export PATH="$HOME/.local/bin:$PATH"

# Keep project-local caches/state separate from experiment evidence.
export AI_SECURITY_LAB_RUNS_DIR="${AI_SECURITY_LAB_RUNS_DIR:-$AI_SECURITY_LAB_ROOT/runs}"
export AI_SECURITY_LAB_EVIDENCE_DIR="${AI_SECURITY_LAB_EVIDENCE_DIR:-$AI_SECURITY_LAB_ROOT/evidence}"

# Goose is expected to be discoverable on PATH. Do not place API keys in this file.
if ! command -v goose >/dev/null 2>&1; then
  printf 'Goose not found on PATH. Run scripts/prerequisites.sh first.\n' >&2
  return 1 2>/dev/null || exit 1
fi

printf 'AI Security Lab environment PASS: %s\n' "$AI_SECURITY_LAB_ROOT"
