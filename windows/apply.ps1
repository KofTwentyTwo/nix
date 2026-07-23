# windows/apply.ps1 -- the Windows analog of `switch`.
#
# Declarative-ish package management for Windows machines in this repo:
#   - winget.json  : GUI/heavy apps (JetBrains Toolbox, Node LTS, Visual Studio 2026)
#   - scoop.json   : CLI tools (mirrors the homebrew/linux-cli curated set)
#   - vs2026.vsconfig : Visual Studio workloads/components
#
# Idempotent: installed packages are skipped. Run again after editing a manifest.
#
# Usage:
#   .\apply.ps1                          # install anything missing (VS uses edition from winget.json)
#   .\apply.ps1 -SkipVS                  # everything except Visual Studio
#   .\apply.ps1 -VSEdition Professional  # override the VS edition for this run
#   .\apply.ps1 -Upgrade                 # also upgrade everything already installed
#
# Notes:
#   - JetBrains IDEs themselves are managed by Toolbox (installs/updates/licenses),
#     not winget. This script only guarantees Toolbox is present.
#   - Changing vs2026.vsconfig after VS is installed: this script detects VS and
#     re-applies the config via the VS Installer (setup.exe modify).

[CmdletBinding()]
param(
    [switch]$SkipVS,
    [ValidateSet('Community', 'Professional', 'Enterprise')]
    [string]$VSEdition,
    [switch]$Upgrade
)

$ErrorActionPreference = 'Stop'
$repoWin = Split-Path -Parent $PSCommandPath

function Info($msg)  { Write-Host "==> $msg" -ForegroundColor Cyan }
function Ok($msg)    { Write-Host "    $msg" -ForegroundColor Green }
function Warn2($msg) { Write-Host "    $msg" -ForegroundColor Yellow }

function Test-WingetInstalled([string]$Id) {
    winget list --id $Id -e --accept-source-agreements *> $null
    return ($LASTEXITCODE -eq 0)
}

function Refresh-ProcessPath {
    $machinePath = [Environment]::GetEnvironmentVariable('Path', 'Machine')
    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    $env:Path = "$machinePath;$userPath"
}

# ----------------------------------------------------- PowerShell profile hook
# Ensure $PROFILE dot-sources windows/profile.ps1 (gives `sw` = WSL switch,
# `swin` = this script). Marker-based and idempotent.
$profilePath = $PROFILE.CurrentUserAllHosts
$sourceLine = ". '$(Join-Path $repoWin 'profile.ps1')'  # nix-repo helpers"
if (-not (Test-Path $profilePath)) {
    New-Item -ItemType Directory -Force (Split-Path -Parent $profilePath) | Out-Null
    New-Item -ItemType File -Force $profilePath | Out-Null
}
if (-not (Select-String -Path $profilePath -SimpleMatch 'nix-repo helpers' -Quiet)) {
    Add-Content $profilePath "`n$sourceLine"
    Info "PowerShell profile: added nix-repo helpers dot-source"
}

# ---------------------------------------------------------------- winget apps
$wingetManifest = Get-Content (Join-Path $repoWin 'winget.json') -Raw | ConvertFrom-Json

Info "winget packages"
foreach ($pkg in $wingetManifest.packages) {
    if (Test-WingetInstalled $pkg.id) {
        if ($Upgrade) {
            Warn2 "$($pkg.id): upgrading"
            winget upgrade --id $pkg.id -e --accept-package-agreements --accept-source-agreements
        } else {
            Ok "$($pkg.id): already installed"
        }
    } else {
        Warn2 "$($pkg.id): installing"
        winget install --id $pkg.id -e --accept-package-agreements --accept-source-agreements
        if ($LASTEXITCODE -ne 0) { Warn2 "$($pkg.id): install exited $LASTEXITCODE" }
    }
}
Refresh-ProcessPath

# ---------------------------------------------------------------- scoop apps
$scoopManifest = Get-Content (Join-Path $repoWin 'scoop.json') -Raw | ConvertFrom-Json

if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
    Info "Scoop"
    Warn2 "bootstrapping Scoop for the current user"
    Invoke-RestMethod 'https://get.scoop.sh' | Invoke-Expression
    Refresh-ProcessPath
}

Info "scoop buckets"
$haveBuckets = @(scoop bucket list 6>$null | ForEach-Object { $_.Name })
foreach ($bucket in $scoopManifest.buckets.PSObject.Properties) {
    if ($haveBuckets -contains $bucket.Name) {
        Ok "$($bucket.Name): present"
    } else {
        Warn2 "$($bucket.Name): adding"
        if ($bucket.Value) { scoop bucket add $bucket.Name $bucket.Value } else { scoop bucket add $bucket.Name }
    }
}

Info "scoop apps"
$haveApps = @(scoop list 6>$null | ForEach-Object { $_.Name })
foreach ($app in $scoopManifest.apps) {
    $name = ($app -split '/')[-1]
    if ($haveApps -contains $name) {
        Ok "${app}: already installed"
    } else {
        Warn2 "${app}: installing"
        scoop install $app
    }
}
if ($Upgrade) {
    Info "scoop update"
    scoop update *
}

# ------------------------------------------------------------- rust toolchain
# scoop's rustup package installs only the MANAGER (no toolchain: `rustup show`
# says "no active toolchain" on a fresh install). Mirror home/rust (macOS) and
# home/linux-cli (WSL): default to stable and add the standard components.
# rust-analyzer/rustfmt/clippy must come from rustup (its PATH proxies shadow
# any other copy). The MSVC linker + Windows SDK come from vs2026.vsconfig
# (VC.Tools.x86.x64 + Windows11SDK — explicit, NOT implied by NativeDesktop).
Refresh-ProcessPath
Info "rust toolchain (rustup)"
if (Get-Command rustup -ErrorAction SilentlyContinue) {
    & rustup show active-toolchain 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Ok "default toolchain present: $(& rustup show active-toolchain 2>$null)"
        if ($Upgrade) { rustup update stable }
    } else {
        Warn2 "no default toolchain; installing stable"
        rustup default stable
        if ($LASTEXITCODE -ne 0) { Warn2 "rustup default stable exited $LASTEXITCODE (offline?)" }
    }
    rustup component add rustfmt clippy rust-analyzer 2>$null | Out-Null
    if ($LASTEXITCODE -ne 0) { Warn2 "rustup component add exited $LASTEXITCODE" }
} else {
    Warn2 "rustup not on PATH (scoop install failed?); skipping toolchain setup"
}

# ------------------------------------------------------------------ npm globals
$npmManifest = Get-Content (Join-Path $repoWin 'npm.json') -Raw | ConvertFrom-Json
Info "npm globals"
$npmHave = (npm ls -g --depth=0 --json 2>$null | ConvertFrom-Json).dependencies.PSObject.Properties.Name
foreach ($pkg in $npmManifest.packages) {
    if ($npmHave -contains $pkg -and -not $Upgrade) {
        Ok "${pkg}: already installed"
    } else {
        Warn2 "${pkg}: installing/updating"
        npm install -g "$pkg@latest" | Out-Null
        if ($LASTEXITCODE -ne 0) { Warn2 "${pkg}: npm install exited $LASTEXITCODE" }
    }
}

# ---------------------------------------------------------- Visual Studio 2026
if (-not $SkipVS) {
    $edition  = if ($VSEdition) { $VSEdition } else { $wingetManifest.visualStudio.edition }
    $vsId     = "Microsoft.VisualStudio.$edition"
    $vsconfig = Join-Path $repoWin $wingetManifest.visualStudio.vsconfig

    Info "Visual Studio 2026 ($edition)"
    $installedEdition = @(@('Community', 'Professional', 'Enterprise') |
        Where-Object { Test-WingetInstalled "Microsoft.VisualStudio.$_" })

    if ($installedEdition) {
        Ok "Microsoft.VisualStudio.$($installedEdition[0]): already installed"
        # Re-apply the vsconfig so manifest edits land on existing installs.
        $vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
        $setup   = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\setup.exe"
        if ((Test-Path $vswhere) -and (Test-Path $setup)) {
            $installPath = & $vswhere -latest -products * -property installationPath
            if ($installPath) {
                # setup.exe needs elevation; launch with an explicit UAC prompt
                # and wait, otherwise it dies silently with nothing in the logs.
                Warn2 "applying $($wingetManifest.visualStudio.vsconfig) via VS Installer (passive; expect a UAC prompt)"
                $p = Start-Process $setup -ArgumentList @(
                    'modify', '--installPath', "`"$installPath`"",
                    '--config', "`"$vsconfig`"", '--passive', '--norestart'
                ) -Verb RunAs -PassThru -Wait
                if ($p.ExitCode -notin 0, 3010) {
                    Warn2 "VS Installer modify exited $($p.ExitCode)"
                } elseif ($p.ExitCode -eq 3010) {
                    Warn2 "VS modify succeeded; reboot required"
                }
            }
        } else {
            Warn2 "VS Installer not found; apply $vsconfig manually via Tools > Get Tools and Features"
        }
    } else {
        Warn2 "$vsId`: installing with $($wingetManifest.visualStudio.vsconfig) (this is a large download)"
        winget install --id $vsId -e --accept-package-agreements --accept-source-agreements `
            --override "--passive --norestart --includeRecommended --config `"$vsconfig`""
        if ($LASTEXITCODE -ne 0) { Warn2 "$vsId`: install exited $LASTEXITCODE" }
    }
} else {
    Info "Visual Studio: skipped (-SkipVS)"
}

# --------------------------------------------------------------------- Hermes
# Native Windows and WSL use the same tracked policy, identity, and Second
# Brain skills. Credentials remain machine-local and arrive through the WSL
# Home Manager secret bridge.
$repoRoot = Split-Path -Parent $repoWin
$hermesSource = Join-Path $repoRoot 'home\hermes'
$aiSource = Join-Path $repoRoot 'home\ai'
$secondBrainSource = Join-Path $repoRoot 'home\secondbrain\skills'
$hermesHome = Join-Path $env:LOCALAPPDATA 'hermes'
$hermesManaged = Join-Path $hermesHome 'managed'
$hermesInstall = Join-Path $hermesHome 'hermes-agent'
$hermesRevision = '46e87b14fd6c943ef0d6671fb0d74c5dde5d4c6b'

Info "Hermes Agent"
$installedRevision = if (Test-Path (Join-Path $hermesInstall '.git')) {
    (& git -C $hermesInstall rev-parse HEAD 2>$null | Out-String).Trim()
} else {
    ''
}

if ($installedRevision -ne $hermesRevision) {
    Warn2 "converging native Hermes Agent to reviewed revision"
    $installer = Join-Path $env:TEMP 'hermes-install.ps1'
    Invoke-WebRequest "https://raw.githubusercontent.com/NousResearch/hermes-agent/$hermesRevision/scripts/install.ps1" -OutFile $installer
    & pwsh -NoProfile -File $installer -SkipSetup -NonInteractive -Commit $hermesRevision
    if ($LASTEXITCODE -ne 0) { throw "Hermes installer exited $LASTEXITCODE" }

    $installedRevision = (& git -C $hermesInstall rev-parse HEAD 2>$null | Out-String).Trim()
    if ($installedRevision -ne $hermesRevision) {
        throw "Hermes checkout is $installedRevision; expected $hermesRevision"
    }
} else {
    Ok "native Hermes Agent: reviewed revision already installed"
}

New-Item -ItemType Directory -Force $hermesManaged | Out-Null
Copy-Item (Join-Path $hermesSource 'managed-config.yaml') (Join-Path $hermesManaged 'config.yaml') -Force
Copy-Item (Join-Path $hermesSource 'SOUL.md') (Join-Path $hermesHome 'SOUL.md') -Force

$managedEnv = Join-Path $hermesManaged '.env'
if (-not (Test-Path $managedEnv)) { New-Item -ItemType File -Force $managedEnv | Out-Null }
$managedLines = @(Get-Content $managedEnv | Where-Object { $_ -notmatch '^SLACK_ALLOWED_USERS=' })
$managedLines += 'SLACK_ALLOWED_USERS=U0A31489THN'
[System.IO.File]::WriteAllLines($managedEnv, $managedLines, [System.Text.UTF8Encoding]::new($false))
$identity = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
& icacls $managedEnv '/inheritance:r' '/grant:r' "${identity}:(F)" | Out-Null

$managedValues = @{}
foreach ($line in Get-Content $managedEnv) {
    if ($line -match '^([^#=]+)=(.*)$') { $managedValues[$Matches[1]] = $Matches[2] }
}
foreach ($name in @('CIRCLECI_TOKEN', 'CIRCLECI_CLI_TOKEN', 'FIRECRAWL_API_KEY', 'OPENROUTER_API_KEY')) {
    $value = if ($managedValues.ContainsKey($name)) { $managedValues[$name] } else { $null }
    [Environment]::SetEnvironmentVariable($name, $value, 'User')
    Set-Item -Path "Env:$name" -Value $value -ErrorAction SilentlyContinue
}

$aiTarget = Join-Path $env:USERPROFILE '.ai'
New-Item -ItemType Directory -Force $aiTarget | Out-Null
foreach ($file in @('0-init.md', '1-profile.md', '2-coding-style.md', '3-rules.md', '4-preferences.yaml', '5-learnings.md')) {
    Copy-Item (Join-Path $aiSource $file) (Join-Path $aiTarget $file) -Force
}

foreach ($file in @('google_client_secret.json', 'google_token.json', 'google_oauth_pending.json')) {
    $path = Join-Path $hermesHome $file
    if (Test-Path $path) {
        & icacls $path '/inheritance:r' '/grant:r' "${identity}:(F)" | Out-Null
    }
}

foreach ($skill in @('secondbrain-save', 'secondbrain-consolidate')) {
    $target = Join-Path $hermesHome "skills\secondbrain\$skill"
    New-Item -ItemType Directory -Force $target | Out-Null
    Copy-Item (Join-Path $secondBrainSource "$skill\SKILL.md") (Join-Path $target 'SKILL.md') -Force
}

[Environment]::SetEnvironmentVariable('HERMES_MANAGED_DIR', $hermesManaged, 'User')
$env:HERMES_MANAGED_DIR = $hermesManaged

$secondBrainVault = Join-Path (Split-Path -Parent $repoRoot) 'second-brain'
[Environment]::SetEnvironmentVariable('SECOND_BRAIN_VAULT', $secondBrainVault, 'User')
$env:SECOND_BRAIN_VAULT = $secondBrainVault
Ok "policy, AI context, and Second Brain skills synced"

$hermesCommand = Get-Command hermes -ErrorAction SilentlyContinue
if ($hermesCommand) {
    $computerUseStatus = & hermes computer-use status 2>&1 | Out-String
    if ($computerUseStatus -notmatch '(?m)^cua-driver: installed') {
        Warn2 "installing Hermes computer-use platform driver"
        & hermes computer-use install
        if ($LASTEXITCODE -ne 0) { Warn2 "computer-use install exited $LASTEXITCODE" }
    } else {
        Ok "Hermes computer-use platform driver: already installed"
    }

    $cuaDriver = Get-Command cua-driver -ErrorAction SilentlyContinue
    $cuaDriverPath = if ($cuaDriver) { $cuaDriver.Source } else { $null }
    if (-not $cuaDriverPath) {
        $candidate = Join-Path $env:USERPROFILE '.local\bin\cua-driver.exe'
        if (Test-Path $candidate) { $cuaDriverPath = $candidate }
    }
    if ($cuaDriverPath) {
        & $cuaDriverPath config set capture_scope desktop | Out-Null
        if ($LASTEXITCODE -ne 0) { Warn2 "could not enable cua-driver desktop scope" }
    }

    & hermes slack manifest --write (Join-Path $hermesManaged 'slack-manifest.json') `
        --name 'Hermes' --description "James Maes's primary coding agent" | Out-Null
    if ($LASTEXITCODE -ne 0) { Warn2 "Slack app manifest generation exited $LASTEXITCODE" }

    & hermes gateway stop *> $null
    & hermes gateway uninstall *> $null
    Ok "Hermes Slack gateway ownership: Grogu only; native service removed"
} else {
    Warn2 "Hermes command is not on this process PATH; open a new shell and re-run apply.ps1"
}

Info "done"
