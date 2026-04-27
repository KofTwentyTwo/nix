# Session State

**Last Updated:** 2026-04-27

## Current Status
Major Claude Code infrastructure cleanup and multi-domain rules update landed on Dark-Horse and verified end-to-end. Changes are staged but uncommitted; other three hosts (Grogu, Darth, Renova) still need a `git pull && darwin-rebuild switch` after push.

## What Was Done This Session

**Audit and discovery**
- Full audit of existing Claude Code setup against an originally-proposed "build companion repo" approach. Concluded the companion-repo idea was wrong for this setup (everything's already declarative inline) and reframed as: cleanups + missing local content additions.
- Found and documented the phantom `local--review-pr` skill (referenced by `3-rules.md` section 17, didn't exist).

**AI rules cleanup (`~/.ai/*`)**
- Rewrote `1-profile.md` with multi-domain CTO at dmdbrands / Greater Goods + Kingsrook/QRun-IO maintainer + multi-org footprint table. Mobile/web/firmware/devops scope added.
- Rewrote `3-rules.md`: extracted QQQ-specific architecture rules (sections 14-15) and Java specifics, generalized identity, decision-making policy, and tracker routing for multi-domain. Added compound-command decomposition note. Reinforced `local--review-pr` routing.
- Restructured `2-coding-style.md` to lead with universal principles, then per-language sections expanded to cover TS, Swift, Kotlin, C/Zephyr, Terraform, YAML alongside existing Java/Rust/Python/Nix/Shell. QQQ-specific marked as project-scoped.
- Cleaned up `4-preferences.yaml` for multi-domain. Added per-language tuning. Fixed paths. Moved GraphQL discussion-posting recipe to `5-learnings.md`.
- Rewrote `0-init.md` to match the 6-file hierarchy.
- Reconciled hierarchy across `~/.claude/CLAUDE.md` inline text (in `home/claude/default.nix`), `0-init.md`, and `3-rules.md` — all three now agree on the 6-file load order including `5-learnings.md`.
- Added Healthcare Context, QRun-IO Discussions GraphQL recipe, and a "Nix + Claude Code Configuration" section to `5-learnings.md` (covering flake/git tracking, marketplace-vs-enabledPlugins, compound-command perms, defensive jq merge).

**New local Claude Code content** (under `home/claude/`)
- 5 new skills: `review-pr`, `brownfield-onboarding`, `pre-merge-checklist`, `mqtt-topic-design`, `circleci-mac-runner-debug`.
- 3 new agents: `firmware-build-doctor`, `hub-firmware-driver`, `migration-planner`.
- 2 new commands: `standup`, `eod-handoff` (new `commands/` directory).
- 5 workspace templates: `mobile/web/firmware/devops/qqq-CLAUDE.md` (new `workspace-templates/` directory).
- 1 project-level MCP example: `templates/mcp.json.example`.
- Wired into `home/claude/skills.nix` (new `localCommands`, `workspaceTemplates`, `localTemplates` attribute sets).

**Permissions expansion** (in `home/claude/default.nix`)
- Added `claude:*`, `cd:*`, full firmware tooling (`west`, `nrfutil`, `pyocd`, `JLinkExe`, `cmake`, `ninja`, `platformio`, `arm-none-eabi-*`, `openocd`).
- Added IaC read-only ops (`terraform plan|validate|init|fmt|output|show|state|...` and equivalent `tofu`).
- Added `WebSearch`, `WebFetch`. Total: 335 entries.

**New Home Manager activation scripts** (in `home/claude/default.nix`)
- `installClaudePluginMarketplaces` — auto-registers `claude-plugins-official` marketplace on every rebuild. Closes a fresh-machine bootstrap gap.
- `bootstrapQqqClaudeMd` — drops `qqq-CLAUDE.md` into `~/Git.Local/QRun-IO/qqq/CLAUDE.md` if QQQ checkout exists and that file is missing. Copy-if-missing, never overwrites.

**Homebrew**
- Added `pnpm` to `modules/homebrew.nix`.

**Verification (Dark-Horse)**
- `nix flake check` green for all 4 darwinConfigurations.
- `darwin-rebuild switch` succeeded after `git add -A` (flake-evaluator-only-sees-tracked-files gotcha).
- 8 local skills, 4 local agents, 6 commands (4 cw + 2 new), 5 workspace templates, mcp.json.example all on disk.
- All `~/.ai/*` symlinks updated to new store hash.
- 24 plugins enabled (Superpowers, Atlassian, Figma, etc. now resolvable as skills).
- pnpm 10.33.2 on PATH.
- Marketplace registered.
- QQQ CLAUDE.md bootstrapped at `~/Git.Local/QRun-IO/qqq/CLAUDE.md` (untracked from QQQ side).

## Active Branches
| Branch | Status |
|---|---|
| `main` | 25 file changes staged + a few worktree edits (TODO.md and 5-learnings.md got further session-end touches). Needs commit + push. |

## Pending Work
- [ ] Commit staged changes and push to origin
- [ ] Sync Grogu / Darth / Renova: `git pull && sudo darwin-rebuild switch --flake ~/.config/nix#$(hostname)`
- [ ] From inside `~/Git.Local/QRun-IO/qqq/`: review the bootstrapped `CLAUDE.md` and commit to QQQ's main branch
- [ ] (optional) Decide whether to put `claude-hud@claude-hud` and the `jarrodwatts/claude-hud` marketplace into Nix
- [ ] (as projects rotate in) Add additional Greater Goods Jira projects to `home/ai/4-preferences.yaml`
- [ ] (deferred) HIPAA / BAA / PHI policy layer

## Key Reference
- AI rules priority hierarchy (binding for all sessions):
  1. `~/.claude/CLAUDE.md` (Nix-managed inline text in `home/claude/default.nix`)
  2-6. `~/.ai/3-rules.md`, `2-coding-style.md`, `1-profile.md`, `4-preferences.yaml`, `5-learnings.md`
  7. Project `CLAUDE.md`
- Local Claude content lives under `home/claude/{skills,agents,commands,workspace-templates,templates}/`, registered in `home/claude/skills.nix`.
- Fresh-machine bootstrap is one command: `sudo darwin-rebuild switch --flake ~/.config/nix#$(hostname)`. Marketplace + QQQ CLAUDE.md are activation-driven; pnpm via `onActivation.upgrade=true`.
- Nix flake gotcha: `git add` (no commit needed) before `darwin-rebuild switch` when adding new files referenced by `${./path}`.
