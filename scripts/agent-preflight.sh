#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail(){ printf 'Preflight FAIL: %s\n' "$*" >&2; exit 1; }
pass(){ printf 'Preflight PASS: %s\n' "$*"; }
have(){ command -v "$1" >/dev/null 2>&1; }

# Make all repository shell controls directly executable after checkout.
for script in scripts/*.sh scripts/tests/*.sh; do
  [ -f "$script" ] || continue
  chmod +x "$script"
  [ -x "$script" ] || fail "cannot enable execute bit: $script"
done

OS="$(uname -s)"
ARCH="$(uname -m)"
DISTRO="unknown"
if [ -r /etc/os-release ]; then . /etc/os-release; DISTRO="${ID:-unknown}"; fi
printf 'Cusimanse preflight: %s/%s/%s\n' "$OS" "$DISTRO" "$ARCH"

# Preflight is allowed to repair a missing dependency by invoking the
# distro-neutral prerequisite bootstrap. It then verifies the final state.
required=(git bash curl python3 ruby go qemu-system-x86_64 limactl)
missing=()
for tool in "${required[@]}"; do have "$tool" || missing+=("$tool"); done
if [ "${#missing[@]}" -gt 0 ]; then
  printf 'Missing prerequisites: %s\n' "${missing[*]}"
  bash "$ROOT/scripts/prerequisites.sh"
fi

for tool in "${required[@]}"; do have "$tool" || fail "required tool unavailable after bootstrap: $tool"; done
pass "required host tools"

if [ "$OS" = "Linux" ]; then
  if [ -e /dev/kvm ]; then pass "/dev/kvm available"; else printf 'Preflight WARN: /dev/kvm unavailable; Lima/QEMU may fall back to software virtualization.\n'; fi
elif [ "$OS" = "Darwin" ]; then
  pass "macOS host detected; Lima/QEMU virtualization path selected"
else
  fail "unsupported host OS: $OS"
fi

if ! limactl --version >/dev/null 2>&1; then fail "limactl is installed but not runnable"; fi
pass "Lima executable"

for script in scripts/*.sh scripts/tests/*.sh; do
  [ -f "$script" ] || continue
  [ -x "$script" ] || fail "execute bit missing after repair: $script"
done
pass "repository script execute bits"

if [ -n "${CUSIMANSE_PRIMARY_ADAPTER:-}" ]; then
  case "$CUSIMANSE_PRIMARY_ADAPTER" in
    prime-agent) have prime-agent || fail "selected adapter prime-agent is not installed" ;;
    hermes) have hermes || fail "selected adapter hermes is not installed" ;;
    goose) have goose || fail "selected adapter goose is not installed" ;;
    *) fail "unsupported CUSIMANSE_PRIMARY_ADAPTER: $CUSIMANSE_PRIMARY_ADAPTER" ;;
  esac
  pass "selected primary adapter: $CUSIMANSE_PRIMARY_ADAPTER"
else
  printf '%s\n' 'Preflight INFO: no primary adapter selected; set CUSIMANSE_PRIMARY_ADAPTER before agent execution.'
fi

printf '%s\n' 'Cusimanse host preflight PASS'
