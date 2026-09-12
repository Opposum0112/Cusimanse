#!/usr/bin/env bash
set -euo pipefail

LOCAL_BIN="${HOME}/.local/bin"

log() { printf '%s\n' "$*"; }
fail() { printf 'Prerequisite FAIL: %s\n' "$*" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }

OS="$(uname -s)"
ARCH="$(uname -m)"
DISTRO="unknown"
if [ -r /etc/os-release ]; then
  . /etc/os-release
  DISTRO="${ID:-unknown}"
fi

log "Cusimanse prerequisite bootstrap"
log "Detected OS=${OS} distro=${DISTRO} architecture=${ARCH}"
mkdir -p "$LOCAL_BIN"
export PATH="$LOCAL_BIN:$PATH"

install_linux_packages() {
  local packages=(git bash curl python3 ruby golang)
  case "$DISTRO" in
    ubuntu|debian|linuxmint|pop) packages+=(qemu-system-x86 qemu-utils) ;;
    fedora|rhel|rocky|almalinux) packages+=(qemu-system-x86-core qemu-img) ;;
    arch|manjaro) packages+=(qemu-desktop) ;;
    opensuse*|sles) packages+=(qemu) ;;
    *) fail "unsupported Linux distribution '$DISTRO'; install git, bash, curl, python3, ruby, Go and QEMU using its supported package manager" ;;
  esac
  if ! have sudo && [ "$(id -u)" -ne 0 ]; then fail "sudo is required to install missing packages"; fi
  case "$DISTRO" in
    ubuntu|debian|linuxmint|pop) if have sudo; then sudo apt-get update && sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "${packages[@]}"; else apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y "${packages[@]}"; fi ;;
    fedora|rhel|rocky|almalinux) if have sudo; then sudo dnf install -y "${packages[@]}"; else dnf install -y "${packages[@]}"; fi ;;
    arch|manjaro) if have sudo; then sudo pacman -Sy --needed --noconfirm "${packages[@]}"; else pacman -Sy --needed --noconfirm "${packages[@]}"; fi ;;
    opensuse*|sles) if have sudo; then sudo zypper --non-interactive install "${packages[@]}"; else zypper --non-interactive install "${packages[@]}"; fi ;;
  esac
}

if [ "$OS" = "Darwin" ]; then
  have brew || fail "Homebrew is required on macOS for automated prerequisites"
  brew install git python3 ruby go qemu lima
elif [ "$OS" = "Linux" ]; then
  missing=0
  for tool in git bash curl python3 ruby go qemu-system-x86_64; do have "$tool" || missing=1; done
  if [ "$missing" -eq 1 ]; then install_linux_packages; fi
else
  fail "unsupported host OS '$OS'; use a supported Linux/macOS host or install prerequisites manually"
fi

if ! have limactl; then
  if [ "$OS" = "Darwin" ] && have brew; then brew install lima
  elif [ "$OS" = "Linux" ]; then
    case "$DISTRO" in
      ubuntu|debian|linuxmint|pop) if have sudo; then sudo apt-get update && sudo DEBIAN_FRONTEND=noninteractive apt-get install -y lima; else apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y lima; fi ;;
      fedora|rhel|rocky|almalinux) if have sudo; then sudo dnf install -y lima; else dnf install -y lima; fi ;;
      arch|manjaro) if have sudo; then sudo pacman -Sy --needed --noconfirm lima; else pacman -Sy --needed --noconfirm lima; fi ;;
      opensuse*|sles) if have sudo; then sudo zypper --non-interactive install lima; else zypper --non-interactive install lima; fi ;;
      *) fail "Lima is missing and this Linux distribution has no supported automated package path" ;;
    esac
  fi
fi

if ! have goose; then curl -fsSL https://github.com/aaif-goose/goose/releases/download/stable/download_cli.sh | bash; fi

# Optional research tools: explicit opt-in installation.
research_tools=(jq yq rg tcpdump strace lsof bpftrace file strings readelf objdump nm yara)
if [ "${CUSIMANSE_INSTALL_RESEARCH_TOOLS:-0}" = "1" ]; then
  case "$OS:$DISTRO" in
    Darwin:*) have brew || fail "Homebrew is required to install optional research tools"; brew install jq yq ripgrep tcpdump strace lsof bpftrace yara || true ;;
    Linux:ubuntu|Linux:debian|Linux:linuxmint|Linux:pop) if have sudo; then sudo apt-get update; sudo DEBIAN_FRONTEND=noninteractive apt-get install -y jq yq ripgrep tcpdump strace lsof bpftrace yara || true; fi ;;
    Linux:fedora|Linux:rhel|Linux:rocky|Linux:almalinux) if have sudo; then sudo dnf install -y jq yq ripgrep tcpdump strace lsof bpftrace yara || true; fi ;;
    Linux:arch|Linux:manjaro) if have sudo; then sudo pacman -Sy --needed --noconfirm jq yq ripgrep tcpdump strace lsof bpftrace yara || true; fi ;;
    *) log "Optional research-tool installation unsupported for ${OS}/${DISTRO}" ;;
  esac
fi

# Token/context optimization helpers. Ponytail is installed only when explicitly requested.
if [ "${CUSIMANSE_INSTALL_OPTIMIZATION_TOOLS:-0}" = "1" ]; then
  if have npm; then
    npm install -g ponytail 2>/dev/null || log "Ponytail package unavailable; optimization capability remains NOT_DEPLOYED"
  else
    log "npm unavailable; Ponytail NOT_DEPLOYED"
  fi
fi

for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
  if [ -f "$rc" ] && ! grep -Fq 'export PATH="$HOME/.local/bin:$PATH"' "$rc"; then
    printf '\n# Cusimanse user-local tools\nexport PATH="$HOME/.local/bin:$PATH"\n' >> "$rc"
  fi
done

missing=()
for tool in git bash python3 ruby go qemu-system-x86_64 limactl goose; do have "$tool" || missing+=("$tool"); done
if [ "${#missing[@]}" -ne 0 ]; then fail "required tools still missing: ${missing[*]}"; fi

log "OS PASS: ${OS} ${DISTRO} ${ARCH}"
log "Tools PASS: git bash python3 ruby go qemu-system-x86_64 limactl goose"
for tool in "${research_tools[@]}"; do if have "$tool"; then log "Research tool AVAILABLE: $tool"; else log "Research tool NOT_DEPLOYED: $tool"; fi; done
if have ponytail; then log "Optimization: ponytail AVAILABLE"; else log "Optimization: ponytail NOT_DEPLOYED"; fi
log "Prerequisite PASS"
log "Shell: source scripts/goose-env.sh before running Goose"
