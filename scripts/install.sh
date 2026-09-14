#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export PATH="$HOME/.local/bin:$HOME/go/bin:$PATH"
HOST_RECIPE="$ROOT/recipes/host/security-research.yaml"
BIN="$HOME/.local/bin"; CFG="$HOME/.config/cusimanse"; DATA="$HOME/.local/share/cusimanse"; VENV="$DATA/venv"
AEGIS_VERSION="b42d4c08c2fe6ed497173cefad173f3f8d21a936"
mkdir -p "$BIN" "$CFG" "$DATA"
log(){ printf '[cusimanse] %s\n' "$*"; }
fail(){ printf '[cusimanse] ERROR: %s\n' "$*" >&2; exit 1; }
have(){ command -v "$1" >/dev/null 2>&1; }
run_root(){ if [ -n "${SUDO:-}" ]; then "$SUDO" "$@"; else "$@"; fi; }
OS="$(uname -s)"; SUDO=""; [ "$(id -u)" -eq 0 ] || SUDO=sudo
[ -s "$HOST_RECIPE" ] || fail 'host recipe missing'
have yq || { if [ "$OS" = Darwin ] && have brew; then brew install yq; elif [ "$OS" = Linux ] && have apt-get; then run_root apt-get update; run_root apt-get install -y yq; else fail 'yq is required to read the host recipe'; fi; }
install_common_linux(){
  if have apt-get; then
    run_root apt-get update
    run_root apt-get install -y git bash curl python3 python3-pip python3-venv jq yq ripgrep ca-certificates
    node_major="$(node -p 'process.versions.node.split(".")[0]' 2>/dev/null || echo 0)"
    if [ "$node_major" -lt 22 ]; then
      tmp="$(mktemp)"; curl -fL --retry 3 --proto '=https' --tlsv1.2 https://deb.nodesource.com/setup_22.x -o "$tmp"; if [ -n "${SUDO:-}" ]; then "$SUDO" bash "$tmp"; else bash "$tmp"; fi; rm -f "$tmp"; run_root apt-get install -y nodejs
    fi
    run_root apt-get install -y golang-go
  elif have dnf; then run_root dnf install -y git bash curl python3 python3-pip python3-virtualenv nodejs npm golang jq yq ripgrep ca-certificates
  elif have pacman; then run_root pacman -Sy --needed --noconfirm git bash curl python python-pip nodejs npm go jq yq ripgrep ca-certificates
  elif have zypper; then run_root zypper --non-interactive install git bash curl python3 python3-pip nodejs npm go jq yq ripgrep ca-certificates
  else fail 'unsupported Linux package manager'; fi
}
if [ "$OS" = Darwin ]; then
  have brew || fail 'Homebrew is required on macOS'
  brew install git curl python node ruby go jq yq ripgrep qemu lima ca-certificates
elif [ "$OS" = Linux ]; then
  install_common_linux
  if have apt-get; then run_root apt-get install -y qemu-system-x86 qemu-utils strace tcpdump iproute2 iputils-ping dnsutils lsof inotify-tools file psmisc procps; fi
  if have dnf; then run_root dnf install -y qemu-system-x86-core qemu-img strace tcpdump iproute iputils bind-utils lsof inotify-tools file psmisc procps; fi
  if have pacman; then run_root pacman -Sy --needed --noconfirm qemu strace tcpdump iproute iputils bind lsof inotify-tools file psmisc procps; fi
  if have zypper; then run_root zypper --non-interactive install qemu strace tcpdump iproute2 iputils bind-utils lsof inotify-tools file psmisc procps; fi
else
  fail 'Use WSL2 for full Cusimanse experiments or the PowerShell native-agent fallback'
fi
case "$OS" in Linux) platform=linux;; Darwin) platform=macos;; *) platform=windows_wsl2;; esac
NODE_MAJOR="$(node -p 'process.versions.node.split(".")[0]' 2>/dev/null || echo 0)"; [ "$NODE_MAJOR" -ge 22 ] || fail 'Node.js 22+ required'
GOOSE_VERSION="${CUSIMANSE_GOOSE_VERSION:-1.50.0}"
if ! have goose; then
  tmp="$(mktemp)"; url="https://github.com/aaif-goose/goose/releases/download/v${GOOSE_VERSION}/download_cli.sh"; curl -fL --retry 3 --proto '=https' --tlsv1.2 "$url" -o "$tmp"; printf '%s  %s\n' 'ab5ae40513348ec4e6047cc7338040aab2df5246800c111d22065766ba6013f0' "$tmp" | sha256sum -c -; bash -n "$tmp"; CONFIGURE=false GOOSE_BIN_DIR="$BIN" bash "$tmp"; rm -f "$tmp"
fi
have goose || fail 'Goose installation failed'
CFG="$(yq -r '.configuration.root' "$HOST_RECIPE" | sed "s|^~|$HOME|")"; AEGIS="$(yq -r '.configuration.aegis_checkout' "$HOST_RECIPE" | sed "s|^~|$HOME|")"; VENV="$(yq -r '.configuration.python_environment' "$HOST_RECIPE" | sed "s|^~|$HOME|")"; GATEWAY_CFG="$(yq -r '.configuration.gateway' "$HOST_RECIPE" | sed "s|^~|$HOME|")"
mkdir -p "$CFG" "$(dirname "$AEGIS")" "$(dirname "$VENV")"
python3 -m venv "$VENV"
"$VENV/bin/pip" install --upgrade pip
"$VENV/bin/pip" install litellm arize-phoenix opentelemetry-api opentelemetry-sdk opentelemetry-exporter-otlp clawmetry
ln -sf "$VENV/bin/litellm" "$BIN/litellm"; ln -sf "$VENV/bin/clawmetry" "$BIN/clawmetry"
if ! have numbat; then GOBIN="$BIN" go install github.com/perplexityai/numbat/cmd/numbat@v0.2.0; fi
if ! have omniroute; then npm install -g omniroute@3.8.50; fi
have numbat || fail 'Numbat installation failed'; have omniroute || fail 'OmniRoute installation failed'; have clawmetry || fail 'ClawMetry installation failed'
if [ ! -d "$AEGIS/.git" ]; then git clone --depth 1 https://github.com/antropos17/Aegis "$AEGIS"; fi
(cd "$AEGIS" && git fetch --depth 1 origin "$AEGIS_VERSION" && git checkout --detach "$AEGIS_VERSION" && npm ci)
cat > "$BIN/cusimanse-aegis" <<EOF
#!/usr/bin/env bash
set -euo pipefail
cd "$AEGIS"
npm start
EOF
chmod +x "$BIN/cusimanse-aegis"
cat > "$GATEWAY_CFG" <<'EOF'
model_list:
  - model_name: auto
    litellm_params:
      model: openai/auto
      api_base: http://127.0.0.1:20128/v1
      api_key: os.environ/OMNIROUTE_API_KEY
router_settings:
  routing_strategy: simple-shuffle
  fallbacks: []
general_settings:
  master_key: os.environ/LITELLM_MASTER_KEY
EOF
cat > "$CFG/omniroute.env" <<'EOF'
export OMNIROUTE_HOST=127.0.0.1
export OMNIROUTE_PORT=20128
EOF
cat > "$CFG/observability.env" <<EOF
export NUMBAT_RECORD_FILE=$HOME/.numbat/cusimanse.ndjson
export PHOENIX_HOST=127.0.0.1
export PHOENIX_PORT=6006
export OTEL_EXPORTER_OTLP_ENDPOINT=http://127.0.0.1:4318
export AEGIS_ROOT=$AEGIS
export CLAWMETRY_HOST=127.0.0.1
export CLAWMETRY_PORT=8900
EOF
cat > "$CFG/goose.env" <<'EOF'
export GOOSE_PROVIDER=openai
export OPENAI_HOST=http://127.0.0.1:4000
export OPENAI_BASE_PATH=v1/chat/completions
export OPENAI_API_KEY=${LITELLM_API_KEY:-}
EOF
for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do if [ -f "$rc" ] && ! grep -Fq 'Cusimanse PATH' "$rc"; then printf '\n# Cusimanse PATH\nexport PATH="$HOME/.local/bin:$HOME/go/bin:$PATH"\n' >> "$rc"; fi; done
selection="${CUSIMANSE_INSTALL_ADAPTERS:-}"
if [ -z "$selection" ] && [ -t 0 ]; then
  printf '%s\n' 'Optional adapters:' '  1) none' '  2) OpenCode' '  3) Hermes' '  4) Antigravity' '  5) Pi' '  6) all'
  read -r -p '[cusimanse] Selection [1]: ' answer || answer=1
  case "$answer" in 2) selection=opencode;;3) selection=hermes;;4) selection=antigravity;;5) selection=pi;;6) selection=all;;*) selection=none;;esac
fi
[ "$selection" = all ] && selection=opencode,hermes,antigravity,pi
install_remote_script(){ local url="$1"; local tmp; tmp="$(mktemp)"; curl -fL --retry 3 --proto '=https' --tlsv1.2 "$url" -o "$tmp"; bash -n "$tmp"; bash "$tmp"; rm -f "$tmp"; }
case ",$selection," in *,opencode,*) have opencode || install_remote_script 'https://opencode.ai/install';; esac
case ",$selection," in *,hermes,*) have hermes || install_remote_script 'https://hermes-agent.nousresearch.com/install.sh';; esac
case ",$selection," in *,antigravity,*) have agy || install_remote_script 'https://antigravity.google/cli/install.sh';; esac
case ",$selection," in *,pi,*) have pi || npm install -g @earendil-works/pi-coding-agent@0.74.0;; esac
missing=0
while IFS= read -r tool; do have "$tool" || { log "MISSING common host command: $tool"; missing=1; }; done < <(yq -r '.common.commands[]' "$HOST_RECIPE")
while IFS= read -r tool; do have "$tool" || { log "MISSING $platform host command: $tool"; missing=1; }; done < <(yq -r '.platforms["'"$platform"'"].commands[]' "$HOST_RECIPE" 2>/dev/null)
[ "$missing" -eq 0 ] || fail 'required host capabilities are unavailable; no experiment should start'
log "Goose ${GOOSE_VERSION}, Numbat v0.2.0, OmniRoute 3.8.50, Aegis ${AEGIS_VERSION} and Pi 0.74.0 selected; host installation/configuration complete."
