#!/usr/bin/env bash
set -euo pipefail
echo "run stage-09-operations"
echo "Approved target:"
echo "  python3 -m labctl doctor"
echo "Refusing to execute unreviewed commands. Pass --apply via labctl after review."
