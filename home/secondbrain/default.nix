# Second Brain — Obsidian vault wired into every Claude Code session
# ===================================================================
# Implements docs/PLAN-secondbrain.md (source spec: James's July 2026
# claude-code-secondbrain-requirements). One physical vault per machine:
#
#   macOS : ~/Git.Local/KofTwentyTwo/second-brain   (clone of the private repo)
#   LORE  : R:\Git.Local\KofTwentyTwo\second-brain  == /mnt/r/... in WSL
#
# This module owns: the SECOND_BRAIN_VAULT env var, the SessionStart/SessionEnd
# hook SCRIPTS (fail-safe, always exit 0), shared secondbrain-save /
# secondbrain-consolidate skills, vault bootstrap, the weekly consolidation
# job (systemd user timer / launchd), and the LORE-only bridge that mirrors
# the same behavior into Windows-native Claude Code.
#
# The hook REGISTRATION (settings.json `hooks` + `env`) lives in
# home/claude/default.nix (syncClaudeUserSettings) because that activation
# owns settings.json merging — see the marker-based hook merge there.
{ config, pkgs, lib, machineConfig ? {}, ... }:
let
  homeDir  = config.home.homeDirectory;
  isDarwin = pkgs.stdenv.isDarwin;
  isWsl    = machineConfig.isWsl or false;

  # Per-platform canonical vault path. Keep this in sync with
  # env.SECOND_BRAIN_VAULT in home/claude/default.nix userPrefs.
  vaultPath = if isDarwin
    then "${homeDir}/Git.Local/KofTwentyTwo/second-brain"
    else if isWsl
    then "/mnt/r/Git.Local/KofTwentyTwo/second-brain"
    else "${homeDir}/Git.Local/KofTwentyTwo/second-brain";

  # Private remote. Created lazily — bootstrap clones if reachable, otherwise
  # scaffolds a fresh local-only vault; consolidation pushes only when a
  # remote is actually configured.
  vaultRemote = "https://github.com/KofTwentyTwo/second-brain.git";

  # Windows-native Claude Code (LORE bridge target). Only used on Linux/WSL.
  winClaudeDir = "/mnt/c/Users/james/.claude";
  winVaultPath = "R:\\Git.Local\\KofTwentyTwo\\second-brain";

  sessionStartScript = ''
    #!/usr/bin/env bash
    # SessionStart hook: inject the vault index (+ project note when the cwd
    # maps to one). MUST be fast and fail-safe — never break a session.
    {
      V="''${SECOND_BRAIN_VAULT:-${vaultPath}}"
      if [ -f "$V/index.md" ]; then
        echo "=== Second Brain index ($V/index.md) ==="
        cat "$V/index.md"
        proj=$(git remote get-url origin 2>/dev/null | sed -e 's#\.git$##' -e 's#.*/##')
        [ -n "$proj" ] || proj=$(basename "$PWD")
        if [ -f "$V/projects/$proj.md" ]; then
          echo
          echo "=== Project note: $proj ==="
          cat "$V/projects/$proj.md"
        fi
        echo
        echo "[second-brain] Consult the vault before substantive work; pull specific notes on demand. Record durable outcomes before finishing (secondbrain-save skill)."
      fi
    } 2>/dev/null
    exit 0
  '';

  sessionEndScript = ''
    #!/usr/bin/env bash
    # SessionEnd hook: stub today's daily log with a session line. Content
    # writes (decisions/knowledge/project notes) are the model's job via the
    # secondbrain-save skill — this only guarantees the daily trail exists.
    {
      V="''${SECOND_BRAIN_VAULT:-${vaultPath}}"
      [ -d "$V/daily" ] || exit 0
      d=$(date +%F); t=$(date +%H:%M)
      f="$V/daily/$d.md"
      if [ ! -f "$f" ]; then
        printf -- '---\ncreated: %s\nupdated: %s\ntags: [daily]\nsource: claude-session\n---\n\n# %s\n' "$d" "$d" "$d" > "$f"
      fi
      branch=$(git branch --show-current 2>/dev/null || true)
      printf -- '- %s session ended in `%s`%s\n' "$t" "$PWD" "''${branch:+ (branch \`$branch\`)}" >> "$f"
    } 2>/dev/null
    exit 0
  '';

  # Weekly consolidation: headless claude runs the consolidate skill in the
  # vault, then git records whatever changed. Idempotent — a run with nothing
  # to tidy produces no commit. Push only when a remote exists.
  consolidateScript = pkgs.writeShellScript "secondbrain-consolidate" ''
    set -u
    export PATH="$HOME/.local/bin:$HOME/.nix-profile/bin:/nix/var/nix/profiles/default/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"
    V="''${SECOND_BRAIN_VAULT:-${vaultPath}}"
    [ -d "$V/.git" ] || { echo "[second-brain] no vault git repo at $V; skipping"; exit 0; }
    command -v claude >/dev/null 2>&1 || { echo "[second-brain] claude not on PATH; skipping"; exit 0; }
    cd "$V"
    claude -p "Use the secondbrain-consolidate skill to tidy this vault (cwd is the vault root). Merge duplicate or near-duplicate notes, fix stale facts and dead wikilinks, and regenerate index.md as a concise, accurate map. Make only edits that improve accuracy or reduce duplication - if nothing needs fixing, change nothing." \
      --permission-mode acceptEdits --max-turns 40 || echo "[second-brain] claude consolidation pass failed; continuing to git step"
    git add -A
    if ! git diff --cached --quiet; then
      git -c commit.gpgsign=false commit -q -m "consolidate: scheduled vault tidy $(date +%F)" || true
    fi
    if git remote get-url origin >/dev/null 2>&1; then
      git push -q origin HEAD || echo "[second-brain] push failed (offline?); will retry next run"
    fi
    exit 0
  '';
in
lib.mkMerge [
  # ------------------------------------------------------------------
  # Cross-platform: env var, hook scripts, skills, vault bootstrap
  # ------------------------------------------------------------------
  {
    # Vault path for every login shell + anything that inherits session env.
    home.sessionVariables.SECOND_BRAIN_VAULT = vaultPath;

    # Hook scripts under ~/.claude/hooks/ (registered in home/claude/default.nix).
    home.file.".claude/hooks/secondbrain-session-start.sh" = {
      text = sessionStartScript;
      executable = true;
    };
    home.file.".claude/hooks/secondbrain-session-end.sh" = {
      text = sessionEndScript;
      executable = true;
    };

    # House-convention skills. Directory-based per Claude Code skill layout.
    home.file.".claude/skills/secondbrain-save/SKILL.md".source = ./skills/secondbrain-save/SKILL.md;
    home.file.".claude/skills/secondbrain-consolidate/SKILL.md".source = ./skills/secondbrain-consolidate/SKILL.md;
    home.file.".hermes/skills/secondbrain/secondbrain-save/SKILL.md".source = ./skills/secondbrain-save/SKILL.md;
    home.file.".hermes/skills/secondbrain/secondbrain-consolidate/SKILL.md".source = ./skills/secondbrain-consolidate/SKILL.md;

    # Vault bootstrap: clone the private remote if the vault is missing;
    # scaffold a minimal unversioned vault if the clone fails. A later
    # activation replaces an untouched scaffold with the remote clone, while
    # preserving any offline-authored content for an explicit merge.
    home.activation.secondbrainBootstrap = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      sb_vault="${vaultPath}"
      sb_pending="$sb_vault/.secondbrain-bootstrap-pending"

      if [ -f "$sb_pending" ]; then
        remote_clone="$sb_vault.remote-$(date +%Y%m%dT%H%M%S)"
        echo "[second-brain] retrying private remote clone"
        if ${pkgs.git}/bin/git clone -q "${vaultRemote}" "$remote_clone" 2>/dev/null; then
          authored_count=$(find "$sb_vault" -type f ! -name '.secondbrain-bootstrap-pending' ! -name 'index.md' | wc -l | tr -d ' ')
          if [ "$authored_count" = "0" ] && grep -q 'See the secondbrain-save skill for conventions' "$sb_vault/index.md" 2>/dev/null; then
            backup="$sb_vault.offline-$(date +%Y%m%dT%H%M%S)"
            mv "$sb_vault" "$backup"
            mv "$remote_clone" "$sb_vault"
            echo "[second-brain] remote clone restored; untouched offline scaffold retained at $backup"
          else
            rm -f "$sb_pending"
            echo "[second-brain] remote available, but offline content exists; merge $remote_clone into $sb_vault manually" >&2
          fi
        else
          echo "[second-brain] private remote still unavailable; keeping offline scaffold" >&2
        fi
      elif [ ! -d "$sb_vault" ]; then
        echo "[second-brain] vault missing; attempting clone of ${vaultRemote}"
        if ! ${pkgs.git}/bin/git clone -q "${vaultRemote}" "$sb_vault" 2>/dev/null; then
          echo "[second-brain] clone failed; scaffolding recoverable offline vault at $sb_vault"
          mkdir -p "$sb_vault"/daily "$sb_vault"/projects "$sb_vault"/decisions "$sb_vault"/knowledge "$sb_vault"/people
          touch "$sb_pending"
          if [ ! -f "$sb_vault/index.md" ]; then
            d=$(date +%F)
            printf -- '---\ncreated: %s\nupdated: %s\ntags: [index]\nsource: claude-session\n---\n\n# Second Brain - Index\n\nSee the secondbrain-save skill for conventions.\n' "$d" "$d" > "$sb_vault/index.md"
          fi
        fi
      fi
    '';
  }

  # ------------------------------------------------------------------
  # Linux/WSL: weekly consolidation timer + Windows Claude Code bridge
  # (`systemd` options are guarded out on darwin, mirroring home/updates).
  # ------------------------------------------------------------------
  (lib.mkIf (!isDarwin) {
    systemd.user.services.secondbrain-consolidate = {
      Unit.Description = "Second-brain vault consolidation (headless claude)";
      Service = {
        Type = "oneshot";
        ExecStart = "${consolidateScript}";
        Environment = [ "SECOND_BRAIN_VAULT=${vaultPath}" ];
      };
    };
    systemd.user.timers.secondbrain-consolidate = {
      Unit.Description = "Weekly second-brain consolidation";
      Timer = {
        OnCalendar = "Sun 18:00";
        Persistent = true;
      };
      Install.WantedBy = [ "timers.target" ];
    };
  })

  (lib.mkIf isWsl {
    # LORE bridge: mirror hooks/skills/CLAUDE.md + settings fragments into
    # Windows-native Claude Code (%USERPROFILE%\.claude). Guarded on the
    # mount existing; jq merge is marker-based and non-destructive.
    home.activation.secondbrainWindowsBridge = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      win="${winClaudeDir}"
      if [ -d "$win" ]; then
        mkdir -p "$win/hooks" "$win/skills/secondbrain-save" "$win/skills/secondbrain-consolidate"

        # PowerShell ports of the two hooks (Windows Claude Code runs hook
        # commands through cmd; powershell -File keeps quoting sane).
        cat > "$win/hooks/secondbrain-session-start.ps1" <<'PS1'
$ErrorActionPreference = 'SilentlyContinue'
$V = if ($env:SECOND_BRAIN_VAULT) { $env:SECOND_BRAIN_VAULT } else { '${winVaultPath}' }
if (Test-Path "$V\index.md") {
  Write-Output "=== Second Brain index ($V\index.md) ==="
  Get-Content "$V\index.md"
  $proj = (git remote get-url origin 2>$null) -replace '\.git$',"" -replace '.*/',""
  if (-not $proj) { $proj = Split-Path -Leaf (Get-Location) }
  if (Test-Path "$V\projects\$proj.md") {
    Write-Output ""; Write-Output "=== Project note: $proj ==="
    Get-Content "$V\projects\$proj.md"
  }
  Write-Output ""
  Write-Output "[second-brain] Consult the vault before substantive work; record durable outcomes before finishing (secondbrain-save skill)."
}
exit 0
PS1

        cat > "$win/hooks/secondbrain-session-end.ps1" <<'PS1'
$ErrorActionPreference = 'SilentlyContinue'
$V = if ($env:SECOND_BRAIN_VAULT) { $env:SECOND_BRAIN_VAULT } else { '${winVaultPath}' }
if (Test-Path "$V\daily") {
  $d = Get-Date -Format 'yyyy-MM-dd'; $t = Get-Date -Format 'HH:mm'
  $f = "$V\daily\$d.md"
  if (-not (Test-Path $f)) {
    "---`ncreated: $d`nupdated: $d`ntags: [daily]`nsource: claude-session`n---`n`n# $d`n" | Set-Content $f
  }
  $branch = git branch --show-current 2>$null
  $suffix = if ($branch) { " (branch ``$branch``)" } else { "" }
  "- $t session ended in ``$(Get-Location)``$suffix" | Add-Content $f
}
exit 0
PS1

        # Skills (same SKILL.md files).
        cp -f ${./skills/secondbrain-save/SKILL.md} "$win/skills/secondbrain-save/SKILL.md"
        cp -f ${./skills/secondbrain-consolidate/SKILL.md} "$win/skills/secondbrain-consolidate/SKILL.md"

        # settings.json: merge env.SECOND_BRAIN_VAULT + marker-based hooks.
        ws="$win/settings.json"
        [ -f "$ws" ] || echo '{}' > "$ws"
        if ${pkgs.jq}/bin/jq \
          --arg vault '${winVaultPath}' \
          --arg start 'powershell -NoProfile -ExecutionPolicy Bypass -File C:/Users/james/.claude/hooks/secondbrain-session-start.ps1' \
          --arg end   'powershell -NoProfile -ExecutionPolicy Bypass -File C:/Users/james/.claude/hooks/secondbrain-session-end.ps1' \
          '
          .env.SECOND_BRAIN_VAULT = $vault
          | .hooks.SessionStart = (((.hooks.SessionStart // []) | map(select((tojson | contains("secondbrain")) | not))) + [{hooks: [{type: "command", command: $start}]}])
          | .hooks.SessionEnd   = (((.hooks.SessionEnd   // []) | map(select((tojson | contains("secondbrain")) | not))) + [{hooks: [{type: "command", command: $end}]}])
          ' "$ws" > "$ws.tmp"; then
          mv "$ws.tmp" "$ws"
          echo "[second-brain] Windows Claude Code bridge synced ($win)"
        else
          rm -f "$ws.tmp"
          echo "[second-brain] WARN: failed to merge $ws; Windows bridge skipped" >&2
        fi

        # Global memory for Windows Claude Code, mirroring ~/.claude/CLAUDE.md.
        # Windows had no CLAUDE.md before the bridge — safe to own it.
        cp -f "${config.home.file.".claude/CLAUDE.md".source}" "$win/CLAUDE.md" 2>/dev/null \
          || echo "[second-brain] WARN: could not mirror CLAUDE.md to Windows" >&2
      fi
    '';
  })

  # ------------------------------------------------------------------
  # macOS: weekly consolidation via launchd (mirrors home/updates pattern)
  # ------------------------------------------------------------------
  (lib.mkIf isDarwin {
    launchd.agents.secondbrain-consolidate = {
      enable = true;
      config = {
        ProgramArguments = [ "${consolidateScript}" ];
        EnvironmentVariables.SECOND_BRAIN_VAULT = vaultPath;
        StartCalendarInterval = [ { Weekday = 0; Hour = 18; Minute = 0; } ];
        StandardOutPath = "${homeDir}/Library/Logs/secondbrain-consolidate.log";
        StandardErrorPath = "${homeDir}/Library/Logs/secondbrain-consolidate.log";
      };
    };
  })
]
