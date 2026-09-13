#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"; cd "$ROOT"
fail(){ printf 'Preflight FAIL: %s\n' "$*" >&2; exit 1; }; pass(){ printf 'Preflight PASS: %s\n' "$*"; }; have(){ command -v "$1" >/dev/null 2>&1; }
have_qemu(){ have qemu-system-x86_64 || have qemu-system-aarch64 || have qemu-system-x86_64-spice || have qemu-system-aarch64-spice; }
while IFS= read -r -d '' script; do chmod +x "$script"; [ -x "$script" ] || fail "cannot enable execute bit: $script"; done < <(find "$ROOT/scripts" -type f -name '*.sh' -print0)
OS="$(uname -s)"; ARCH="$(uname -m)"; DISTRO="unknown"; [ -r /etc/os-release ] && . /etc/os-release && DISTRO="${ID:-unknown}"
printf 'Cusimanse interactive preflight: %s/%s/%s\n' "$OS" "$DISTRO" "$ARCH"
echo '1) Check/repair baseline host'
echo '2) Check baseline + selected primary agent'
echo '3) Full capability audit (all planes)'
printf 'Preflight mode [3]: '; read -r mode || mode=3; mode="${mode:-3}"
missing=(); for tool in git bash curl python3 ruby go; do have "$tool" || missing+=("$tool"); done; have limactl || missing+=(limactl); have_qemu || missing+=(qemu)
if [ "${#missing[@]}" -gt 0 ]; then printf 'Missing: %s\n' "${missing[*]}"; printf 'Run comprehensive installer now? [Y/n]: '; read -r answer || answer=y; case "${answer:-y}" in y|Y|yes|YES) bash "$ROOT/scripts/prerequisites.sh";; *) fail "required tools missing: ${missing[*]}";; esac; hash -r; fi
for tool in git bash curl python3 ruby go limactl; do have "$tool" || fail "required tool unavailable after bootstrap: $tool"; done; have_qemu || fail 'QEMU system emulator unavailable after bootstrap'; pass 'baseline host tools'
if [ "$OS" = Linux ]; then [ -e /dev/kvm ] && pass '/dev/kvm available' || printf '%s\n' 'Preflight WARN: /dev/kvm unavailable; virtualization may be slower.'; elif [ "$OS" = Darwin ]; then pass 'macOS host detected'; elif grep -qi microsoft /proc/version 2>/dev/null; then pass 'Windows WSL2 Linux environment detected'; else fail "unsupported host OS: $OS"; fi
limactl --version >/dev/null 2>&1 || fail 'limactl is installed but not runnable'; pass 'Lima executable'
for script in scripts/*.sh scripts/tests/*.sh; do [ -f "$script" ] || continue; [ -x "$script" ] || fail "execute bit missing: $script"; done; pass 'repository script execute bits'
if [ "$mode" -ge 2 ] 2>/dev/null; then
  printf 'Select primary adapter (blank = none) [prime-agent/hermes/goose]: '; read -r adapter || adapter=""
  if [ -n "$adapter" ]; then case "$adapter" in prime-agent) have prime-agent || fail 'prime-agent not installed';; hermes) have hermes || fail 'hermes not installed';; goose) have goose || fail 'goose not installed';; *) fail "unsupported adapter: $adapter";; esac; pass "selected primary adapter: $adapter"; fi
fi
if [ "$mode" -eq 3 ] 2>/dev/null; then
  echo '== Plane capability audit =='
  for tool in jq yq; do have "$tool" && pass "control utility: $tool" || printf 'Preflight INFO: %s not deployed\n' "$tool"; done
  python3 -c 'import importlib.util; print("OpenTelemetry:", bool(importlib.util.find_spec("opentelemetry"))); print("Phoenix:", bool(importlib.util.find_spec("phoenix")))' || true
  for tool in numbat aegis; do have "$tool" && pass "observability/governance: $tool" || printf 'Preflight INFO: %s NOT_DEPLOYED\n' "$tool"; done
  [ -f "$ROOT/policies/host-policy.yaml" ] && pass 'policy plane files' || fail 'host policy missing'
  [ -d "$ROOT/recipes" ] && pass 'control recipes present' || fail 'recipes directory missing'
  [ -d "$ROOT/skills" ] && pass 'learning plane present' || printf '%s\n' 'Preflight INFO: skills directory absent; candidates may be under .agents/skills.'
  [ -d "$ROOT/.agents/skills" ] && pass 'agent skill library present' || true
  pass 'full capability audit'
fi
printf '%s\n' 'Cusimanse host preflight PASS'
