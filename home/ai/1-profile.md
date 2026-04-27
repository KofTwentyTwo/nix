# Profile

## Overview

**Name:** James Maes
**Roles:**
- **CTO, dmdbrands** (operating co: Greater Goods) — hands-on technical leadership for a healthcare device company, ~25 engineers across mobile, web, firmware, and devops.
- **Founder / Maintainer, Kingsrook, LLC / QRun.IO** — owner of the QQQ low-code framework (AGPL, open source) and supporting tooling.

I lead engineering at dmdbrands while remaining hands-on across the stack and continuing to maintain the QQQ ecosystem. Most working sessions are in one of three modes:

1. **CTO mode** — architecture review, codebase audits, brownfield onboarding, cross-team coordination, hiring signal, devops/security oversight.
2. **Builder mode (dmdbrands)** — hands-on work in mobile, web, firmware (Zephyr/NCS), or infrastructure (Terraform/AWS/CircleCI).
3. **Builder mode (QQQ)** — Java framework engineering on the QQQ codebase.

The active mode is usually obvious from the working directory and git remote. When ambiguous, ask.

## Multi-Org Footprint

| Org | GitHub | Atlassian/Jira | Role |
|---|---|---|---|
| Greater Goods (dmdbrands) | `dmdbrands` | `greatergoods.atlassian.net` | CTO, hands-on |
| Kingsrook / QRun-IO | `QRun-IO` | -- (GitHub Issues) | Founder, maintainer |
| Personal | `KofTwentyTwo` (`kof22.com`) | -- | Personal projects, tooling |

Issue-tracker auto-detection lives in `3-rules.md` section 4. When the org isn't matched by that table, ask before assuming.

## Expertise

### Languages & Technologies
- **Daily:** Java 17+ (expert), TypeScript/JavaScript (Node + browser), Nix, Shell (Bash/Zsh)
- **Active:** Swift/Kotlin (mobile), C/C++ (Zephyr firmware), Python, Rust, Terraform/HCL, YAML
- **Build/runtime:** Maven, npm/pnpm/yarn, Cargo, west (Zephyr), CMake, Homebrew, Nix
- **Frameworks:** QQQ, React/Next.js, Javalin, JUnit, Spring-adjacent patterns, Zephyr RTOS / nRF Connect SDK
- **Data:** PostgreSQL, SQLite, MongoDB, Redis, generic RDBMS
- **Infra:** AWS (multiple accounts via Control Tower), Docker, Kubernetes, CircleCI (incl. self-hosted Mac runners), Terraform, Helm, Argo
- **IoT/messaging:** AWS IoT Core, MQTT, BLE
- **Version control:** Git (GPG-signed commits, conventional commits), GitHub, gh CLI, GitHub Actions
- **Editors:** Neovim/LazyVim (terminal), IntelliJ IDEA (Java), Xcode (iOS), VS Code (occasional)

### Domain Expertise
- **Low-code framework design** — meta-data-driven architectures, registration patterns, multi-module Maven (QQQ)
- **Healthcare device software** — device-cloud sync, telemetry, OTA, embedded development
- **Brownfield engineering** — picking up unfamiliar repos, framework migrations, dependency upgrades
- **Developer experience** — declarative environments (Nix + Home Manager), CI/CD design, code-quality enforcement
- **Engineering leadership** — code review at scale, technical interviewing, architectural decision records

## Communication Style

### Preferences
- **Tone:** Professional, direct, concise.
- **Verbosity:** Medium. Context where it helps, no padding.
- **Technical depth:** Deep — don't oversimplify or add disclaimers I don't need.
- **Code examples:** Always concrete and from the actual codebase when relevant.
- **Documentation:** Prefer structured, scannable, maintainable. Tables and short paragraphs over walls of prose.

### What I Appreciate
- Solutions that match existing patterns in the active codebase.
- Honest assessment of trade-offs — even when the answer is "this is fine, leave it alone."
- Push-back when my framing is wrong. I'd rather be corrected than humored.
- Cross-domain context (e.g., flagging when a backend choice affects firmware OTA).
- Awareness that I'm working across 100+ repos — I rely on patterns and tooling, not memorization.

### What I Don't Like
- Generic advice that ignores codebase-specific patterns.
- Over-engineering, premature abstraction, or "future-proofing" for hypotheticals.
- Breaking changes without clear value.
- Long preambles, restatements of my question, or trailing summaries when the diff already shows the work.
- Emoji in any generated content (rules, code, prose, commit messages).

## Development Environment

- **Platform:** macOS Apple Silicon (`aarch64-darwin`), multiple machines (Darth, Grogu, Renova, Dark-Horse) — all synced via this Nix flake at `~/.config/nix`.
- **Declarative dotfiles:** nix-darwin + Home Manager. AI rules, shell, editor, terminal, secrets, and Claude Code config are all version-controlled here.
- **Shell:** zsh + Oh-My-Zsh, eza-as-ls wrapper, zoxide, fzf, direnv (with nix-direnv).
- **Terminal:** WezTerm.
- **Editor (terminal):** Neovim with LazyVim.
- **AI tooling:** Claude Code (npm-globals, latest), GSD framework, Superpowers and 21 other official plugins, 100+ skills from upstream community repos plus local skills/agents/commands managed in this Nix repo.
- **Secrets:** `git-crypt` for repo-internal secrets, SOPS-nix for secrets shipped through Home Manager, 1Password CLI for runtime credentials.

## Technical Philosophy

- **Declarative over imperative.** Reproducible environments via Nix. Everything that can be config should be config.
- **Convention over configuration when it earns its keep.** Choose patterns, then apply them consistently.
- **Code quality is enforced, not requested.** Linters, formatters, type-checkers, CI gates — not docstrings asking nicely.
- **Open source first** for foundational tooling (QQQ is AGPL). Closed only when there's a clear reason.
- **Long-term maintenance over short-term cleverness.** I read more code than I write; so does the next person.

## Engineering Principles

- Favor explicit over implicit.
- Write code for the next maintainer.
- Test at the appropriate level (unit, integration, system, end-to-end).
- Document the *why*, not the *what*. Names handle the "what."
- Consistency is a feature.
- When in doubt, match the surrounding code.

## Reference Workspaces (when applicable)

| Domain | Path | Notes |
|---|---|---|
| QQQ framework | `~/Git.Local/QRun-IO/qqq/` | QQQ-specific rules in that repo's `CLAUDE.md` |
| Nix config | `~/.config/nix/` | This flake; primary across all machines |
| dmdbrands repos | varies | Mobile, web, firmware, devops — see local `CLAUDE.md` per repo |
