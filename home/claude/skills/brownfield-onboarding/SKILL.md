---
name: brownfield-onboarding
description: "Structured methodology for picking up an unfamiliar repo: discover build/test/deploy paths, map dependencies, audit current state, identify open work, and produce or update a project-level CLAUDE.md. Use when the user says 'pick up this repo', 'help me onboard to X', 'I'm new to this codebase', or starts work in a repo that lacks a CLAUDE.md."
when_to_use: "When starting work on a repo with no existing CLAUDE.md, or when the user explicitly asks for an onboarding pass on an existing repo. Required across the 100+ repo footprint at dmdbrands and Kingsrook orgs."
argument-hint: "[--repo <path>] [--update] [--quick]"
---

# Brownfield Onboarding

Build a working mental model of an unfamiliar repo, then capture it in a project-level `CLAUDE.md` so the next session (and every other tool) can boot from solid ground.

## When to invoke

- First time working in a repo — checked out, no `CLAUDE.md`, no idea where to start.
- Existing repo where the `CLAUDE.md` is stale (build commands changed, framework migrated, deploy path moved).
- Cross-domain handoff (e.g., backend dev now touching the firmware repo).

## Output

A populated `CLAUDE.md` at the repo root. If one exists, update — don't replace. Always show a diff to the user before writing.

## Sequence

Run sections 1–6 in parallel where the inputs allow; only section 7 (CLAUDE.md generation) is strictly sequential.

### 1. Identity

Determine:
- Repo name from `git remote get-url origin`
- Org → tracker (per `~/.ai/3-rules.md` section 4): `dmdbrands` → Jira, `QRun-IO`/`KofTwentyTwo` → GitHub Issues
- Domain bucket: mobile / web / firmware / devops / framework / tooling. Inputs: top-level files (`package.json` → web/mobile, `west.yml` → Zephyr, `pom.xml` → Java, `Cargo.toml` → Rust, `flake.nix` → Nix, `*.tf` → Terraform). Multiple buckets is fine — note them all.
- Primary languages: `tokei` or `cloc` if available; otherwise file-extension count via `fd`.

### 2. Build / Test / Run

For each detected ecosystem, record the canonical commands. Don't guess — read the config files.

| Ecosystem | Where to look | What to capture |
|---|---|---|
| Maven | `pom.xml`, `Makefile`, `.circleci/config.yml`, `README.md` | `mvn ...` build/test invocations, profiles, multi-module pattern |
| Node (npm/pnpm/yarn) | `package.json` `scripts`, lock files, `.nvmrc`, `engines` | install command, dev/build/test/lint scripts, package manager from lockfile |
| Zephyr/NCS | `west.yml`, `CMakeLists.txt`, `prj.conf`, `boards/` | board target(s), `west build` invocations, `west flash`, sample/app structure |
| Rust | `Cargo.toml`, `rust-toolchain.toml`, `.cargo/config.toml` | features, workspace members, MSRV, `cargo build/test/run` |
| Python | `pyproject.toml`, `requirements*.txt`, `tox.ini`, `setup.py` | venv setup, test runner (pytest/unittest), formatter/linter |
| Terraform | `*.tf`, `versions.tf`, `terraform.tf`, `backend.tf` | required version, providers, backend, module structure |
| Docker | `Dockerfile`, `docker-compose*.yml` | base images, build args, entrypoint, compose services |
| CircleCI | `.circleci/config.yml` | jobs, workflows, executors, orbs, secrets context |
| GitHub Actions | `.github/workflows/*.yml` | jobs, reusable workflows, secrets, environments |

Verify any non-obvious command works (e.g., run `--dry-run` or `--help` if available). Note anything that requires environment setup the user must do (env vars, 1Password items, AWS profile).

### 3. Code Map

Top-level directory tree to depth 2:

```bash
fd --type d --max-depth 2 . | sort
# or: tree -L 2 -d
```

For each top-level dir, write one line: what's in it. Skim for:
- Entry points (`main.*`, `app/`, `cmd/`, `bin/`)
- Test layout (`test/`, `tests/`, `__tests__/`, `*_test.go`, `*.test.ts`, `src/test/`)
- Generated code or vendored deps (mark as "do not edit by hand")
- `docs/` content — pull a list of headings if there are README-shaped files

### 4. Current State

In parallel:

- **Branches:** `git branch -a --sort=-committerdate | head -20` — what's the default branch? Is there a `develop`? Any active feature branches?
- **Open PRs:** `gh pr list --state open --json number,title,author,createdAt,labels`. Anything stale (>30 days)? Anything blocking?
- **Open issues:** `gh issue list --state open --limit 20 --json number,title,labels,assignees` (GitHub repos), or `searchJiraIssuesUsingJql 'project = X AND status != Done ORDER BY updated DESC'` (Jira repos).
- **Recent activity:** `git log --oneline -20` — what's been worked on? Hot files via `git log --since="3 months ago" --pretty=format: --name-only | sort | uniq -c | sort -rn | head -20`.
- **CI health:** `gh run list --limit 10 --json conclusion,name,createdAt,headBranch` — recent failures? On main?
- **Dependency freshness:** `npm outdated` / `cargo outdated` / `mvn versions:display-dependency-updates` / `west update --help` — anything dramatically out of date?
- **Security:** `gh api /repos/{owner}/{repo}/dependabot/alerts` if Dependabot is on; `gitleaks detect --no-git` for accidental secrets in working tree.

### 5. Deploy Path

Where does code go from `merge-to-main` to running?

- `Dockerfile` + image registry (GHCR? ECR? Docker Hub?) — find the push target in CI config.
- Kubernetes manifests / Helm charts / Argo CD `Application` — where is the cluster? Which env(s)?
- CD repo / GitOps — does this repo update a separate CD repo? (Munitor pattern at kof22; standard ArgoCD Image Updater elsewhere.)
- Mobile: TestFlight / Play Console internal testing. Fastlane lanes if present.
- Firmware: built artifact format (`.hex`, `.bin`, signed `.zip` for DFU/MCUboot), distribution (Nordic Cloud, OTA service, factory provisioning).
- Infrastructure: `terraform apply` cadence, who owns state, change-control process.

If you can't determine this from the repo alone, note it as a question for the user.

### 6. Conventions

Skim for:
- Style/format: `.editorconfig`, `.prettierrc`, `.eslintrc`, `checkstyle.xml`, `rustfmt.toml`, `.swiftformat`, `.clang-format`
- Pre-commit hooks: `.pre-commit-config.yaml`, `husky/`, `lefthook.yml`
- Commit conventions: `commitlint.config.*`, recent commit messages — is it conventional commits?
- Branch naming: recent branches — feature/X-Y? feat/X-Y? something else?
- PR template: `.github/pull_request_template.md`
- License: `LICENSE` file
- Code of conduct, contributing: `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`

### 7. Generate / update CLAUDE.md

Use the appropriate workspace template from `~/.claude/workspace-templates/` (mobile / web / firmware / devops) as a starting point. Fill it in from sections 1–6.

The `CLAUDE.md` MUST cover:
1. **What this repo is** — one paragraph.
2. **How to build/test/run** — exact commands.
3. **How to deploy** — or "not deployed from here, see <other repo>".
4. **Conventions** — style, branch naming, commit format.
5. **Tracker** — Jira project key + board URL, or GitHub Issues link.
6. **Session continuity** — pointer to `docs/SESSION-STATE.md` and `docs/TODO.md`.
7. **Open questions** — things you couldn't determine. Bring these to the user.

Show the proposed CLAUDE.md as a diff and ask before writing.

### 8. Hand off

Output a short summary:

```
## Onboarding: <repo-name>

**Domain:** <web | mobile | firmware | devops | ...>
**Stack:** <primary languages/frameworks>
**Tracker:** <Jira project | GitHub Issues>
**Build:** <one-line>
**Deploy:** <one-line or "not from here">

### CLAUDE.md
<created | updated> at `<repo>/CLAUDE.md`

### Open questions
1. ...
2. ...
```

## Rules

- Don't write code. Don't fix anything. Don't run destructive commands. This is read-only investigation plus one CLAUDE.md write.
- If the repo already has a complete, current `CLAUDE.md`, summarize what's there and ask whether the user wants a refresh anyway.
- Use the right workspace template for the domain. Don't fabricate sections that don't apply (e.g., no "Deploy" section for a pure library).
- Open questions are valuable — surfacing what you don't know is more useful than guessing.
- The `--quick` flag skips sections 4 and 5 and produces a stub CLAUDE.md from sections 1–3 only. Use when the user is impatient and accepts a partial pass.
