#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOCAL_BIN="${HOME}/.local/bin"
log(){ printf '%s\n' "$*"; }
fail(){ printf 'Prerequisite FAIL: %s\n' "$*" >&2; exit 1; }
have(){ command -v "$1" >/dev/null 2>&1; }
OS="$(uname -s)"; ARCH="$(uname -m)"; DISTRO="unknown"
if [ -r /etc/os-release ]; then . /etc/os-release; DISTRO="${ID:-unknown}"; fi

# Repository shell programs are executable host controls. Repair and verify bits.
for script in scripts/*.sh scripts/tests/*.sh; do
  [ -f "$script" ] || continue
  chmod +x "$script"
  [ -x "$script" ] || fail "required execute bit missing: $script"
done
mkdir -p "$LOCAL_BIN"
export GOPATH="${GOPATH:-$HOME/go}"; export GOBIN="${GOBIN:-$GOPATH/bin}"
mkdir -p "$GOBIN"; export PATH="$LOCAL_BIN:$GOBIN:$PATH"
log "Cusimanse host prerequisite bootstrap: ${OS}/${DISTRO}/${ARCH}"

install_linux_packages(){
  local packages=(git bash curl python3 ruby golang)
  case "$DISTRO" in
    ubuntu|debian|linuxmint|pop) packages+=(qemu-system-x86 qemu-utils) ;;
    fedora|rhel|rocky|almalinux) packages+=(qemu-system-x86-core qemu-img) ;;
    arch|manjaro) packages+=(qemu-desktop) ;;
    opensuse*|sles) packages+=(qemu) ;;
    *) fail "unsupported Linux distribution '$DISTRO'" ;;
  esac
  if ! have sudo && [ "$(id -u)" -ne 0 ]; then fail "sudo is required to install missing packages"; fi
  case "$DISTRO" in
    ubuntu|debian|linuxmint|pop) ${SUDO:-} apt-get update; ${SUDO:-} DEBIAN_FRONTEND=noninteractive apt-get install -y "${packages[@]}" ;;
    fedora|rhel|rocky|almalinux) ${SUDO:-} dnf install -y "${packages[@]}" ;;
    arch|manjaro) ${SUDO:-} pacman -Sy --needed --noconfirm "${packages[@]}" ;;
    opensuse*|sles) ${SUDO:-} zypper --non-interactive install "${packages[@]}" ;;
  esac
}
if [ "$(id -u)" -ne 0 ] && have sudo; then SUDO="sudo"; else SUDO=""; fi

if [ "$OS" = "Darwin" ]; then
  have brew || fail "Homebrew is required on macOS"; brew install git python3 ruby go qemu lima
elif [ "$OS" = "Linux" ]; then
  missing=0; for tool in git bash curl python3 ruby go qemu-system-x86_64; do have "$tool" || missing=1; done
  [ "$missing" -eq 0 ] || install_linux_packages
else fail "unsupported host OS '$OS'"; fi

if ! have limactl; then
  if [ "$OS" = "Darwin" ]; then brew install lima
  else
    case "$DISTRO" in
      ubuntu|debian|linuxmint|pop) ${SUDO:-} apt-get update && ${SUDO:-} DEBIAN_FRONTEND=noninteractive apt-get install -y lima ;;
      fedora|rhel|rocky|almalinux) ${SUDO:-} dnf install -y lima ;;
      arch|manjaro) ${SUDO:-} pacman -Sy --needed --noconfirm lima ;;
      opensuse*|sles) ${SUDO:-} zypper --non-interactive install lima ;;
      *) fail "no supported automated Lima package path" ;;
    esac
  fi
fi
have goose || curl -fsSL https://github.com/aaif-goose/goose/releases/download/stable/download_cli.sh | bash

install_optional_tools(){
  log "Installing optional security-research tools"
  if [ "$OS" = "Darwin" ]; then brew install jq yq ripgrep sqlite3 binutils libmagic yara || true; return; fi
  case "$DISTRO" in
    ubuntu|debian|linuxmint|pop) ${SUDO:-} apt-get update && ${SUDO:-} DEBIAN_FRONTEND=noninteractive apt-get install -y jq yq ripgrep sqlite3 file binutils strace lsof tcpdump tshark yara ;;
    fedora|rhel|rocky|almalinux) ${SUDO:-} dnf install -y jq yq ripgrep sqlite3 file binutils strace lsof tcpdump wireshark-cli yara ;;
    arch|manjaro) ${SUDO:-} pacman -Sy --needed --noconfirm jq yq ripgrep sqlite sqlite-tools file binutils strace lsof tcpdump wireshark-cli yara ;;
    opensuse*|sles) ${SUDO:-} zypper --non-interactive install jq yq ripgrep sqlite3 file binutils strace lsof tcpdump wireshark-cli yara ;;
    *) fail "unsupported Linux distribution '$DISTRO'" ;;
  esac
}

install_observability(){
  log "Installing mandatory OpenTelemetry/Phoenix foundation"
  python3 -m pip install --user opentelemetry-api opentelemetry-sdk opentelemetry-exporter-otlp arize-phoenix || fail "OpenTelemetry/Phoenix installation failed"
  # Numbat/Aegis package names vary by release; fail closed rather than installing an unverified package.
  for tool in numbat aegis; do
    if have "$tool"; then log "$tool: PASS"; else log "$tool: NOT_DEPLOYED (verified installer/adapter required)"; fi
  done
  have phoenix || log "phoenix CLI: NOT_DEPLOYED; Python package is the supported Phoenix foundation"
}

PROFILE="${CUSIMANSE_INSTALL_PRODUCTION_PROFILE:-${CUSIMANSE_INSTALL_ARCH_REFACTOR:-0}}"
OBSERVABILITY="${CUSIMANSE_INSTALL_OBSERVABILITY:-1}"
[ "$PROFILE" = "1" ] && install_optional_tools
[ "$PROFILE" = "1" ] && python3 -m pip install --user langgraph qdrant-client chromadb pyyaml || true
[ "$OBSERVABILITY" = "1" ] && install_observability

for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
  if [ -f "$rc" ] && ! grep -Fq 'export PATH="$HOME/.local/bin:$HOME/go/bin:$PATH"' "$rc"; then
    printf '\n# Cusimanse user-local tools\nexport PATH="$HOME/.local/bin:$HOME/go/bin:$PATH"\n' >> "$rc"
  fi
done

missing=(); for tool in git bash python3 ruby go qemu-system-x86_64 limactl goose; do have "$tool" || missing+=("$tool"); done
[ "${#missing[@]}" -eq 0 ] || fail "required tools still missing: ${missing[*]}"
log "Mandatory host prerequisites PASS; script execute bits PASS; PATH/GOPATH/GOBIN configured"
[ "$OBSERVABILITY" = "1" ] && log "Agent observability foundation configured"
