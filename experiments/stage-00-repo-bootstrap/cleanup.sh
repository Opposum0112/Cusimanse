#!/usr/bin/env bash
set -euo pipefail
echo "cleanup stage-00-repo-bootstrap"
echo "1. Preserve and hash evidence"
echo "2. Stop captures"
echo "3. Stop and delete the disposable Lima VM if one was used"
echo "4. Confirm no secrets leaked into Git"
