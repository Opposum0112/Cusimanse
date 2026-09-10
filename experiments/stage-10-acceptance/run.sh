#!/usr/bin/env bash
set -euo pipefail
echo "run stage-10-acceptance"
echo "Approved target:"
echo "  python3 -m labctl accept"
echo "Refusing to execute unreviewed commands. Pass --apply via labctl after review."
