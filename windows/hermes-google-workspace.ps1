[CmdletBinding()]
param(
    [ValidateSet('Status', 'InstallDeps', 'ClientSecret', 'AuthUrl', 'AuthCode', 'Revoke')]
    [string]$Action = 'Status',
    [string]$Value
)

$ErrorActionPreference = 'Stop'
$hermesHome = Join-Path $env:LOCALAPPDATA 'hermes'
$setup = Join-Path $hermesHome 'hermes-agent\skills\productivity\google-workspace\scripts\setup.py'
$python = Join-Path $hermesHome 'hermes-agent\venv\Scripts\python.exe'

if (-not (Test-Path $setup) -or -not (Test-Path $python)) {
    throw 'Hermes Google Workspace skill is not installed. Run windows\apply.ps1 first.'
}

switch ($Action) {
    'Status'      { & $python $setup --check }
    'InstallDeps' { & $python $setup --install-deps }
    'ClientSecret' {
        if (-not $Value) { throw 'ClientSecret requires -Value <downloaded-json-path>.' }
        & $python $setup --client-secret $Value
    }
    'AuthUrl'     { & $python $setup --auth-url }
    'AuthCode' {
        if (-not $Value) { throw 'AuthCode requires -Value <redirect-url-or-code>.' }
        & $python $setup --auth-code $Value
    }
    'Revoke'      { & $python $setup --revoke }
}

if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$identity = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
foreach ($file in @('google_client_secret.json', 'google_token.json')) {
    $path = Join-Path $hermesHome $file
    if (Test-Path $path) {
        & icacls $path '/inheritance:r' '/grant:r' "${identity}:(F)" | Out-Null
    }
}
