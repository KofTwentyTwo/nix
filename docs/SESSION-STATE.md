# Session State

**Last Updated:** 2026-04-21

## Current Status
Session complete. Added firebase-cli and opencode Ollama provider, committed and pushed.

## What Was Done This Session
- Added firebase-cli to homebrew.nix, ran darwin-rebuild switch
- Committed opencode Ollama provider config (was previously unstaged)
- Pushed both commits to origin/main

## Active Branches
| Branch | Status |
|--------|--------|
| `main` | Up to date with origin |

## Pending Work
- [ ] Test opencode TUI launch and MCP server connections (interactive test)
- [ ] Diff remote machine (100.76.144.59) brew packages when online
- [ ] Remaining audit: #22 (permission drift), #23 (disk cleanup)

## Key Reference
- Git-crypt encrypts: home/ssh/default.nix, home/aws/config/config, home/ai/4-preferences.yaml, home/aws/config/credentials
- Git history is clean (filter-repo removed plaintext of encrypted files)
- Repo is safe for public release on GitHub
- Other machines (Grogu, Renova, Dark-Horse) need fresh clone after history rewrite
