# PLAN: Hermes Integration and Second Brain Coverage

## Goal

Document the Nix repository completely in the Second Brain and make Hermes a declaratively configured OpenRouter-backed agent with verified model routing and explicitly bounded access to development tools, communications, and the local computer.

## Approach

Audit the current flake and deployed Hermes runtime against upstream capabilities, record the repository architecture and Hermes operating model in provenance-backed Second Brain notes, then add the smallest Nix-managed configuration needed for repeatable provider routing, credentials, integrations, and low-friction approvals. Preserve interactive confirmation for destructive, secret-bearing, or externally consequential actions.

The user explicitly waived the repository's ticket and feature-branch conventions for this project on 2026-07-14. Work remains on `main`; the user authorized the validated rollout commit, push, and reachable-machine activation on 2026-07-14.

## Files Affected

- `home/hermes/default.nix` — declarative Hermes configuration and platform bridges.
- `home/sops/default.nix` — scoped credential deployment if Hermes needs additional secrets.
- `home/zsh/default.nix` — environment wiring only where Hermes requires it.
- `README.md` and relevant `docs/` files — current cross-platform architecture and operating instructions.
- `docs/TODO.md` and `docs/SESSION-STATE.md` — task and continuity tracking.
- `$SECOND_BRAIN_VAULT/projects/nix.md` — current project state and coverage ledger.
- `$SECOND_BRAIN_VAULT/knowledge/nix/` — provenance-backed Nix and Hermes knowledge notes.
- `$SECOND_BRAIN_VAULT/index.md` and `daily/2026-07-14.md` — retrieval links and session record.

## Steps

1. [x] Inventory the repository, deployed Hermes runtime, and existing Second Brain coverage.
2. [x] Verify upstream Hermes support for OpenRouter routing, tools, gateways, hooks, and approvals.
3. [x] Define the capability and permission matrix for Git, GitHub, CircleCI, Slack, email, browser, and local-computer access.
4. [x] Write provenance-backed Second Brain notes and update the Nix project ledger.
5. [x] Implement the approved declarative Hermes configuration and secret wiring.
6. [x] Update repository documentation and continuity files.
7. [x] Run final repository checks, activation, and live validation.
8. [x] Record final verified results and remaining account-authorization steps.

## Decisions

- Communications target Greater Goods Slack and Gmail. Calendar, Drive, Docs, Sheets, People, and Contacts remain available through the same Google Workspace OAuth helper.
- Safe reads and local development are low-friction; externally consequential, destructive, secret-bearing, and Git publication actions retain the shared AI-rule controls.
- Interactive Hermes runs everywhere. Grogu alone owns the continuous Slack gateway and its service credentials.

## Validation

The implementation passed the final repository gate, all-system flake evaluation, exact Darwin builds, Dark-Horse activation, and live OpenRouter, context, GitHub, CircleCI, Atlassian, local-tool, and computer-use checks. The replacement CircleCI token is SOPS-deployed and live-verified through the REST API and native CLI; revoking its exposed predecessor remains the final incident action. Gmail and the additional Google Workspace services are declaratively wired but await the shared Desktop OAuth client and per-runtime consent. Slack, Firecrawl key population, and offline LORE validation still require account or machine interaction.
