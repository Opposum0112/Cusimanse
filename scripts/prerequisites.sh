#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
LOCAL_BIN="${HOME}/.local/bin"
LIMA_VERSION="2.2.0"

log() { printf '%s\n' "$*"; }
fail() { printf 'Prerequisite FAIL: %s\n' "$*" >&2; exit 1; }

OS="$(uname -s)"
ARCH="$(uname -m)"
DISTRO="unknown"
if [ -r /etc/os-release ]; then
  . /etc/os-release
  DISTRO="${ID:-unknown}"
fi

log "AI Security Lab prerequisite bootstrap"
log "Detected OS=${OS} distro=${DISTRO} architecture=${ARCH}"

mkdir -p "$LOCAL_BIN"
case ":${PATH}:" in
  *":${LOCAL_BIN}:"*) ;;
  *) export PATH="${LOCAL_BIN}:$PATH" ;;
esac

have() { command -v "$1" >/dev/null 2>&1; }

install_linux_packages() {
  local packages=(git bash curl python3)
  case "$DISTRO" in
    ubuntu|debian|linuxmint|pop)
      packages+=(qemu-system-x86 qemu-utils)
      if ! have sudo && [ "$(id -u)" -ne 0 ]; then fail "sudo is required to install missing packages"; fi
      if have sudo; then sudo apt-get update; sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "${packages[@]}"; else apt-get update; DEBIAN_FRONTEND=noninteractive apt-get install -y "${packages[@]}"; fi
      ;;
    fedora|rhel|rocky|almalinux)
      packages+=(qemu-system-x86-core qemu-img)
      if ! have sudo && [ "$(id -u)" -ne 0 ]; then fail "sudo is required to install missing packages"; fi
      if have sudo; then sudo dnf install -y "${packages[@]}"; else dnf install -y "${packages[@]}"; fi
      ;;
    arch|manjaro)
      packages+=(qemu-desktop)
      if ! have sudo && [ "$(id -u)" -ne 0 ]; then fail "sudo is required to install missing packages"; fi
      if have sudo; then sudo pacman -Sy --needed --noconfirm "${packages[@]}"; else pacman -Sy --needed --noconfirm "${packages[@]}"; fi
      ;;
    opensuse*|sles)
      packages+=(qemu)
      if ! have sudo && [ "$(id -u)" -ne 0 ]; then fail "sudo is required to install missing packages"; fi
      if have sudo; then sudo zypper --non-interactive install "$@" "${packages[@]}"; else zypper --non-interactive install "${packages[@]}"; fi
      ;;
    *)
      fail "unsupported Linux distribution '$DISTRO'; install git, bash, python3, curl and QEMU using the distribution's supported package manager"
      ;;
  esac
}

if [ "$OS" = "Darwin" ]; then
  have brew || fail "Homebrew is required on macOS for automated prerequisites"
  brew install git python3 qemu lima
elif [ "$OS" = "Linux" ]; then
  missing=0
  for tool in git bash curl python3 qemu-system-x86_64; do have "$tool" || missing=1; done
  if [ "$missing" -eq 1 ]; then install_linux_packages; fi
else
  fail "unsupported host OS '$OS'; use a supported Linux/macOS host or install prerequisites manually"
fi

# Install Lima from Homebrew where available. On Linux without a package-provided
# limactl, use the official signed release archive and keep it user-local.
if ! have limactl; then
  if [ "$OS" = "Darwin" ] && have brew; then
    brew install lima
  elif [ "$OS" = "Linux" ]; then
    case "$ARCH" in
      x86_64) LIMA_ARCH="x86_64" ;;
      aarch64|arm64) LIMA_ARCH="aarch64" ;;
      *) fail "unsupported Linux architecture '$ARCH' for automated Lima installation" ;;
    esac
    tmp="$(mktemp -d)"
    trap 'rm -rf "$tmp"' EXIT
    url="https://github.com/lima-vm/lima/releases/download/v${LIMA_VERSION}/lima-${LIMA_VERSION}-Linux-${LIMA_ARCH}.tar.gz"
    curl -fsSL "$url" -o "$tmp/lima.tar.gz"
    tar -xzf "$tmp/lima.tar.gz" -C "$HOME/.local"
    trap - EXIT
    rm -rf "$tmp"
  fi
fi

# Goose is installed only when absent. This is the official Goose CLI bootstrap.
# The command is idempotent because the check above prevents reinstalling it.
if ! have goose; then
  curl -fsSL https://github.com/aaif-goose/goose/releases/download/stable/download_cli.sh | bash
fi

# Make user-local binaries available to this process and future interactive shells.
for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
  if [ -f "$rc" ] && ! grep -Fq 'export PATH="$HOME/.local/bin:$PATH"' "$rc"; then
    printf '\n# AI Security Lab user-local tools\nexport PATH="$HOME/.local/bin:$PATH"\n' >> "$rc"
  fi
done

missing=()
for tool in git bash python3 qemu-system-x86_64 limactl goose; do
  have "$tool" || missing+=("$tool")
done

if [ "${#missing[@]}" -ne 0 ]; then
  fail "required tools still missing: ${missing[*]}"
fi

log "OS PASS: ${OS} ${DISTRO} ${ARCH}"
log "Tools PASS: git bash python3 qemu-system-x86_64 limactl goose"
log "Prerequisite PASS"
log "Shell: source scripts/goose-env.sh before running Goose"
