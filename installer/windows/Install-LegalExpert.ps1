[CmdletBinding()]
param(
    [string]$InstallRoot = (Join-Path $env:LOCALAPPDATA "Legal Expert"),
    [switch]$TestMode
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

$InstallerVersion = "1.0.0"
$MarketplaceName = "legal-expert"
$MarketplaceSource = "legal-expert-ai/marketplace"
$PluginSelector = "legal-expert@legal-expert"
$LogPath = Join-Path $InstallRoot "installer.log"

function Write-InstallerLog {
    param([string]$Message)

    $line = "{0:u} {1}" -f (Get-Date), $Message
    Write-Host $Message
    Add-Content -LiteralPath $LogPath -Value $line -Encoding UTF8
}

function Add-ToUserPath {
    param([Parameter(Mandatory = $true)][string]$Directory)

    $currentProcessEntries = @($env:Path -split ";" | Where-Object { $_ })
    if (-not ($currentProcessEntries | Where-Object { $_.TrimEnd("\") -ieq $Directory.TrimEnd("\") })) {
        $env:Path = "$Directory;$env:Path"
    }

    if ($TestMode) {
        return
    }

    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    $userEntries = @($userPath -split ";" | Where-Object { $_ })
    if ($userEntries | Where-Object { $_.TrimEnd("\") -ieq $Directory.TrimEnd("\") }) {
        return
    }

    $newUserPath = if ([string]::IsNullOrWhiteSpace($userPath)) {
        $Directory
    } else {
        "$userPath;$Directory"
    }
    [Environment]::SetEnvironmentVariable("Path", $newUserPath, "User")
}

function Get-PortableGitPackage {
    $architecture = if ($env:PROCESSOR_ARCHITEW6432) {
        $env:PROCESSOR_ARCHITEW6432
    } else {
        $env:PROCESSOR_ARCHITECTURE
    }

    if ($architecture -match "ARM64") {
        return @{
            Version = "2.55.0.4"
            Url = "https://github.com/git-for-windows/git/releases/download/v2.55.0.windows.4/MinGit-2.55.0.4-arm64.zip"
            Sha256 = "033eb6b927d804558ae479a6ae6c6ed86da42cabc0d424844a3e108c780a58cc"
        }
    }

    return @{
        Version = "2.55.0.4"
        Url = "https://github.com/git-for-windows/git/releases/download/v2.55.0.windows.4/MinGit-2.55.0.4-64-bit.zip"
        Sha256 = "4e03f94c2ffbf70be337e005cee02661c732dbfc81031a078bda9299b9a7d644"
    }
}

function Install-PortableGit {
    $package = Get-PortableGitPackage
    $gitRoot = Join-Path $InstallRoot ("Git-{0}" -f $package.Version)
    $gitExecutable = Join-Path $gitRoot "cmd\git.exe"
    if (Test-Path -LiteralPath $gitExecutable -PathType Leaf) {
        Add-ToUserPath -Directory (Split-Path -Parent $gitExecutable)
        return $gitExecutable
    }

    if ($TestMode) {
        throw "Git is required for the installer smoke test."
    }

    Write-InstallerLog "Instalez componenta Git portabila pentru Legal Expert..."
    $downloadRoot = Join-Path $env:TEMP ("legal-expert-{0}" -f [Guid]::NewGuid().ToString("N"))
    $archivePath = Join-Path $downloadRoot "mingit.zip"
    $stagingRoot = Join-Path $downloadRoot "expanded"
    New-Item -ItemType Directory -Path $downloadRoot -Force | Out-Null
    New-Item -ItemType Directory -Path $stagingRoot -Force | Out-Null

    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -Uri $package.Url -OutFile $archivePath -UseBasicParsing -Headers @{
            "User-Agent" = "LegalExpertInstaller/$InstallerVersion"
        }

        $actualHash = (Get-FileHash -LiteralPath $archivePath -Algorithm SHA256).Hash.ToLowerInvariant()
        if ($actualHash -ne $package.Sha256) {
            throw "The Git package checksum is invalid."
        }

        Expand-Archive -LiteralPath $archivePath -DestinationPath $stagingRoot -Force
        $stagedGit = Join-Path $stagingRoot "cmd\git.exe"
        if (-not (Test-Path -LiteralPath $stagedGit -PathType Leaf)) {
            throw "The Git package does not contain cmd\git.exe."
        }

        New-Item -ItemType Directory -Path (Split-Path -Parent $gitRoot) -Force | Out-Null
        Move-Item -LiteralPath $stagingRoot -Destination $gitRoot
    } finally {
        if (Test-Path -LiteralPath $downloadRoot) {
            Remove-Item -LiteralPath $downloadRoot -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    Add-ToUserPath -Directory (Split-Path -Parent $gitExecutable)
    return $gitExecutable
}

function Resolve-GitExecutable {
    $command = Get-Command git.exe -ErrorAction SilentlyContinue
    if ($command) {
        return $command.Source
    }

    $knownCandidates = @()
    if ($env:ProgramFiles) {
        $knownCandidates += Join-Path $env:ProgramFiles "Git\cmd\git.exe"
    }
    if (${env:ProgramFiles(x86)}) {
        $knownCandidates += Join-Path ${env:ProgramFiles(x86)} "Git\cmd\git.exe"
    }
    if ($env:LOCALAPPDATA) {
        $knownCandidates += Join-Path $env:LOCALAPPDATA "Programs\Git\cmd\git.exe"
    }

    foreach ($candidate in $knownCandidates) {
        if (Test-Path -LiteralPath $candidate -PathType Leaf) {
            Add-ToUserPath -Directory (Split-Path -Parent $candidate)
            return $candidate
        }
    }

    return Install-PortableGit
}

function Resolve-CodexExecutable {
    if ($env:CODEX_EXE -and (Test-Path -LiteralPath $env:CODEX_EXE -PathType Leaf)) {
        return $env:CODEX_EXE
    }

    foreach ($commandName in @("codex.exe", "codex")) {
        $command = Get-Command $commandName -ErrorAction SilentlyContinue
        if ($command) {
            return $command.Source
        }
    }

    $candidatePaths = @(
        (Join-Path $env:USERPROFILE ".codex\plugins\.plugin-appserver\codex.exe"),
        (Join-Path $env:USERPROFILE ".codex\plugins\.plugin-appserver\codex")
    )
    foreach ($candidate in $candidatePaths) {
        if (Test-Path -LiteralPath $candidate -PathType Leaf) {
            return $candidate
        }
    }

    $appServerRoot = Join-Path $env:USERPROFILE ".codex\plugins\.plugin-appserver"
    if (Test-Path -LiteralPath $appServerRoot -PathType Container) {
        $discovered = Get-ChildItem -LiteralPath $appServerRoot -Filter "codex*.exe" -File -Recurse -ErrorAction SilentlyContinue |
            Select-Object -First 1
        if ($discovered) {
            return $discovered.FullName
        }
    }

    throw "Nu am gasit runtime-ul Codex. Deschideti ChatGPT o data, apoi rulati din nou installerul Legal Expert."
}

function Invoke-CodexCommand {
    param(
        [Parameter(Mandatory = $true)][string]$CodexExecutable,
        [Parameter(Mandatory = $true)][string[]]$Arguments
    )

    Write-InstallerLog ("Codex: {0}" -f ($Arguments -join " "))
    $output = & $CodexExecutable @Arguments 2>&1
    $exitCode = $LASTEXITCODE
    foreach ($line in @($output)) {
        Write-InstallerLog ([string]$line)
    }
    if ($exitCode -ne 0) {
        throw "Codex command failed with exit code $exitCode."
    }

    return (@($output) -join [Environment]::NewLine)
}

function Install-LegalExpertPlugin {
    param([Parameter(Mandatory = $true)][string]$CodexExecutable)

    $marketplaceJson = Invoke-CodexCommand -CodexExecutable $CodexExecutable -Arguments @(
        "plugin", "marketplace", "list", "--json"
    )
    $marketplaces = $marketplaceJson | ConvertFrom-Json
    $isConfigured = @($marketplaces.marketplaces | Where-Object { $_.name -eq $MarketplaceName }).Count -gt 0

    if ($isConfigured) {
        Invoke-CodexCommand -CodexExecutable $CodexExecutable -Arguments @(
            "plugin", "marketplace", "upgrade", $MarketplaceName
        ) | Out-Null
    } else {
        Invoke-CodexCommand -CodexExecutable $CodexExecutable -Arguments @(
            "plugin", "marketplace", "add", $MarketplaceSource, "--ref", "stable"
        ) | Out-Null
    }

    Invoke-CodexCommand -CodexExecutable $CodexExecutable -Arguments @(
        "plugin", "add", $PluginSelector
    ) | Out-Null
}

try {
    New-Item -ItemType Directory -Path $InstallRoot -Force | Out-Null
    Add-Content -LiteralPath $LogPath -Value "" -Encoding UTF8
    Write-InstallerLog "Legal Expert Setup $InstallerVersion"

    $gitExecutable = Resolve-GitExecutable
    Write-InstallerLog "Git disponibil: $gitExecutable"

    $codexExecutable = Resolve-CodexExecutable
    Write-InstallerLog "Runtime Codex disponibil."
    Install-LegalExpertPlugin -CodexExecutable $codexExecutable

    Set-Content -LiteralPath (Join-Path $InstallRoot "install-complete.txt") -Value (Get-Date).ToString("O") -Encoding UTF8
    Write-InstallerLog "Legal Expert a fost instalat. Inchideti si redeschideti ChatGPT."
    exit 0
} catch {
    Write-InstallerLog ("EROARE: {0}" -f $_.Exception.Message)
    exit 1
}
