Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$testRoot = Join-Path $env:RUNNER_TEMP ("legal-expert-installer-test-{0}" -f [Guid]::NewGuid().ToString("N"))
$fakeCodex = Join-Path $testRoot "codex.cmd"
$commandLog = Join-Path $testRoot "codex-commands.log"
$installer = Join-Path $PSScriptRoot "Install-LegalExpert.ps1"
New-Item -ItemType Directory -Path $testRoot -Force | Out-Null

try {
    @'
@echo off
echo %*>>"%LEGAL_EXPERT_TEST_COMMAND_LOG%"
if "%1 %2 %3"=="plugin marketplace list" (
  if "%LEGAL_EXPERT_TEST_MARKETPLACE_PRESENT%"=="1" (
    echo {"marketplaces":[{"name":"legal-expert"}]}
  ) else (
    echo {"marketplaces":[]}
  )
)
exit /b 0
'@ | Set-Content -LiteralPath $fakeCodex -Encoding ASCII

    $env:CODEX_EXE = $fakeCodex
    $env:LEGAL_EXPERT_TEST_COMMAND_LOG = $commandLog
    $env:LEGAL_EXPERT_TEST_MARKETPLACE_PRESENT = "0"

    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $installer -InstallRoot (Join-Path $testRoot "install-new") -TestMode
    if ($LASTEXITCODE -ne 0) {
        throw "Fresh-install smoke test failed."
    }
    $freshCommands = Get-Content -LiteralPath $commandLog -Raw
    if ($freshCommands -notmatch "plugin marketplace add legal-expert-ai/marketplace --ref stable") {
        throw "Fresh install did not add the stable marketplace."
    }
    if ($freshCommands -notmatch "plugin add legal-expert@legal-expert") {
        throw "Fresh install did not install the Legal Expert plugin."
    }

    Clear-Content -LiteralPath $commandLog
    $env:LEGAL_EXPERT_TEST_MARKETPLACE_PRESENT = "1"
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $installer -InstallRoot (Join-Path $testRoot "install-update") -TestMode
    if ($LASTEXITCODE -ne 0) {
        throw "Upgrade smoke test failed."
    }
    $upgradeCommands = Get-Content -LiteralPath $commandLog -Raw
    if ($upgradeCommands -notmatch "plugin marketplace upgrade legal-expert") {
        throw "Existing installations were not upgraded."
    }

    Write-Host "Windows installer smoke tests passed."
} finally {
    Remove-Item Env:CODEX_EXE -ErrorAction SilentlyContinue
    Remove-Item Env:LEGAL_EXPERT_TEST_COMMAND_LOG -ErrorAction SilentlyContinue
    Remove-Item Env:LEGAL_EXPERT_TEST_MARKETPLACE_PRESENT -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $testRoot -Recurse -Force -ErrorAction SilentlyContinue
}
