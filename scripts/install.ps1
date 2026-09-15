# Idempotent Windows host bootstrap. Prefer winget, then scoop, then choco.
$ErrorActionPreference = 'Continue'
function Have($name) { return [bool](Get-Command $name -ErrorAction SilentlyContinue) }
function Log($m) { Write-Host "[cusimanse] $m" }
function Ensure($id, $winget, $scoop, $choco) {
  if (Have $id) { Log "ok $id (already present)"; return }
  if (Have 'winget' -and $winget) { Log "winget $winget"; winget install --accept-package-agreements --accept-source-agreements $winget; return }
  if (Have 'scoop' -and $scoop) { Log "scoop $scoop"; scoop install $scoop; return }
  if (Have 'choco' -and $choco) { Log "choco $choco"; choco install -y $choco; return }
  Log "WARN: $id NOT_DEPLOYED (no package manager)"
}
Log 'os=windows'
Ensure git Git.Git git git
Ensure curl cURL.cURL curl curl
Ensure go GoLang.Go go golang
Ensure node OpenJS.NodeJS.LTS nodejs-lts nodejs
Ensure yq MikeFarah.yq yq yq
Ensure multipass Canonical.Multipass multipass multipass
if (-not (Have 'goose')) { Log 'WARN: install Goose from https://block.github.io/goose/ — official Windows build' } else { Log 'ok goose' }
Log 'bootstrap complete. Use WSL2 for Lima/QEMU guests, or Multipass on native Windows.'
