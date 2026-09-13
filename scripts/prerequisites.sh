#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOCAL_BIN="${HOME}/.local/bin"; LOCAL_PREFIX="${HOME}/.local"
log(){ printf '%s\n' "$*"; }; fail(){ printf 'Prerequisite FAIL: %s\n' "$*" >&2; exit 1; }; have(){ command -v "$1" >/dev/null 2>&1; }
have_qemu(){ have qemu-system-x86_64 || have qemu-system-aarch64 || have qemu-system-x86_64-spice || have qemu-system-aarch64-spice; }

# Recover execute bits before doing anything else. This also makes a damaged checkout usable.
for script in scripts/*.sh scripts/tests/*.sh; do [ -f "$script" ] || continue; chmod +x "$script"; [ -x "$script" ] || fail "cannot enable execute bit: $script"; done
mkdir -p "$LOCAL_BIN"; export GOPATH="${GOPATH:-$HOME/go}"; export GOBIN="${GOBIN:-$GOPATH/bin}"; mkdir -p "$GOBIN"; export PATH="$LOCAL_BIN:$GOBIN:$PATH"
OS="$(uname -s)"; ARCH="$(uname -m)"; DISTRO="unknown"; [ -r /etc/os-release ] && . /etc/os-release && DISTRO="${ID:-unknown}"
log "Cusimanse host bootstrap: ${OS}/${DISTRO}/${ARCH}"

linux_pkg_manager(){ if have apt-get; then printf apt; elif have dnf; then printf dnf; elif have pacman; then printf pacman; elif have zypper; then printf zypper; elif have apk; then printf apk; else printf none; fi; }
install_linux_packages(){
  local m="$(linux_pkg_manager)" SUDO=""; [ "$(id -u)" -ne 0 ] && SUDO=sudo
  [ "$(id -u)" -eq 0 ] || have sudo || fail "sudo is required to install Linux packages"
  local p=(git bash curl python3 ruby)
  case "$m" in apt) p+=(golang qemu-system-x86 qemu-utils); $SUDO apt-get update; $SUDO env DEBIAN_FRONTEND=noninteractive apt-get install -y "${p[@]}";;
    dnf) p+=(golang qemu-system-x86-core qemu-img); $SUDO dnf install -y "${p[@]}";;
    pacman) p+=(go qemu-desktop); $SUDO pacman -Sy --needed --noconfirm "${p[@]}";;
    zypper) p+=(go qemu); $SUDO zypper --non-interactive install "${p[@]}";;
    apk) p+=(go qemu-system-x86_64 qemu-img); $SUDO apk add --no-cache "${p[@]}";;
    *) fail "no supported Linux package manager detected";; esac
}

if [ "$OS" = Darwin ]; then have brew || fail 'Homebrew is required on macOS'; brew install git python3 ruby go qemu || true
elif [ "$OS" = Linux ]; then miss=0; for t in git bash curl python3 ruby go; do have "$t" || miss=1; done; have_qemu || miss=1; [ "$miss" -eq 0 ] || install_linux_packages
elif grep -qi microsoft /proc/version 2>/dev/null; then log 'Windows WSL2 detected; using Linux bootstrap path.'
else fail "unsupported host OS '$OS'; on Windows use WSL2"; fi

install_lima_release(){
  local version os_name arch_name tmp; version="$(curl -fsSL https://api.github.com/repos/lima-vm/lima/releases/latest | python3 -c 'import json,sys; print(json.load(sys.stdin)["tag_name"])')" || fail 'cannot determine latest Lima release'
  os_name="$(printf %s "$OS" | tr '[:upper:]' '[:lower:]')"; case "$ARCH" in x86_64|amd64) arch_name=x86_64;; aarch64|arm64) arch_name=arm64;; *) fail "unsupported architecture: $ARCH";; esac
  tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' RETURN; local asset="lima-${version#v}-${os_name}-${arch_name}.tar.gz"
  curl -fL --retry 3 "https://github.com/lima-vm/lima/releases/download/${version}/${asset}" -o "$tmp/lima.tar.gz" || fail 'official Lima archive download failed'
  tar -xzf "$tmp/lima.tar.gz" -C "$LOCAL_PREFIX"; [ -x "$LOCAL_BIN/limactl" ] || fail 'Lima archive did not install limactl'; chmod +x "$LOCAL_BIN/limactl"; [ ! -e "$LOCAL_PREFIX/share/lima" ] && fail 'Lima share directory missing'
}
if ! have limactl; then
  log 'Lima not found; trying native package manager first.'; ok=0
  if [ "$OS" = Darwin ] && have brew; then brew install lima && ok=1 || true
  elif [ "$OS" = Linux ]; then m="$(linux_pkg_manager)"; SUDO=""; [ "$(id -u)" -ne 0 ] && SUDO=sudo; case "$m" in apt) $SUDO apt-get update && $SUDO apt-get install -y lima && ok=1 || true;; dnf) $SUDO dnf install -y lima && ok=1 || true;; pacman) $SUDO pacman -Sy --needed --noconfirm lima && ok=1 || true;; zypper) $SUDO zypper --non-interactive install lima && ok=1 || true;; apk) $SUDO apk add --no-cache lima && ok=1 || true;; esac; fi
  [ "$ok" -eq 1 ] && have limactl || { log 'Native Lima package unavailable; using official release archive.'; install_lima_release; }; hash -r
fi

install_agents(){
  log 'Installing supported primary-agent adapters.'
  if ! have goose; then curl -fsSL https://github.com/aaif-goose/goose/releases/download/stable/download_cli.sh | bash || log 'Goose: NOT_DEPLOYED'; fi
  if ! have prime-agent; then curl -fsSL https://app.primeintellect.ai/prime-agent/install.sh | sh || log 'Prime Agent: NOT_DEPLOYED'; fi
  if ! have hermes; then curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash || log 'Hermes: NOT_DEPLOYED'; fi
}
install_optional(){
  log 'Installing security-research/control/learning tooling.'
  if [ "$OS" = Darwin ]; then brew install jq yq ripgrep sqlite3 binutils libmagic yara || true; else m="$(linux_pkg_manager)"; SUDO=""; [ "$(id -u)" -ne 0 ] && SUDO=sudo; case "$m" in apt) $SUDO apt-get update && $SUDO apt-get install -y jq yq ripgrep sqlite3 file binutils strace lsof tcpdump tshark yara;; dnf) $SUDO dnf install -y jq yq ripgrep sqlite3 file binutils strace lsof tcpdump wireshark-cli yara;; pacman) $SUDO pacman -Sy --needed --noconfirm jq yq ripgrep sqlite file binutils strace lsof tcpdump wireshark-cli yara;; zypper) $SUDO zypper --non-interactive install jq yq ripgrep sqlite3 file binutils strace lsof tcpdump wireshark-cli yara;; apk) $SUDO apk add --no-cache jq yq ripgrep sqlite file binutils strace lsof tcpdump wireshark-cli yara;; esac; fi
  python3 -m pip install --user langgraph qdrant-client chromadb pyyaml || true
}
install_observability(){ python3 -m pip install --user opentelemetry-api opentelemetry-sdk opentelemetry-exporter-otlp arize-phoenix || fail 'OpenTelemetry/Phoenix installation failed'; for t in numbat aegis; do have "$t" && log "$t: PASS" || log "$t: NOT_DEPLOYED (verified adapter required)"; done; }

if [ "${CUSIMANSE_NONINTERACTIVE:-0}" != 1 ]; then
  echo 'Select Cusimanse installation profile:'; echo '  1) Baseline host + VM prerequisites'; echo '  2) Extended research/control/learning'; echo '  3) Observability/governance'; echo '  4) All components + all supported primary agents'; echo '  5) Check/repair only'; printf 'Choice [1]: '; read -r choice || choice=1
else choice=1; fi
case "${choice:-1}" in 2) install_optional;; 3) install_observability;; 4) install_optional; install_observability; install_agents;; esac
[ "${CUSIMANSE_INSTALL_PRODUCTION_PROFILE:-0}" = 1 ] && install_optional
[ "${CUSIMANSE_INSTALL_OBSERVABILITY:-0}" = 1 ] && install_observability
[ "${CUSIMANSE_INSTALL_AGENTS:-0}" = 1 ] && install_agents

for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do [ -f "$rc" ] && ! grep -Fq 'export PATH="$HOME/.local/bin:$HOME/go/bin:$PATH"' "$rc" && printf '\n# Cusimanse\nexport PATH="$HOME/.local/bin:$HOME/go/bin:$PATH"\n' >> "$rc" || true; done
missing=(); for t in git bash python3 ruby go limactl; do have "$t" || missing+=("$t"); done; have_qemu || missing+=(qemu); [ "${#missing[@]}" -eq 0 ] || fail "required tools still missing: ${missing[*]}"
log 'Cusimanse prerequisite bootstrap PASS'
