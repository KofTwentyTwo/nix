# PowerShell helpers for the nix repo — dot-sourced from $PROFILE
# (the dot-source line is maintained idempotently by windows/apply.ps1).
#
# `switch` is a PowerShell reserved keyword (like `if`/`for`) — typing it
# alone opens a `>>` continuation prompt and it can NEVER be a command name.
# `sw` is the Windows-side equivalent.

function sw {
    <# Run the WSL home-manager switch (same as typing `switch` in Ubuntu). #>
    wsl.exe -d Ubuntu -- /home/james/.nix-profile/bin/zsh -ilc switch
}

function swin {
    <# Apply the Windows-side tooling manifests (winget/scoop/VS). #>
    & 'R:\Git.Local\KofTwentyTwo\nix\windows\apply.ps1' @args
}

function Clear-StaleMcpRemote {
    <#
    Reap leftover `mcp-remote` node processes from previous agent sessions.
    agy/gemini spawn MCP servers as child processes but don't always reap them
    on exit; the stragglers keep holding mcp-remote's fixed OAuth callback port
    (atlassian's is 39570), so the NEXT session's atlassian hangs "still
    connecting" — which makes agy withhold its whole tool list (github etc.
    then look "not listed"). Targets ONLY node processes whose command line
    contains mcp-remote, so real dev servers are untouched.
    #>
    Get-CimInstance Win32_Process -Filter "Name='node.exe'" -ErrorAction SilentlyContinue |
        Where-Object { $_.CommandLine -match 'mcp-remote' } |
        ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
}

function agy {
    <# Launch antigravity, first reaping stale mcp-remote so atlassian (and
       therefore the whole MCP tool list) connects instead of hanging. #>
    Clear-StaleMcpRemote
    & "$env:USERPROFILE\scoop\shims\agy.exe" @args
}

# Muscle-memory shim: a line consisting of exactly `switch` is rewritten to
# `sw` at Enter, instead of opening the switch-statement continuation prompt.
# Real switch statements (anything beyond the bare word) are untouched.
try {
    Set-PSReadLineKeyHandler -Key Enter -BriefDescription 'AcceptLine+SwitchShim' -ScriptBlock {
        $line = $null; $cursor = $null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
        if ($line.Trim() -eq 'switch') {
            [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
            [Microsoft.PowerShell.PSConsoleReadLine]::Insert('sw')
        }
        [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
    }
} catch { }  # PSReadLine absent (non-interactive host) — shim not needed there

# zsh alias parity: git/kubectl/docker/helm/terraform + shellAliases as
# PowerShell functions (generated — see windows/ps-aliases.ps1 header).
$psAliases = Join-Path $PSScriptRoot 'ps-aliases.ps1'
if (Test-Path $psAliases) { . $psAliases }
