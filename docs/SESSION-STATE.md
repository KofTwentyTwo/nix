# Session State

**Last Updated:** 2026-04-20

## Current Status
All changes committed and pushed. Repo hardened for public release (git-crypt on sensitive files, env vars for credentials). Tmux session naming and window titles working.

## What Was Done This Session
- Added ncdu alias with dark-bg, graph, apparent-size, percent flags
- Added tmux session-created hook that prompts for session name (Enter to skip)
- Fixed session naming: %1 instead of %% for all-occurrence substitution
- Fixed session naming: quoted %1 to support spaces in names
- Added set-titles to tmux so WezTerm Cmd+Tab shows session name instead of "tmux"
- Added ollama (cask) and jetbrains-toolbox to homebrew
- Rewrote README as comprehensive "Ultimate AI Developer Terminal" showcase
- Security audit: identified 5 blockers for public repo
- Encrypted SSH config, AWS config, preferences.yaml via git-crypt
- Parameterized confluence scripts (CONFLUENCE_BASE_URL, CONFLUENCE_EMAIL env vars)
- Parameterized SonarQube org (SONARQUBE_ORG env var)
- Committed and fixed neovim config (LazyVim compat, nil_ls for Nix, ts_ls)
- Added sales-admin agent and skill

## Active Branches
| Branch | Status |
|--------|--------|
| `main` | Clean, up to date with origin |

## Pending Work
- [ ] Add CONFLUENCE_BASE_URL and CONFLUENCE_EMAIL to 1Password vault
- [ ] Before making repo public: rewrite git history to remove plaintext of now-encrypted files (git filter-repo)
- [ ] Test opencode launches and MCP servers connect
- [ ] Re-set tmux lock PIN (format changed, run `tmux-lock-set-pin.sh`)
- [ ] Remaining audit: #22 (permission drift), #23 (disk cleanup)

## Key Reference
- Git-crypt encrypts: home/ssh/default.nix, home/aws/config/config, home/ai/4-preferences.yaml
- New env vars needed: CONFLUENCE_BASE_URL, CONFLUENCE_EMAIL, SONARQUBE_ORG
- Audit report: docs/AUDIT-2026-04-07.md (21/23 resolved)
