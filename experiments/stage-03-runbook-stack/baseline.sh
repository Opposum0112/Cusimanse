#!/usr/bin/env bash
set -euo pipefail
echo "baseline stage-03-runbook-stack $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "Collect process, network and filesystem baselines before the target command."
