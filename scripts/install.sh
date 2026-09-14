#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export PATH="$HOME/.local/bin:$HOME/go/bin:$PATH"
HOST_RECIPE="$ROOT/recipes/host/security-research.yaml"
ADAPTER_RECIPE="$ROOT/recipes/agents/adapter-installation.yaml"
BIN="$HOME/.local/bin"
CFG="$HOME/.config/cusimanse"
DATA="$HOME/.local/share/cusimanse"
VENV="$DATA/venv"
mkdir -p "$BIN" "$CFG" "$DATA"
log(){ printf '[cusimanse] %s\n' "$*"; }
fail(){ printf '[cusimanse] ERROR: %s\n' "$*" >&2; exit 1; }
have(){ command -v "$1" >/dev/null 2>&1; }
run_root(){ if [ -n "${SUDO:-}" ]; then "$SUDO" "$@"; else "$@"; fi; }
OS="$(uname -s)"; SUDO=""; [ "$(id -u)" -eq 0 ] || SUDO=sudo
[ -s "$HOST_RECIPE" ] || fail "missing host recipe: $HOST_RECIPE"
[ -s "$ADAPTER_RECIPE" ] || fail "missing adapter installation recipe: $ADAPTER_RECIPE"

if [ "$OS" = Darwin ]; then
  have brew || fail 'Homebrew is required on macOS'
  brew install git curl python node ruby go jq yq ripgrep qemu lima ca-certificates
elif [ "$OS" = Linux ]; then
  if have apt-get; then
    run_root apt-get update
    run_root env DEBIAN_FRONTEND=noninteractive apt-get install -y git bash curl python3 python3-pip python3-venv ruby jq yq ripgrep qemu-system-x86 qemu-utils lima ca-certificates strace tcpdump iproute2 iputils-ping dnsutils lsof inotify-tools file psmisc procps
    node_major="$(node -p 'process.versions.node.split(".")[0]' 2>/dev/null || echo 0)"
    if [ "$node_major" -lt 22 ]; then
      setup_node="$(curl -fsSL https://deb.nodesource.com/setup_22.x)"
      if [ -n "${SUDO:-}" ]; then printf '%s\n' "$setup_node" | "$SUDO" -E bash; else printf '%s\n' "$setup_node" | bash; fi
      run_root apt-get install -y nodejs
    fi
    run_root apt-get install -y golang-go
  elif have dnf; then
    run_root dnf install -y git bash curl python3 python3-pip python3-venv ruby nodejs npm golang jq yq ripgrep qemu-system-x86-core qemu-img lima ca-certificates strace tcpdump iproute iputils bind-utils lsof inotify-tools file psmisc procps
  elif have pacman; then
    run_root pacman -Sy --needed --noconfirm git bash curl python python-pip ruby nodejs npm go jq yq ripgrep qemu lima strace tcpdump iproute iputils bind lsof inotify-tools file psmisc procps
  elif have zypper; then
    run_root zypper --non-interactive install git bash curl python3 python3-pip ruby nodejs npm go jq yq ripgrep qemu lima ca-certificates strace tcpdump iproute2 iputils bind-utils lsof inotify-tools file psmisc procps
  else fail 'No supported Linux package manager'; fi
else
  fail 'Use Linux/macOS/WSL2 with install.sh, or native Windows with install.ps1'
fi

have yq || fail 'yq installation failed'
CFG="$(yq -r '.configuration.root' "$HOST_RECIPE" | sed "s|^~|$HOME|")"
AEGIS="$(yq -r '.configuration.aegis_checkout' "$HOST_RECIPE" | sed "s|^~|$HOME|")"
VENV="$(yq -r '.configuration.python_environment' "$HOST_RECIPE" | sed "s|^~|$HOME|")"
GATEWAY_CFG="$(yq -r '.configuration.gateway' "$HOST_RECIPE" | sed "s|^~|$HOME|")"
mkdir -p "$BIN" "$CFG" "$(dirname "$AEGIS")" "$(dirname "$VENV")"

if ! have goose; then curl -fsSL https://github.com/aaif-goose/goose/releases/download/stable/download_cli.sh | CONFIGURE=false GOOSE_BIN_DIR="$BIN" bash; fi
have goose || fail 'Goose installation failed'
node_major="$(node -p 'process.versions.node.split(".")[0]' 2>/dev/null || echo 0)"; [ "$node_major" -ge 22 ] || fail 'Node.js 22+ is required'
python3 -m venv "$VENV"
"$VENV/bin/pip" install --upgrade pip
"$VENV/bin/pip" install --upgrade litellm arize-phoenix opentelemetry-api opentelemetry-sdk opentelemetry-exporter-otlp clawmetry
ln -sf "$VENV/bin/litellm" "$BIN/litellm"
ln -sf "$VENV/bin/clawmetry" "$BIN/clawmetry"
if ! have numbat; then GOBIN="$BIN" go install github.com/perplexityai/numbat/cmd/numbat@latest; fi
if ! have omniroute; then npm install -g omniroute; fi
have numbat || fail 'Numbat installation failed'; have omniroute || fail 'OmniRoute installation failed'; have clawmetry || fail 'ClawMetry installation failed'

if [ ! -d "$AEGIS/.git" ]; then git clone --depth 1 https://github.com/antropos17/Aegis "$AEGIS"; else git -C "$AEGIS" fetch --depth 1 origin main >/dev/null 2>&1 || true; fi
(cd "$AEGIS" && npm ci)
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

for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
  if [ -f "$rc" ] && ! grep -Fq 'export PATH="$HOME/.local/bin:$HOME/go/bin:$PATH"' "$rc"; then printf '\n# Cusimanse\nexport PATH="$HOME/.local/bin:$HOME/go/bin:$PATH"\n' >> "$rc"; fi
done

install_adapters() {
  local selection="${CUSIMANSE_INSTALL_ADAPTERS:-}"
  if [ -z "$selection" ] && [ -t 0 ]; then
    printf '%s\n' 'Install optional primary-agent adapters?' '  1) none (default)' '  2) OpenCode' '  3) Hermes' '  4) Antigravity' '  5) Pi' '  6) all'
    read -r -p '[cusimanse] Selection [1]: ' answer || answer=1
    case "$answer" in 2) selection=opencode;; 3) selection=hermes;; 4) selection=antigravity;; 5) selection=pi;; 6) selection=all;; *) selection=none;; esac
  fi
  [ "$selection" = none ] || [ -z "$selection" ] && return 0
  [ "$selection" = all ] && selection=opencode,hermes,antigravity,pi
  case ",$selection," in *,opencode,*) have opencode || curl -fsSL https://opencode.ai/install | bash || log 'OpenCode optional install failed';; esac
  case ",$selection," in *,hermes,*) have hermes || curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash || log 'Hermes optional install failed';; esac
  case ",$selection," in *,antigravity,*) have agy || curl -fsSL https://antigravity.google/cli/install.sh | bash || log 'Antigravity optional install failed';; esac
  case ",$selection," in *,pi,*) have pi || npm install -g @mariozechner/pi-coding-agent || log 'Pi optional install failed';; esac
}
install_adapters

missing=0
while IFS= read -r tool; do have "$tool" || { printf '[cusimanse] MISSING required command: %s\n' "$tool" >&2; missing=1; }; done < <(yq -r '.required.commands[]' "$HOST_RECIPE")
[ "$missing" -eq 0 ] || fail 'one or more required host capabilities are unavailable'
"$ROOT/scripts/preflight.sh"
log 'Host installation and recipe-driven configuration PASS'
printf '%s\n' 'Next:' '  source ~/.config/cusimanse/goose.env' '  ./scripts/tools.sh list' '  ./scripts/tests/validate.sh'
