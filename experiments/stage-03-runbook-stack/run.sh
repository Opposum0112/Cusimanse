#!/usr/bin/env bash
set -euo pipefail
echo "run stage-03-runbook-stack"
echo "Approved target:"
echo "  python3 -m labctl stage run 03"
echo "Refusing to execute unreviewed commands. Pass --apply via labctl after review."
