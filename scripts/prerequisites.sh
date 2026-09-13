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

linux_pkg_manager(){
  if have apt-get; then printf 'apt';
  elif have dnf; then printf 'dnf';
  elif have pacman; then printf 'pacman';
  elif have zypper; then printf 'zypper';
  elif have apk; then printf 'apk';
  else printf 'none'; fi
}

install_linux_packages(){
  local manager="$(linux_pkg_manager)"
  local packages=(git bash curl python3 ruby)
  case "$manager" in
    apt) packages+=(golang qemu-system-x86 qemu-utils);;
    dnf) packages+=(golang qemu-system-x86-core qemu-img);;
    pacman) packages+=(go qemu-desktop);;
    zypper) packages+=(go qemu);;
    apk) packages+=(go qemu-system-x86_64 qemu-img);;
    none) fail "no supported Linux package manager detected; install Git, Bash, curl, Python 3, Ruby, Go and QEMU manually";;
  esac
  if [ "$(id -u)" -ne 0 ] && ! have sudo; then fail "sudo is required to install missing Linux packages"; fi
  local SUDO=""; [ "$(id -u)" -ne 0 ] && SUDO="sudo"
  case "$manager" in
    apt) $SUDO apt-get update; $SUDO env DEBIAN_FRONTEND=noninteractive apt-get install -y "${packages[@]}";;
    dnf) $SUDO dnf install -y "${packages[@]}";;
    pacman) $SUDO pacman -Sy --needed --noconfirm "${packages[@]}";;
    zypper) $SUDO zypper --non-interactive install "${packages[@]}";;
    apk) $SUDO apk add --no-cache "${packages[@]}";;
  esac
}

if [ "$(id -u)" -ne 0 ] && have sudo; then SUDO="sudo"; else SUDO=""; fi

if [ "$OS" = "Darwin" ]; then
  have brew || fail "Homebrew is required on macOS"
  brew install git python3 ruby go qemu || true
elif [ "$OS" = "Linux" ]; then
  missing=0
  for tool in git bash curl python3 ruby go qemu-system-x86_64; do have "$tool" || missing=1; done
  [ "$missing" -eq 0 ] || install_linux_packages
else
  fail "unsupported host OS '$OS'"
fi

install_lima_release(){
  have curl || fail "curl is required for Lima binary installation"
  mkdir -p "$LOCAL_BIN"
  local version os_name arch_name asset tmp
  version="$(curl -fsSL https://api.github.com/repos/lima-vm/lima/releases/latest | python3 -c 'import json,sys; print(json.load(sys.stdin)["tag_name"])')" \
    || fail "unable to determine latest Lima release"
  os_name="$(printf '%s' "$OS" | tr '[:upper:]' '[:lower:]')"
  case "$ARCH" in
    x86_64|amd64) arch_name="x86_64";;
    aarch64|arm64) arch_name="arm64";;
    *) fail "unsupported host architecture for automatic Lima install: $ARCH";;
  esac
  asset="lima-${version#v}-${os_name}-${arch_name}.tar.gz"
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' RETURN
  log "Installing Lima from official release archive: $asset"
  curl -fL --retry 3 "https://github.com/lima-vm/lima/releases/download/${version}/${asset}" -o "$tmp/lima.tar.gz" \
    || fail "unable to download official Lima release $version"
  tar -xzf "$tmp/lima.tar.gz" -C "$tmp"
  [ -x "$tmp/bin/limactl" ] || fail "official Lima archive did not contain bin/limactl"
  cp "$tmp/bin/limactl" "$LOCAL_BIN/limactl"
  chmod +x "$LOCAL_BIN/limactl"
  if [ -x "$tmp/bin/lima" ]; then cp "$tmp/bin/lima" "$LOCAL_BIN/lima"; chmod +x "$LOCAL_BIN/lima"; fi
  if [ -d "$tmp/share/lima" ]; then
    mkdir -p "$LOCAL_BIN/../share/lima"
    cp -a "$tmp/share/lima/." "$LOCAL_BIN/../share/lima/"
  fi
}

if ! have limactl; then
  log "Lima not found; attempting native package-manager installation"
  lima_installed=0
  if [ "$OS" = "Darwin" ] && have brew; then brew install lima && lima_installed=1 || true
  elif [ "$OS" = "Linux" ]; then
    manager="$(linux_pkg_manager)"
    if [ "$(id -u)" -ne 0 ] && ! have sudo; then SUDO=""; else SUDO="$( [ "$(id -u)" -ne 0 ] && printf sudo )"; fi
    case "$manager" in
      apt) $SUDO apt-get update && $SUDO env DEBIAN_FRONTEND=noninteractive apt-get install -y lima && lima_installed=1 || true;;
      dnf) $SUDO dnf install -y lima && lima_installed=1 || true;;
      pacman) $SUDO pacman -Sy --needed --noconfirm lima && lima_installed=1 || true;;
      zypper) $SUDO zypper --non-interactive install lima && lima_installed=1 || true;;
      apk) $SUDO apk add --no-cache lima && lima_installed=1 || true;;
    esac
  fi
  if [ "$lima_installed" -eq 0 ] || ! have limactl; then
    log "Native Lima package unavailable; using the official Lima release archive"
    install_lima_release
    hash -r
  fi
fi

have goose || curl -fsSL https://github.com/aaif-goose/goose/releases/download/stable/download_cli.sh | bash

install_optional_tools(){
  log "Installing optional security-research tools"
  if [ "$OS" = "Darwin" ]; then brew install jq yq ripgrep sqlite3 binutils libmagic yara || true; return; fi
  case "$(linux_pkg_manager)" in
    apt) $SUDO apt-get update && $SUDO env DEBIAN_FRONTEND=noninteractive apt-get install -y jq yq ripgrep sqlite3 file binutils strace lsof tcpdump tshark yara;;
    dnf) $SUDO dnf install -y jq yq ripgrep sqlite3 file binutils strace lsof tcpdump wireshark-cli yara;;
    pacman) $SUDO pacman -Sy --needed --noconfirm jq yq ripgrep sqlite sqlite-tools file binutils strace lsof tcpdump wireshark-cli yara;;
    zypper) $SUDO zypper --non-interactive install jq yq ripgrep sqlite3 file binutils strace lsof tcpdump wireshark-cli yara;;
    apk) $SUDO apk add --no-cache jq yq ripgrep sqlite file binutils strace lsof tcpdump wireshark-cli yara;;
    *) fail "unsupported Linux package manager for optional tools";;
  esac
}

install_observability(){
  log "Installing mandatory OpenTelemetry/Phoenix foundation"
  python3 -m pip install --user opentelemetry-api opentelemetry-sdk opentelemetry-exporter-otlp arize-phoenix || fail "OpenTelemetry/Phoenix installation failed"
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
