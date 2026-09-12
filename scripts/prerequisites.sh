#!/usr/bin/env bash
set -euo pipefail
LOCAL_BIN="${HOME}/.local/bin"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
log() { printf '%s\n' "$*"; }
fail() { printf 'Prerequisite FAIL: %s\n' "$*" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }
OS="$(uname -s)"; ARCH="$(uname -m)"; DISTRO="unknown"
if [ -r /etc/os-release ]; then . /etc/os-release; DISTRO="${ID:-unknown}"; fi
mkdir -p "$LOCAL_BIN" "$ROOT/.cusimanse"; export PATH="$LOCAL_BIN:$PATH"
install_linux_packages() {
  local packages=(git bash curl python3 ruby golang)
  case "$DISTRO" in ubuntu|debian|linuxmint|pop) packages+=(qemu-system-x86 qemu-utils);; fedora|rhel|rocky|almalinux) packages+=(qemu-system-x86-core qemu-img);; arch|manjaro) packages+=(qemu-desktop);; opensuse*|sles) packages+=(qemu);; *) fail "unsupported Linux distribution '$DISTRO'";; esac
  if ! have sudo && [ "$(id -u)" -ne 0 ]; then fail 'sudo is required to install missing packages'; fi
  case "$DISTRO" in ubuntu|debian|linuxmint|pop) ${SUDO:-sudo} apt-get update && ${SUDO:-sudo} DEBIAN_FRONTEND=noninteractive apt-get install -y "${packages[@]}";; fedora|rhel|rocky|almalinux) ${SUDO:-sudo} dnf install -y "${packages[@]}";; arch|manjaro) ${SUDO:-sudo} pacman -Sy --needed --noconfirm "${packages[@]}";; opensuse*|sles) ${SUDO:-sudo} zypper --non-interactive install "${packages[@]}";; esac
}
if [ "$OS" = "Darwin" ]; then have brew || fail 'Homebrew is required on macOS'; brew install git python3 ruby go qemu lima; elif [ "$OS" = "Linux" ]; then missing=0; for tool in git bash curl python3 ruby go qemu-system-x86_64; do have "$tool" || missing=1; done; [ "$missing" -eq 0 ] || install_linux_packages; else fail "unsupported host OS '$OS'"; fi
if ! have limactl; then if [ "$OS" = "Darwin" ]; then brew install lima; else case "$DISTRO" in ubuntu|debian|linuxmint|pop) ${SUDO:-sudo} apt-get update && ${SUDO:-sudo} DEBIAN_FRONTEND=noninteractive apt-get install -y lima;; fedora|rhel|rocky|almalinux) ${SUDO:-sudo} dnf install -y lima;; arch|manjaro) ${SUDO:-sudo} pacman -Sy --needed --noconfirm lima;; opensuse*|sles) ${SUDO:-sudo} zypper --non-interactive install lima;; *) fail "Lima is missing and '$DISTRO' has no supported automated package path";; esac; fi; fi
if ! have goose; then curl -fsSL https://github.com/aaif-goose/goose/releases/download/stable/download_cli.sh | bash; fi
adapter_available() { case "$1" in goose) have goose;; opencode) have opencode;; pi) have pi;; hermes) have hermes;; codex) have codex;; prime-intellect) have prime-agent;; *) return 1;; esac; }
install_adapter() { case "$1" in goose) :;; opencode) if ! have opencode && have npm; then npm install -g opencode-ai; fi;; pi) if ! have pi && have npm; then npm install -g @mariozechner/pi-coding-agent; fi;; codex) if ! have codex && have npm; then npm install -g @openai/codex; fi;; *) log "$1 is provider/manual-managed; no unverified installer is executed.";; esac; }
select_primary() { if [ -n "${CUSIMANSE_PRIMARY_ADAPTER:-}" ]; then printf '%s\n' "$CUSIMANSE_PRIMARY_ADAPTER"; return; fi; if [ ! -t 0 ]; then printf 'goose\n'; return; fi; cat <<'EOF'
Select one primary Cusimanse operator:
  1) goose
  2) opencode
  3) grok-build
  4) antigravity
  5) pi
  6) hermes
  7) codex
  8) prime-intellect
  9) claude-code (enterprise)
 10) devin (enterprise)
EOF
read -r -p 'Primary adapter [1-10]: ' choice; case "$choice" in 1) echo goose;; 2) echo opencode;; 3) echo grok-build;; 4) echo antigravity;; 5) echo pi;; 6) echo hermes;; 7) echo codex;; 8) echo prime-intellect;; 9) echo claude-code;; 10) echo devin;; *) fail 'invalid primary adapter selection';; esac; }
PRIMARY="$(select_primary)"; install_adapter "$PRIMARY"
if adapter_available "$PRIMARY"; then log "Primary adapter '$PRIMARY': AVAILABLE"; else log "Primary adapter '$PRIMARY': NOT_DEPLOYED — provider/manual setup required."; fi
cat > "$ROOT/.cusimanse/primary-agent.yaml" <<EOF
version: 1
primary_adapter: $PRIMARY
contract: recipes/agents/primary-agent.yaml
learning: recipes/agents/learning-loop.yaml
selected_at: $(date -u +%Y-%m-%dT%H:%M:%SZ)
EOF
chmod +x "$ROOT"/scripts/*.sh "$ROOT"/scripts/tests/*.sh 2>/dev/null || true
if [ -x "$ROOT/scripts/agent-preflight.sh" ]; then "$ROOT/scripts/agent-preflight.sh" || log "Agent preflight: NOT_DEPLOYED/needs provider configuration"; fi
for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do if [ -f "$rc" ] && ! grep -Fq 'export PATH="$HOME/.local/bin:$PATH"' "$rc"; then printf '\n# Cusimanse user-local tools\nexport PATH="$HOME/.local/bin:$PATH"\n' >> "$rc"; fi; done
missing=(); for tool in git bash python3 ruby go qemu-system-x86_64 limactl goose; do have "$tool" || missing+=("$tool"); done
[ "${#missing[@]}" -eq 0 ] || fail "required tools still missing: ${missing[*]}"
log "OS PASS: ${OS} ${DISTRO} ${ARCH}"; log "Required tools PASS"; log "Primary adapter: $PRIMARY"; log "Prerequisite PASS"
