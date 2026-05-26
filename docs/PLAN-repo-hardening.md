# PLAN: Repo Hardening

## Goal

Fix the review findings and add local checks that keep the Nix config, shell
scripts, generated agent instructions, and repo hygiene from drifting.

## Approach

Patch the concrete defects first, then add a single repo check script that runs
the same validation commands used during review. Keep activation-sensitive
changes small and verify with flake evaluation plus a non-activating Darwin
build.

## Files Affected

- `home/sops/default.nix` - avoid aborting later Home Manager activations.
- `home/zsh/default.nix` - remove stale GSD flake update from `switch`.
- `home/codex/default.nix` - include `~/.ai/5-learnings.md` in bootstrap text.
- `home/gemini/default.nix` - include `~/.ai/5-learnings.md` in bootstrap text.
- `home/claude/default.nix` - tighten risky auto-allow permissions.
- `.claude/settings.local.json` - align tracked local permissions with policy.
- `.gitignore` - ignore local generated artifacts.
- `scripts/check-repo.sh` - local verification entry point.
- `home/scripts/default.nix` - install the check script.
- Shell scripts flagged by ShellCheck - remove avoidable warnings.
- `docs/TODO.md` and `docs/SESSION-STATE.md` - update continuity state.

## Steps

1. [x] Fix activation and rebuild helper defects.
2. [x] Fix generated agent instruction drift.
3. [x] Tighten risky permission allowlist entries.
4. [x] Add local repo check script and lint config.
5. [x] Clean tracked build/local artifacts.
6. [x] Run verification and record residual risks.

## Open Questions

- None blocking. Full `darwin-rebuild switch` still requires human sudo and is
  intentionally outside this pass.
