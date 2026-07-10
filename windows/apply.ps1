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

# ----------------------------------------------------- PowerShell profile hook
# Ensure $PROFILE dot-sources windows/profile.ps1 (gives `sw` = WSL switch,
# `swin` = this script). Marker-based and idempotent.
$profilePath = $PROFILE.CurrentUserAllHosts
$sourceLine = ". '$(Join-Path $repoWin 'profile.ps1')'  # nix-repo helpers"
if (-not (Test-Path $profilePath)) {
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

# ---------------------------------------------------------------- scoop apps
$scoopManifest = Get-Content (Join-Path $repoWin 'scoop.json') -Raw | ConvertFrom-Json

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

Info "done"
