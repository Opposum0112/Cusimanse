#!/usr/bin/env bash
set -euo pipefail
echo "capture go-install-001"
echo "Instrumentation: process syscall filesystem dns network packet security-events"
echo "Start collectors BEFORE the target. Prefer VM-side strace/tcpdump."
echo "Do not capture host credential files."
