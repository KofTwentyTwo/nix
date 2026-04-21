# Session State

**Last Updated:** 2026-04-21

## Current Status
Session work complete. Committing and pushing.

## What Was Done This Session
- Replaced Tunnelblick with Viscosity VPN client
- Created home/viscosity/ module with 5 VPN connections (dev, prod, staging, st-marys-lan, galaxy-lan)
- Added activation script to auto-register connections in Viscosity plist on switch
- All VPN config files git-crypt encrypted via .gitattributes wildcard
- Added /opt/homebrew/sbin to PATH (for mtr and other sbin tools)
- Added prettyping, aliased ping and traceroute to modern alternatives
- Fixed tmux session naming: split rename into helper script, handle duplicate names, fix grep regex issue with session IDs containing $
- Marked tmux performance and GPG/SSH backlog items as done

## Active Branches
| Branch | Status |
|--------|--------|
| `main` | Committing |

## Pending Work
- [ ] Test opencode TUI launch and MCP server connections (interactive test)
- [ ] Diff remote machine (100.76.144.59) brew packages when online
- [ ] Remaining audit: #22 (permission drift), #23 (disk cleanup)

## Key Reference
- Git-crypt encrypts: home/ssh/default.nix, home/aws/config/config, home/ai/4-preferences.yaml, home/aws/config/credentials
- Git history is clean (filter-repo removed plaintext of encrypted files)
- Repo is safe for public release on GitHub
- Other machines (Grogu, Renova, Dark-Horse) need fresh clone after history rewrite
