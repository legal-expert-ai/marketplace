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

function Write-SmokeFailureDiagnostics {
    param(
        [Parameter(Mandatory = $true)][object[]]$Output,
        [Parameter(Mandatory = $true)][string]$InstallRoot
    )

    Write-Host "Installer process output:"
    $Output | ForEach-Object { Write-Host ([string]$_) }
    $installerLog = Join-Path $InstallRoot "installer.log"
    if (Test-Path -LiteralPath $installerLog -PathType Leaf) {
        Write-Host "Installer log:"
        Get-Content -LiteralPath $installerLog | ForEach-Object { Write-Host $_ }
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
if "%1 %2 %3"=="mcp list --json" (
  if exist "%LEGAL_EXPERT_TEST_MCP_RESET%" (
    if exist "%LEGAL_EXPERT_TEST_AUTH_STATE%" (
      echo [{"name":"legal-expert","enabled":true,"auth_status":"o_auth","transport":{"type":"streamable_http","url":"https://api.legal-expert.ai/mcp"}},{"name":"node_repl","enabled":true,"auth_status":"unsupported","transport":{"type":"stdio","command":"node_repl.exe"}}]
    ) else (
      echo [{"name":"legal-expert","enabled":true,"auth_status":"not_logged_in","transport":{"type":"streamable_http","url":"https://api.legal-expert.ai/mcp"}},{"name":"node_repl","enabled":true,"auth_status":"unsupported","transport":{"type":"stdio","command":"node_repl.exe"}}]
    )
  ) else if exist "%LEGAL_EXPERT_TEST_AUTH_STATE%" (
    echo [{"name":"legal-expert","enabled":true,"auth_status":"o_auth","transport":{"type":"streamable_http","url":"%LEGAL_EXPERT_TEST_MCP_URL%"}},{"name":"node_repl","enabled":true,"auth_status":"unsupported","transport":{"type":"stdio","command":"node_repl.exe"}}]
  ) else (
    echo [{"name":"legal-expert","enabled":true,"auth_status":"not_logged_in","transport":{"type":"streamable_http","url":"%LEGAL_EXPERT_TEST_MCP_URL%"}},{"name":"node_repl","enabled":true,"auth_status":"unsupported","transport":{"type":"stdio","command":"node_repl.exe"}}]
  )
)
if "%1 %2 %3"=="mcp remove legal-expert" type nul > "%LEGAL_EXPERT_TEST_MCP_RESET%"
if "%1 %2 %3"=="mcp login legal-expert" (
  type nul > "%LEGAL_EXPERT_TEST_AUTH_STATE%"
  echo OAuth login completed.
)
exit /b 0
'@ | Set-Content -LiteralPath $fakeCodex -Encoding ASCII

    $env:CODEX_EXE = $fakeCodex
    $env:LEGAL_EXPERT_TEST_COMMAND_LOG = $commandLog
    $env:LEGAL_EXPERT_TEST_MARKETPLACE_PRESENT = "0"
    $env:LEGAL_EXPERT_TEST_AUTH_STATE = Join-Path $testRoot "oauth-authenticated"
    $env:LEGAL_EXPERT_TEST_MCP_RESET = Join-Path $testRoot "mcp-reset"
    $env:LEGAL_EXPERT_TEST_MCP_URL = "https://api.legal-expert.ai/mcp"

    $freshInstallRoot = Join-Path $testRoot "install-new"
    $freshOutput = @(& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $installer -InstallRoot $freshInstallRoot -TestMode -ForcePortableGit)
    if ($LASTEXITCODE -ne 0) {
        Write-SmokeFailureDiagnostics -Output $freshOutput -InstallRoot $freshInstallRoot
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
    if ($freshCommands -notmatch "mcp login legal-expert --scopes openid,profile,email,offline_access") {
        throw "Fresh install did not start the Legal Expert OAuth flow."
    }
    if ($freshCommands -notmatch "mcp list --json") {
        throw "Fresh install did not verify MCP authentication."
    }
    if ($freshCommands -match "mcp remove legal-expert") {
        throw "Fresh install unexpectedly replaced a production MCP connection."
    }

    Clear-Content -LiteralPath $commandLog
    Remove-Item -LiteralPath $env:LEGAL_EXPERT_TEST_MCP_RESET -Force -ErrorAction SilentlyContinue
    $env:LEGAL_EXPERT_TEST_MARKETPLACE_PRESENT = "1"
    $env:LEGAL_EXPERT_TEST_MCP_URL = "https://legal-expert-preview.invalid/mcp"
    $upgradeInstallRoot = Join-Path $testRoot "install-update"
    $upgradeOutput = @(& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $installer -InstallRoot $upgradeInstallRoot -TestMode)
    if ($LASTEXITCODE -ne 0) {
        Write-SmokeFailureDiagnostics -Output $upgradeOutput -InstallRoot $upgradeInstallRoot
        throw "Upgrade smoke test failed."
    }
    Assert-ProgressSequence -Output $upgradeOutput
    $upgradeCommands = Get-Content -LiteralPath $commandLog -Raw
    if ($upgradeCommands -notmatch "plugin marketplace upgrade legal-expert") {
        throw "Existing installations were not upgraded."
    }
    if ($upgradeCommands -notmatch "mcp remove legal-expert") {
        throw "Upgrade did not replace the stale preview MCP connection."
    }

    Write-Host "Windows installer smoke tests passed."
} finally {
    Remove-Item Env:CODEX_EXE -ErrorAction SilentlyContinue
    Remove-Item Env:LEGAL_EXPERT_TEST_COMMAND_LOG -ErrorAction SilentlyContinue
    Remove-Item Env:LEGAL_EXPERT_TEST_MARKETPLACE_PRESENT -ErrorAction SilentlyContinue
    Remove-Item Env:LEGAL_EXPERT_TEST_AUTH_STATE -ErrorAction SilentlyContinue
    Remove-Item Env:LEGAL_EXPERT_TEST_MCP_RESET -ErrorAction SilentlyContinue
    Remove-Item Env:LEGAL_EXPERT_TEST_MCP_URL -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $testRoot -Recurse -Force -ErrorAction SilentlyContinue
}
