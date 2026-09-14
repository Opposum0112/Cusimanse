#Requires -Version 5.1
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
function Have($name) { return [bool](Get-Command $name -ErrorAction SilentlyContinue) }
Write-Host '[cusimanse] Windows host preparation'

# Prefer the canonical Linux installer in WSL2 because the reference experiment
# boundary is Lima/QEMU and the complete forensic toolchain is Linux-oriented.
if (Have 'wsl.exe') {
  Write-Host '[cusimanse] WSL2 detected; delegating to the canonical recipe-driven installer.'
  & wsl.exe bash -lc "cd '$root' && ./scripts/install.sh"
  exit $LASTEXITCODE
}

Write-Warning '[cusimanse] WSL2 is not installed. Native Windows mode installs the primary-agent tooling only; full Lima/QEMU experiments require WSL2 or a Linux/macOS host.'

if (Have 'winget.exe') {
  $packages = @(
    'Git.Git',
    'OpenJS.NodeJS.LTS'
  )
  foreach ($id in $packages) {
    & winget.exe install --id $id --exact --accept-source-agreements --accept-package-agreements --silent
    if ($LASTEXITCODE -ne 0 -and -not (Have ($(if ($id -like 'Git.*') {'git'} else {'node'})))) {
      throw "Failed to install required Windows package: $id"
    }
  }
} else {
  throw 'winget is required for native Windows fallback. Install WSL2 or enable winget.'
}

if (-not (Have 'goose.exe') -and -not (Have 'goose')) {
  $tmp = Join-Path $env:TEMP 'cusimanse-goose-install.ps1'
  Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/aaif-goose/goose/main/download_cli.ps1' -OutFile $tmp
  & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $tmp
  Remove-Item $tmp -Force -ErrorAction SilentlyContinue
}

Write-Host '[cusimanse] Native Windows primary-agent fallback is ready.'
Write-Host '[cusimanse] For the full mandatory gateway/observability + Lima experiment stack, install WSL2 and rerun scripts/install.ps1.'
