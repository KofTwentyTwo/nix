# Claude Code Configuration Module
# ================================
# This Home Manager module manages the ~/.claude/ directory with Claude Code
# configuration files. All files are generated declaratively from this module.
#
# Files managed:
#   - ~/.claude/CLAUDE.md         User-level instructions for Claude Code
#   - ~/.claude/settings.json     Claude Code settings (if needed)
#
# Usage:
#   Import this module in home/default.nix:
#     imports = [ ./claude ];
#
# Updates:
#   Edit this file and run: darwin-rebuild switch --flake ~/.config/nix

{ config, pkgs, lib, ... }:

{
  home.file.".claude/CLAUDE.md".text = ''
    # User Settings for Claude Code

    ## GitHub Issue Creation

    When creating issues for QRun-IO repositories, ALWAYS:

    1. **Required fields** - Set all of these:
       - Title (clear, concise)
       - Body (structured with ## Summary, ## Tasks, ## Acceptance Criteria)
       - Labels (at minimum: enhancement/bug, phase-X if applicable)
       - Assignee (default: KofTwentyTwo)
       - Milestone (if one exists for the repo)

    2. **Project fields** - Add to QQQ Roadmap project (#12) and set:
       - Status (default: Backlog)
       - Priority (ask if not obvious)
       - Component (match the repo)
       - Parent Issue (if part of an epic)

    3. **Before creating** - Ask user to confirm any fields that are:
       - Blank or unknown
       - Ambiguous (e.g., priority, parent issue)

    4. **After creating** - Verify the issue has all fields populated correctly.
  '';
}
