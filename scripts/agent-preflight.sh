#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"; cd "$ROOT"
fail(){ printf 'Preflight FAIL: %s\n' "$*" >&2; exit 1; }; pass(){ printf 'Preflight PASS: %s\n' "$*"; }; have(){ command -v "$1" >/dev/null 2>&1; }
have_qemu(){ have qemu-system-x86_64 || have qemu-system-aarch64 || have qemu-system-x86_64-spice || have qemu-system-aarch64-spice; }
while IFS= read -r -d '' script; do chmod +x "$script"; [ -x "$script" ] || fail "cannot enable execute bit: $script"; done < <(find "$ROOT/scripts" -type f -name '*.sh' -print0)
OS="$(uname -s)"; ARCH="$(uname -m)"; DISTRO="unknown"; [ -r /etc/os-release ] && . /etc/os-release && DISTRO="${ID:-unknown}"
printf 'Cusimanse comprehensive preflight: %s/%s/%s\n' "$OS" "$DISTRO" "$ARCH"
missing=(); for tool in git bash curl python3 ruby go; do have "$tool" || missing+=("$tool"); done; have limactl || missing+=(limactl); have_qemu || missing+=(qemu)
if [ "${#missing[@]}" -gt 0 ]; then printf 'Missing baseline capabilities: %s\n' "${missing[*]}"; printf 'Run the one-frontdoor bootstrap now? [Y/n]: '; read -r answer || answer=y; case "${answer:-y}" in y|Y|yes|YES) bash "$ROOT/scripts/prerequisites.sh";; *) fail "required capabilities missing: ${missing[*]}";; esac; hash -r; fi
for tool in git bash curl python3 ruby go limactl; do have "$tool" || fail "required tool unavailable after bootstrap: $tool"; done; have_qemu || fail 'QEMU system emulator unavailable after bootstrap'; pass 'host and VM toolchain'
if [ "$OS" = Linux ]; then [ -e /dev/kvm ] && pass '/dev/kvm available' || printf '%s\n' 'Preflight WARN: /dev/kvm unavailable; virtualization may be slower.'; elif [ "$OS" = Darwin ]; then pass 'macOS host detected'; elif grep -qi microsoft /proc/version 2>/dev/null; then pass 'Windows WSL2 Linux environment detected'; else fail "unsupported host OS: $OS"; fi
limactl --version >/dev/null 2>&1 || fail 'limactl is installed but not runnable'; pass 'Lima executable'
for script in scripts/*.sh scripts/tests/*.sh; do [ -f "$script" ] || continue; [ -x "$script" ] || fail "execute bit missing: $script"; done; pass 'repository script execute bits'
adapter="${CUSIMANSE_PRIMARY_ADAPTER:-}"; if [ -z "$adapter" ] && [ -f recipes/agents/self-learning-primary.yaml ]; then adapter="$(sed -n 's/^selected_adapter: *//p' recipes/agents/self-learning-primary.yaml | head -1)"; fi
if [ -n "$adapter" ] && [ "$adapter" != "null" ] && [ "$adapter" != "none" ]; then case "$adapter" in prime-agent|hermes|goose) have "$adapter" || fail "selected primary adapter not installed: $adapter";; *) fail "unsupported selected adapter: $adapter";; esac; pass "primary adapter: $adapter"; else printf '%s\n' 'Preflight INFO: no primary adapter selected'; fi
printf '%s\n' '== Plane capability audit =='
for tool in jq yq; do have "$tool" && pass "control utility: $tool" || printf 'Preflight INFO: %s NOT_DEPLOYED\n' "$tool"; done
python3 -c 'import importlib.util; print("OpenTelemetry:", bool(importlib.util.find_spec("opentelemetry"))); print("Phoenix:", bool(importlib.util.find_spec("phoenix")))' || true
for tool in numbat aegis; do have "$tool" && pass "observability/governance: $tool" || printf 'Preflight INFO: %s NOT_DEPLOYED\n' "$tool"; done
[ -f "$ROOT/recipes/observability/numbat.yaml" ] && pass 'Numbat recipe present' || fail 'Numbat recipe missing'
[ -f "$ROOT/recipes/observability/aegis.yaml" ] && pass 'Aegis recipe present' || fail 'Aegis recipe missing'
[ -f "$ROOT/policies/host-policy.yaml" ] && pass 'policy plane files' || fail 'host policy missing'
[ -d "$ROOT/recipes" ] && pass 'control recipes present' || fail 'recipes directory missing'
[ -d "$ROOT/.agents/skills" ] && pass 'agent skill library present' || printf '%s\n' 'Preflight INFO: agent skill library absent'
pass 'all planes audited'
printf '%s\n' 'Cusimanse host preflight PASS'
