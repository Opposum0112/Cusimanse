#!/usr/bin/env bash
set -euo pipefail
echo "run stage-00-repo-bootstrap"
echo "Approved target:"
echo "  python3 -m labctl init"
echo "Refusing to execute unreviewed commands. Pass --apply via labctl after review."
