#!/usr/bin/env bash
set -euo pipefail
LOCAL_BIN="${HOME}/.local/bin"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
log(){ printf '%s\n' "$*"; }
fail(){ printf 'Prerequisite FAIL: %s\n' "$*" >&2; exit 1; }
have(){ command -v "$1" >/dev/null 2>&1; }
ask(){ local n="$1" d="$2" a; read -r -p "$n [$d]: " a || true; printf '%s' "${a:-$d}"; }
OS="$(uname -s)"; ARCH="$(uname -m)"; DISTRO="unknown"
[ -r /etc/os-release ] && { . /etc/os-release; DISTRO="${ID:-unknown}"; }
mkdir -p "$LOCAL_BIN"
export PATH="$LOCAL_BIN:$ROOT/scripts:$ROOT/scripts/tests:$PATH"
install_linux_packages(){
  local p=(git bash curl python3 ruby golang qemu-system-x86 qemu-utils)
  case "$DISTRO" in fedora|rhel|rocky|almalinux) p=(git bash curl python3 ruby golang qemu-system-x86-core qemu-img);; arch|manjaro) p=(git bash curl python3 ruby go qemu-desktop);; opensuse*|sles) p=(git bash curl python3 ruby go qemu);; esac
  if ! have sudo && [ "$(id -u)" -ne 0 ]; then fail 'sudo is required to install missing host packages'; fi
  case "$DISTRO" in
    ubuntu|debian|linuxmint|pop) if have sudo; then sudo apt-get update && sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "${p[@]}"; else apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y "${p[@]}"; fi;;
    fedora|rhel|rocky|almalinux) if have sudo; then sudo dnf install -y "${p[@]}"; else dnf install -y "${p[@]}"; fi;;
    arch|manjaro) if have sudo; then sudo pacman -Sy --needed --noconfirm "${p[@]}"; else pacman -Sy --needed --noconfirm "${p[@]}"; fi;;
    opensuse*|sles) if have sudo; then sudo zypper --non-interactive install "${p[@]}"; else zypper --non-interactive install "${p[@]}"; fi;;
    *) fail "unsupported Linux distribution '$DISTRO'";;
  esac
}
if [ "$OS" = Darwin ]; then have brew || fail 'Homebrew is required on macOS'; brew install git python3 ruby go qemu lima; elif [ "$OS" = Linux ]; then missing=0; for t in git bash curl python3 ruby go qemu-system-x86_64; do have "$t" || missing=1; done; [ "$missing" -eq 1 ] && install_linux_packages; else fail "unsupported host OS '$OS'"; fi
if ! have limactl; then if [ "$OS" = Darwin ]; then brew install lima; else case "$DISTRO" in ubuntu|debian|linuxmint|pop) sudo apt-get install -y lima;; fedora|rhel|rocky|almalinux) sudo dnf install -y lima;; arch|manjaro) sudo pacman -Sy --needed --noconfirm lima;; opensuse*|sles) sudo zypper --non-interactive install lima;; *) fail 'Lima missing; install it manually';; esac; fi; fi
if ! have goose; then curl -fsSL https://github.com/aaif-goose/goose/releases/download/stable/download_cli.sh | bash; fi
if [ -t 0 ]; then
  mkdir -p "$ROOT/.cusimanse/generated"
  cat > "$ROOT/.cusimanse/generated/selections.env" <<EOF
NUMBAT=$(ask 'Enable Numbat agent observability?' yes)
OPENTELEMETRY=$(ask 'Enable OpenTelemetry?' yes)
PROMETHEUS=$(ask 'Enable Prometheus metrics?' yes)
MODEL_GATEWAY=$(ask 'Enable model gateway?' yes)
AI_GOVERNANCE=$(ask 'Enable AI-plane governance?' yes)
SKILLS=$(ask 'Enable skills registry?' yes)
MCP=$(ask 'Enable MCP registry?' yes)
EOF
fi
find "$ROOT/scripts" -type f -name '*.sh' -exec chmod +x {} +
for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
  touch "$rc"
  grep -Fq '# Cusimanse shell' "$rc" || printf '\n# Cusimanse shell\nexport PATH="%s/scripts:%s/scripts/tests:$HOME/.local/bin:$PATH"\n' "$ROOT" "$ROOT" >> "$rc"
done
missing=(); for t in git bash python3 ruby go qemu-system-x86_64 limactl goose; do have "$t" || missing+=("$t"); done
[ "${#missing[@]}" -eq 0 ] || fail "required tools still missing: ${missing[*]}"
log "OS PASS: $OS $DISTRO $ARCH"
log 'Required tools PASS: git bash python3 ruby go qemu-system-x86_64 limactl goose'
log 'Interactive component selections persisted under .cusimanse/generated/'
log 'Prerequisite PASS'
