# Session State

**Last Updated:** 2026-04-20

## Current Status
All active tasks complete. Repo is safe for public release. Git history rewritten (no plaintext sensitive files). All changes committed and pushed.

## What Was Done This Session
- Added ncdu alias with dark-bg, graph, apparent-size, percent flags
- Added tmux session-created hook that prompts for session name (Enter to skip)
- Fixed session naming: %1 for all-occurrence substitution, quoted for spaces
- Added set-titles to tmux so WezTerm Cmd+Tab shows session name
- Added ollama (cask) and jetbrains-toolbox to homebrew
- Rewrote README as comprehensive "Ultimate AI Developer Terminal" showcase
- Security audit: identified and resolved 5 blockers for public repo
- Encrypted SSH config, AWS config, preferences.yaml via git-crypt
- Parameterized confluence scripts (CONFLUENCE_BASE_URL, CONFLUENCE_EMAIL)
- Parameterized SonarQube org (SONARQUBE_ORG env var)
- Added CONFLUENCE_BASE_URL and CONFLUENCE_EMAIL as nix session variables
- Rewrote git history with git-filter-repo (removed plaintext of encrypted files)
- Fixed git-crypt key corruption after filter-repo, re-encrypted with valid key
- Neovim config updated (LazyVim compat, nil_ls for Nix, ts_ls)
- Added sales-admin agent and skill
- Tmux lock PIN re-set

## Active Branches
| Branch | Status |
|--------|--------|
| `main` | Clean, up to date with origin |

## Pending Work
- [ ] Test opencode TUI launch and MCP server connections (interactive test)
- [ ] Diff remote machine (100.76.144.59) brew packages when online
- [ ] Remaining audit: #22 (permission drift), #23 (disk cleanup)

## Key Reference
- Git-crypt encrypts: home/ssh/default.nix, home/aws/config/config, home/ai/4-preferences.yaml, home/aws/config/credentials
- Git history is clean (filter-repo removed plaintext of encrypted files)
- Repo is safe for public release on GitHub
- Other machines (Grogu, Renova, Dark-Horse) need fresh clone after history rewrite
