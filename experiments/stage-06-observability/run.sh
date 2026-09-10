#!/usr/bin/env bash
set -euo pipefail
echo "run stage-06-observability"
echo "Approved target:"
echo "  python3 -m labctl stack up --stack observability --dry-run"
echo "Refusing to execute unreviewed commands. Pass --apply via labctl after review."
