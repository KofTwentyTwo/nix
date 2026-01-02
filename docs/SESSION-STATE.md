# Session State

Last updated: 2026-01-02

## Current State

Refining AI agent rules and preferences. Just added major new rules for planning mode, progress tracking, secrets handling, retry limits, and session continuity.

## Just Completed

- Added rules: secrets handling, retry limits, expensive ops warning, progress reporting
- Added rules: pause on failure, planning mode workflow
- Added session continuity requirements (periodic updates to docs)
- Moved TODO.md to docs/ directory
- Committed WezTerm status bar and SSH host tracking

## Pending

- Run `sudo darwin-rebuild switch --flake ~/.config/nix` to apply rules
- Commit the new rules

## Active Issues

**Tmux Performance** - Auto-start disabled due to flickering/lag. See `TMUX-ISSUES.md`.

## How to Continue

Say **"continue from last session"**. Claude reads this file, `CLAUDE.md`, and `docs/TODO.md`.
