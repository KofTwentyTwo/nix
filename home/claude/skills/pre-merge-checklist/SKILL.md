---
name: pre-merge-checklist
description: "Pre-merge validation gate. Runs the structured checklist that must pass before a PR can be merged: tests green, lint clean, no zombie code, no untracked TODOs, dependencies audited, docs/changelog updated where applicable. Use when user asks 'is this ready to merge', 'pre-merge check', or before any merge operation."
when_to_use: "Before merging a PR; when the user asks if a branch is ready; before tagging a release. Distinct from review-pr (which evaluates the *changes*); this evaluates *merge readiness*."
argument-hint: "[pr-number | --branch <name> | --strict]"
---

# Pre-Merge Checklist

Validate that a branch is ready to merge. Run the checks, report pass/fail per item, and never auto-merge.

## Inputs

- Current branch (default), or
- `--branch <name>`, or
- `pr-number` (looks up the head ref via `gh pr view`)

`--strict` mode requires all "Should" items to pass, not just "Must" items.

## Sequence

Run all checks in parallel. Each check returns one of: PASS, FAIL, SKIP (not applicable), WARN (passed but with caveats).

### Must Pass (blocks merge)

#### 1. CI green
```bash
gh pr checks <id>
# or for current branch:
gh run list --branch $(git rev-parse --abbrev-ref HEAD) --limit 1 --json conclusion,name
```
FAIL if any required check is failing or pending.

#### 2. Tests run locally
Run the project's test command. Detect from:
- `package.json` `scripts.test` → `npm test` / `pnpm test`
- `pom.xml` → `mvn test`
- `Cargo.toml` → `cargo test`
- `pytest.ini` / `pyproject.toml` → `pytest`
- `west.yml` → `west twister` (Zephyr) or repo-specific

If the project has no tests, mark SKIP and note it (don't silently pass).

#### 3. Lint / format clean
Run the project's linter and formatter check. Common patterns:
- `npm run lint`, `pnpm lint`, `eslint .`
- `prettier --check .`
- `cargo clippy --all-targets`
- `cargo fmt --check`
- `ruff check .`, `black --check .`, `mypy`
- `mvn checkstyle:check`
- `terraform fmt -check`, `terraform validate`

#### 4. No zombie code introduced
Diff vs base for commented-out code blocks. Heuristic:
```bash
git diff <base>...HEAD | grep -E '^\+\s*(//|#|--)' | grep -vE '^\+\s*(//|#|--)\s*[A-Z]|TODO|FIXME|NOTE|HACK'
```
Look for commented-out code that's clearly code (function calls, assignments, control flow) rather than explanatory comments. WARN on suspicious blocks; user decides.

#### 5. No new secrets
```bash
gitleaks detect --source . --no-git --verbose
```
FAIL on any finding. Suppress known false positives via `.gitleaks.toml` allowlist (see `~/.ai/5-learnings.md` Munitor section for the pattern).

#### 6. Conflicts resolved
```bash
git merge-tree $(git merge-base <base> HEAD) HEAD <base> | grep -E '^(<<<<<<<|=======|>>>>>>>)'
```
FAIL if any conflict markers exist.

### Should Pass (FAIL in --strict, WARN otherwise)

#### 7. New TODOs are tracked
```bash
git diff <base>...HEAD | grep -E '^\+.*\b(TODO|FIXME|XXX|HACK)\b'
```
For each new TODO/FIXME, check that it references a ticket (`MH-123`, `(#45)`, `Closes #45`). Untracked TODOs become tech debt.

#### 8. Public API / contract changes are documented
If the diff touches:
- OpenAPI specs
- Protobuf files
- Exported route handlers
- TypeScript public types
- Java public classes/methods marked for SDK consumers

…check whether `CHANGELOG.md`, `docs/`, or migration notes were updated. WARN if not.

#### 9. Dependency changes are audited
If `package.json` / `pom.xml` / `Cargo.toml` / `go.mod` / `west.yml` changed:
- New dependencies should have a justification in the PR description
- Major version bumps should be flagged
- Run advisory check: `npm audit`, `cargo audit`, `mvn dependency-check:check` (if configured)

WARN on findings; the human decides.

#### 10. Migration files (if applicable) are reversible
If schema/migration files added:
- For SQL: check that the migration has a corresponding rollback (or is documented as one-way)
- For Liquibase/Flyway: check changelog entry format
- For Terraform: check `terraform plan` output for unexpected destroys

### Conditional (when triggered)

#### 11. Healthcare / PHI sensitivity (dmdbrands healthcare repos)
If the repo or diff touches anything PHI-adjacent:
- No patient data in logs (search for hardcoded names, MRNs, device serials)
- No PII in test fixtures committed to git
- Encryption-at-rest configuration unchanged or strengthened
- Access control unchanged or stricter

This is a manual flag. Always WARN-level; HIPAA review is a human responsibility per `~/.ai/3-rules.md` section 13.

#### 12. Firmware sanity (Zephyr/NCS repos)
If `prj.conf`, `*.overlay`, or `Kconfig*` changed:
- Build for all targeted boards (don't just rely on one)
- Verify no debug-only configs (`CONFIG_LOG_DEFAULT_LEVEL=4`, `CONFIG_DEBUG_THREAD_INFO`) left enabled in release configs
- Check stack/heap sizes haven't been quietly reduced

#### 13. Infrastructure sanity (Terraform repos)
If `*.tf` changed:
- `terraform plan` clean (no unexpected destroys)
- State backend not modified inadvertently
- No `terraform.tfstate*` files committed

## Output

Single-screen summary:

```
Pre-merge: <repo> / <branch> → <base>

Must:
  [PASS] CI green
  [PASS] Tests run locally
  [FAIL] Lint clean — eslint reported 3 errors
  [PASS] No zombie code
  [PASS] No new secrets
  [PASS] No conflicts

Should (--strict mode: required):
  [WARN] 2 new TODOs without ticket references
  [PASS] Public API changes documented
  [SKIP] No dependency changes
  [N/A]  No migrations

Conditional:
  [PASS] Firmware sanity — release configs unchanged

Verdict: BLOCKED — fix lint errors before merge.
```

End with a one-line verdict: `READY TO MERGE`, `READY WITH WARNINGS (n)`, or `BLOCKED (reason)`.

## Rules

- Never auto-merge or auto-approve. This skill produces a recommendation; the human decides.
- Don't run destructive commands. `terraform plan` is fine; `terraform apply` is not.
- For tests, prefer `--quiet` or summary output. Stream the full output only on FAIL.
- If you can't determine the right test/lint command, ask once. Don't skip silently.
