# Windows installer shim

#Requires -Version 5.1
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Write-Host '[cusimanse] Windows host preparation'

if (Get-Command wsl.exe -ErrorAction SilentlyContinue) {
  Write-Host '[cusimanse] WSL2 detected; delegating to the canonical install.sh.'
  & wsl.exe bash -lc "cd '$root' && ./scripts/install.sh"
  exit $LASTEXITCODE
}

Write-Host '[cusimanse] Native Windows mode: install the required Windows tools using your approved package manager,'
Write-Host '             then run the repository validation/preflight from WSL2 or Git Bash.'
Write-Host '             Lima/QEMU experiments are supported through the Linux compatibility path.'
if (Get-Command winget.exe -ErrorAction SilentlyContinue) {
  Write-Host '[cusimanse] winget is available for prerequisite installation; no packages are silently installed by this shim.'
} else {
  Write-Warning '[cusimanse] winget not found. Install a supported package manager or enable WSL2.'
}
