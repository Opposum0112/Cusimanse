#!/usr/bin/env bash
set -euo pipefail
# Runs INSIDE the disposable VM (or prints the plan on the host).
ROOT="${LAB_ROOT:-/lab}"
PROBE="${ROOT}/packages/labprobe"
echo "go-install-001 target: in-repo packages/labprobe"
if [[ ! -d "${PROBE}" ]]; then
  echo "labprobe sources not found at ${PROBE}"
  echo "Copy packages/labprobe into the VM before running. Example:"
  echo "  limactl start --name go-install-001 experiments/go-install-001/lima.yaml"
  echo "  limactl copy packages/labprobe go-install-001:/tmp/labprobe"
  echo "  limactl shell go-install-001 -- bash -lc 'cd /tmp/labprobe && go install .'"
  exit 1
fi
cd "${PROBE}"
go version
go env GOPROXY GOSUMDB GOMODCACHE
# Local module: observes compiler/install without requiring a public GitHub repo.
GOPROXY=off go install .
command -v labprobe >/dev/null && labprobe || "$(go env GOPATH)/bin/labprobe"
