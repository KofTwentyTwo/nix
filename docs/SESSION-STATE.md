# Session State

Last updated: 2026-03-13

## Current State

Changes made but NOT YET APPLIED. Need to run `switch` to activate.

## Changes Pending Switch

Two files modified in `~/.config/nix`:

1. **home/zsh/default.nix** - Three additions:
   - `ls()` wrapper function: translates standard ls flags (`-t`, `-S`, `-s`, `-h`) to eza equivalents so `ls -lsrt` works naturally
   - `shelp()` function: comprehensive help reference for all tools, aliases, scripts, and apps. Supports filtering: `shelp kubectl`, `shelp replace`, etc.
   - Replaced old aliases (`lss`, `lrt`, `llt`) with `ls-*` naming: `ls-la`, `ls-lt`, `ls-lrt`, `ls-lsrt`, `ls-lsart`, `ls-lS`, `ls-lSr`
   - Added explicit `ll`, `la`, `tree` aliases (previously auto-created by eza module)

2. **home/default.nix** - One change:
   - Set `programs.eza.enableZshIntegration = false` so eza does not create an `alias ls=eza` that overrides our wrapper function (zsh aliases expand before function lookup)

## Key Decision

Eza's auto-aliases were interfering with the ls wrapper function. Zsh processes aliases at parse time before function lookup, so `alias ls=eza` meant `ls -lsrt` became `eza -lsrt` (broken) instead of hitting our wrapper. Fix: disabled eza's zsh integration and defined all aliases manually.

## Environment Status

| Item | Status |
|------|--------|
| Brew formulae | 137 managed in modules/homebrew.nix |
| Brew casks | 47 managed in modules/homebrew.nix |
| Nix packages | delta, comma, fonts only (rest in brew) |
| Node.js | v22 default, v25 + v20 available |
| Claude plugins | 13 plugins managed via Nix |
| fzf | Shell integration enabled |
| oh-my-zsh | 9 plugins (git, sudo, docker, kubectl, aws, helm, terraform, fzf, aliases) |
| ls wrapper | Written, needs switch to activate |
| shelp | Written, needs switch to activate |

## Pending

- Run `switch` to activate the ls wrapper and shelp changes
- Test `ls -lsrt` after switch
- Test `shelp` and `shelp KEYWORD` after switch
- Remote machine (100.76.144.59) unreachable. Need to diff its brew packages when online.
- masApps left commented out (mas was reinstalling on every run)

## How to Continue

Say **"continue from last session"**. Claude reads:
1. `./docs/SESSION-STATE.md` (this file)
2. `./docs/TODO.md`
3. `./CLAUDE.md`
