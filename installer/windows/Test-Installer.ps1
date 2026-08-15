Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$testRoot = Join-Path $env:RUNNER_TEMP ("legal-expert-installer-test-{0}" -f [Guid]::NewGuid().ToString("N"))
$fakeCodex = Join-Path $testRoot "codex.cmd"
$commandLog = Join-Path $testRoot "codex-commands.log"
$installer = Join-Path $PSScriptRoot "Install-LegalExpert.ps1"
New-Item -ItemType Directory -Path $testRoot -Force | Out-Null

function Assert-ProgressSequence {
    param([Parameter(Mandatory = $true)][object[]]$Output)

    $progressValues = @(
        $Output |
            ForEach-Object { [string]$_ } |
            Where-Object { $_ -match '^LEGAL_EXPERT_PROGRESS\|(\d+)\|' } |
            ForEach-Object { [int]([regex]::Match($_, '^LEGAL_EXPERT_PROGRESS\|(\d+)\|').Groups[1].Value) }
    )
    if ($progressValues.Count -lt 6) {
        throw "Installer did not emit enough progress stages."
    }
    for ($index = 1; $index -lt $progressValues.Count; $index++) {
        if ($progressValues[$index] -lt $progressValues[$index - 1]) {
            throw "Installer progress moved backwards."
        }
    }
    if ($progressValues[0] -gt 10 -or $progressValues[-1] -ne 100) {
        throw "Installer progress must begin near zero and finish at 100."
    }
}

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
if "%1 %2 %3"=="plugin list --json" (
  echo {"installed":[{"pluginId":"legal-expert@legal-expert","installed":true,"enabled":true}]}
)
exit /b 0
'@ | Set-Content -LiteralPath $fakeCodex -Encoding ASCII

    $env:CODEX_EXE = $fakeCodex
    $env:LEGAL_EXPERT_TEST_COMMAND_LOG = $commandLog
    $env:LEGAL_EXPERT_TEST_MARKETPLACE_PRESENT = "0"

    $freshOutput = @(& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $installer -InstallRoot (Join-Path $testRoot "install-new") -TestMode -ForcePortableGit)
    if ($LASTEXITCODE -ne 0) {
        throw "Fresh-install smoke test failed."
    }
    Assert-ProgressSequence -Output $freshOutput
    $freshCommands = Get-Content -LiteralPath $commandLog -Raw
    if ($freshCommands -notmatch "plugin marketplace add legal-expert-ai/marketplace --ref stable") {
        throw "Fresh install did not add the stable marketplace."
    }
    if ($freshCommands -notmatch "plugin add legal-expert@legal-expert") {
        throw "Fresh install did not install the Legal Expert plugin."
    }
    if ($freshCommands -notmatch "plugin list --json") {
        throw "Fresh install did not verify the installed plugin."
    }

    Clear-Content -LiteralPath $commandLog
    $env:LEGAL_EXPERT_TEST_MARKETPLACE_PRESENT = "1"
    $upgradeOutput = @(& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $installer -InstallRoot (Join-Path $testRoot "install-update") -TestMode)
    if ($LASTEXITCODE -ne 0) {
        throw "Upgrade smoke test failed."
    }
    Assert-ProgressSequence -Output $upgradeOutput
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
