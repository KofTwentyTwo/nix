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
