# Generator: parse the enabled oh-my-zsh plugin files + James's shellAliases and
# emit windows/ps-aliases.ps1 (PowerShell functions mirroring the zsh aliases).
#
# Reproducible: run this after `nix flake update` bumps oh-my-zsh, or after
# editing home/ohmyzsh plugins / home/zsh shellAliases. It copies the enabled
# plugin files out of the WSL nix store itself, regenerates, and refuses to
# write a file that doesn't parse. Then commit windows/ps-aliases.ps1.
#
#   pwsh -File windows\gen-ps-aliases.ps1
param(
  [string]$PluginDir = "$env:TEMP\omz-plugins",
  [string]$OutFile   = "$PSScriptRoot\ps-aliases.ps1"
)
$ErrorActionPreference = 'Stop'

# Pull the enabled plugin files from the WSL nix store (keep this list in sync
# with home/ohmyzsh/default.nix `plugins`). aws/sudo/extract/aliases add no
# command aliases we port here.
$enabledPlugins = @('git','kubectl','docker','helm','terraform','aws')
New-Item -ItemType Directory -Force $PluginDir | Out-Null
$plugList = $enabledPlugins -join ' '
$pluginDirWsl = "/mnt/" + $PluginDir.Substring(0,1).ToLower() + ($PluginDir.Substring(2) -replace '\\','/')
$bash = "omz=`$(dirname `$(dirname `$(find /nix/store -maxdepth 6 -name 'git.plugin.zsh' 2>/dev/null | head -1))); for p in $plugList; do cp `"`$omz/`$p/`$p.plugin.zsh`" `"$pluginDirWsl/`$p.zsh`" 2>/dev/null; done"
wsl.exe -d Ubuntu -e bash -lc $bash 2>$null
if (-not (Get-ChildItem $PluginDir -Filter *.zsh -ErrorAction SilentlyContinue)) {
  throw "could not copy omz plugin files from WSL nix store into $PluginDir"
}

# Names to skip: shell-pipeline / subshell / omz-function / gitk / svn oddities
# that don't translate cleanly to PowerShell.
$deny = @(
  'ggpur','glp','gstu','gtl','gk','gke','gwip','gunwip','gpristine','gwipe',
  'gbgd','gbgD','gbg','gignored','gfg','gdct','git-svn-dcommit-push','gsd','gsr',
  'gg','gga','gtv','gclean','gam','gama','gamc','gamscp','gams'
) | ForEach-Object { $_.ToLower() } | Sort-Object -Unique

# Branch-helper subshell -> PowerShell subexpression
function Convert-BranchHelpers([string]$v) {
  $v = $v -replace '\$\(git_current_branch\)', '$(Get-GitCurrentBranch)'
  $v = $v -replace '\$\(git_main_branch\)',    '$(Get-GitMainBranch)'
  $v = $v -replace '\$\(git_develop_branch\)', '$(Get-GitDevelopBranch)'
  return $v
}

# After branch substitution, reject anything still shell-specific.
function Is-Portable([string]$v) {
  # allow our known-good branch-helper subexpressions, then reject any OTHER subshell
  $probe = $v -replace '\$\(Get-Git(Current|Main|Develop)Branch\)', ''
  if ($probe -match '\$\(' ) { return $false }     # leftover (non-helper) subshell
  if ($v -match '[|;`]') { return $false }         # pipe / sequence / backtick
  if ($v -match '&&|&!|>>|>') { return $false }    # chaining / redirect / bg
  if ($v -match '\(\)\s*\{') { return $false }     # function def
  if ($v -match 'noglob|LANG=C') { return $false }
  if ($v -match '^\\') { return $false }           # \gitk
  return $true
}

$parsed = [ordered]@{}   # name(lower) -> @{ Name=orig; Val=; Src= }
$seenCase = @{}          # lowername -> original name (case-collision guard)

foreach ($f in Get-ChildItem $PluginDir -Filter *.zsh) {
  $plugin = $f.BaseName
  foreach ($line in Get-Content $f.FullName) {
    if ($line -notmatch "^\s*alias\s+([A-Za-z0-9_.\-]+)=(.*)$") { continue }
    $name = $Matches[1]; $rhs = $Matches[2].Trim()
    # strip one matching outer quote pair
    if ($rhs.Length -ge 2 -and $rhs[0] -eq "'" -and $rhs[-1] -eq "'") { $val = $rhs.Substring(1, $rhs.Length-2) }
    elseif ($rhs.Length -ge 2 -and $rhs[0] -eq '"' -and $rhs[-1] -eq '"') { $val = $rhs.Substring(1, $rhs.Length-2) }
    else { $val = $rhs }
    $lower = $name.ToLower()
    if ($deny -contains $lower) { continue }
    $val = Convert-BranchHelpers $val
    if (-not (Is-Portable $val)) { continue }
    # case-insensitive collision: PowerShell can't distinguish gcb/gcB — keep first
    if ($seenCase.ContainsKey($lower)) { continue }
    $seenCase[$lower] = $name
    $parsed[$name] = @{ Name = $name; Val = $val; Src = $plugin }
  }
}

# James's shellAliases that override omz or add value. .sh scripts run via WSL
# with the current dir translated (wslpath) so multi-repo helpers work from any
# Windows path. Format: name => @{ type; val }.
#   git       = literal git command (overrides omz)
#   wsl       = a ~/.local/bin script run in WSL at the translated cwd
#   toolcmd   = a modern-CLI replacement, only defined if the tool is on PATH
$shellAliases = [ordered]@{
  # git overrides / additions
  gc    = @{ type='git';  val='git cz c' }                 # commitizen (overrides omz gc)
  # multi-repo + helper scripts (bash, via WSL)
  gt    = @{ type='wsl';  val='gitops-publish.sh' }
  gsa   = @{ type='wsl';  val='git-sync-all.sh' }
  gsall = @{ type='wsl';  val='git-status-all.sh' }
  gclo  = @{ type='wsl';  val='git-clone-all.sh' }
  gfa   = @{ type='wsl';  val='git-fetch-all.sh' }
  gpa   = @{ type='wsl';  val='git-pull-all.sh' }
  gba   = @{ type='wsl';  val='git-branch-all.sh' }        # overrides omz gba
  gcoa  = @{ type='wsl';  val='git-checkout-all.sh' }
  gla   = @{ type='wsl';  val='git-log-all.sh' }
  gi    = @{ type='wsl';  val='git-info.sh' }
  ghelp = @{ type='wsl';  val='git-help.sh' }
  # general shortcuts
  tl    = @{ type='raw';  val='task --list-all' }
  t     = @{ type='raw';  val='task' }
  h     = @{ type='raw';  val='helm' }
  v     = @{ type='raw';  val='velero' }
  # modern CLI replacements (guarded by tool presence)
  cat   = @{ type='tool'; val='bat' }
  ll    = @{ type='tool'; val='eza -l' }
  la    = @{ type='tool'; val='eza -la' }
  tree  = @{ type='tool'; val='eza --tree' }
  du    = @{ type='tool'; val='dust' }
  grep  = @{ type='tool'; val='rg' }
  cloc  = @{ type='tool'; val='tokei' }
}

$sb = [System.Text.StringBuilder]::new()
[void]$sb.AppendLine("# ps-aliases.ps1 - PowerShell port of James's zsh aliases (git + k8s + docker +")
[void]$sb.AppendLine("# helm + terraform + shellAliases). GENERATED by windows/ (see nix repo). Do not")
[void]$sb.AppendLine("# hand-edit; regenerate from the omz plugin files + home/zsh shellAliases.")
[void]$sb.AppendLine("# Dot-sourced from `$PROFILE via windows/profile.ps1.")
[void]$sb.AppendLine("#")
[void]$sb.AppendLine("# PowerShell aliases outrank functions in resolution, so we remove any built-in")
[void]$sb.AppendLine("# alias that collides (gc/gp/gl/gm/gi/...) — the full cmdlets (Get-Content etc.)")
[void]$sb.AppendLine("# remain available by their real names. PowerShell is case-insensitive, so")
[void]$sb.AppendLine("# case-only variants (gcB, gbD) are not distinct — use the git flag directly.")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("# --- omz branch helpers (git_current_branch / git_main_branch / git_develop_branch) ---")
[void]$sb.AppendLine("function Get-GitCurrentBranch { (git symbolic-ref --quiet --short HEAD 2>`$null) }")
[void]$sb.AppendLine("function Get-GitMainBranch {")
[void]$sb.AppendLine("  foreach (`$r in 'origin/main','origin/trunk','origin/master') {")
[void]$sb.AppendLine("    git show-ref -q --verify `"refs/remotes/`$r`" 2>`$null; if (`$?) { return (`$r -replace '^origin/','') }")
[void]$sb.AppendLine("  }")
[void]$sb.AppendLine("  foreach (`$b in 'main','trunk','master') { git show-ref -q --verify `"refs/heads/`$b`" 2>`$null; if (`$?) { return `$b } }")
[void]$sb.AppendLine("  return 'main'")
[void]$sb.AppendLine("}")
[void]$sb.AppendLine("function Get-GitDevelopBranch {")
[void]$sb.AppendLine("  foreach (`$b in 'develop','devel','dev','development') { git show-ref -q --verify `"refs/heads/`$b`" 2>`$null; if (`$?) { return `$b } }")
[void]$sb.AppendLine("  return 'develop'")
[void]$sb.AppendLine("}")
[void]$sb.AppendLine("")

# collision-removal preamble over all names we define
$allNames = @($parsed.Keys) + @($shellAliases.Keys) | ForEach-Object { $_.ToLower() } | Sort-Object -Unique
[void]$sb.AppendLine("# Remove colliding built-in aliases so our functions win.")
[void]$sb.AppendLine("foreach (`$n in @('$([string]::Join("','", $allNames))')) { if (Test-Path `"Alias:`$n`") { Remove-Item `"Alias:`$n`" -Force -ErrorAction SilentlyContinue } }")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("# --- plugin aliases (git / kubectl / docker / helm / terraform / aws) ---")

# shellAliases override plugin aliases of the same name (zsh semantics) — skip
# the plugin definition so the shellAlias one below is authoritative.
$overridden = @($shellAliases.Keys) | ForEach-Object { $_.ToLower() }
foreach ($k in $parsed.Keys) {
  if ($overridden -contains $k.ToLower()) { continue }
  $e = $parsed[$k]
  # git's @{upstream}/@{push} revsyntax collides with PowerShell's @{} hash
  # literal — single-quote those tokens so they pass through to git literally.
  $val = [regex]::Replace($e.Val, '@\{[^}]*\}', { "'" + $args[0].Value + "'" })
  [void]$sb.AppendLine("function $($e.Name) { $val @args }")
}

[void]$sb.AppendLine("")
[void]$sb.AppendLine("# --- shellAliases (home/zsh) ---")
foreach ($k in $shellAliases.Keys) {
  $e = $shellAliases[$k]
  switch ($e.type) {
    'git'  { [void]$sb.AppendLine("function $k { $($e.val) @args }") }
    'raw'  { [void]$sb.AppendLine("function $k { $($e.val) @args }") }
    'tool' {
      $bin = ($e.val -split ' ')[0]
      [void]$sb.AppendLine("if (Get-Command $bin -ErrorAction SilentlyContinue) { function $k { $($e.val) @args } }")
    }
    'wsl'  {
      # run the bash helper in WSL at the current dir (translated via wslpath)
      [void]$sb.AppendLine("function $k { `$p = (wsl.exe wslpath -a `"`$((Get-Location).Path)`"); wsl.exe -d Ubuntu -e bash -lc `"cd '`$p' && $($e.val) `$(`$args -join ' ')`" }")
    }
  }
}

$dir = Split-Path -Parent $OutFile
if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force $dir | Out-Null }
Set-Content -Path $OutFile -Value $sb.ToString() -Encoding UTF8 -NoNewline

# Parse-validation gate: a single bad line breaks the whole dot-source, so
# refuse to ship a file that doesn't parse.
$errors = $null
[System.Management.Automation.Language.Parser]::ParseFile($OutFile, [ref]$null, [ref]$errors) | Out-Null
if ($errors -and $errors.Count) {
  Write-Host "PARSE ERRORS ($($errors.Count)):" -ForegroundColor Red
  $errors | Select-Object -First 10 | ForEach-Object { "  line $($_.Extent.StartLineNumber): $($_.Message)" }
  throw "ps-aliases.ps1 has parse errors — not safe to ship"
}
"generated + parse-clean: $OutFile"
"plugin functions: $($parsed.Count)  | shellAlias functions: $($shellAliases.Count)  | total names: $($allNames.Count)"