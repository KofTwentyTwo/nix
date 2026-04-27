# Coding Style Guide

> **Reference guide.** Behavioral mandates (MUST/MUST NOT) live in `3-rules.md`. Tunable knobs live in `4-preferences.yaml`. Project-scoped style (QQQ flower-box javadoc, dmdbrands per-repo conventions) lives in the relevant project's `CLAUDE.md` or `CODE_STYLE.md`.

## Active Domains

| Domain | Primary languages | Project-style file |
|---|---|---|
| QQQ framework | Java 17+ | `~/Git.Local/QRun-IO/qqq/CODE_STYLE.md` and `~/Git.Local/QRun-IO/qqq/CLAUDE.md` |
| dmdbrands web | TypeScript / Next.js / React | per-repo `CLAUDE.md` |
| dmdbrands mobile | Swift, Kotlin | per-repo `CLAUDE.md` |
| dmdbrands firmware | C/C++ on Zephyr/NCS | per-repo `CLAUDE.md` |
| dmdbrands devops | Terraform, HCL, YAML, shell | per-repo `CLAUDE.md` |
| Personal tooling | Rust, Python, shell, Nix | this file |
| This Nix config | Nix | this file (Nix section) |

When the active project has its own style file, that file wins for project-scoped conventions. This file owns universal principles and language idioms.

---

## General Principles

1. **Write for maintainability.** Code is read far more than written.
2. **Be explicit over clever.** Clarity beats brevity.
3. **Follow established patterns in the active codebase.** Consistency is a feature.
4. **Document the *why*, not the *what*.** Names handle the what.
5. **Test at the appropriate level.** Unit for logic, integration for interactions, end-to-end sparingly.
6. **Automate quality.** Linters, formatters, and CI gates over docstrings asking nicely.
7. **DRY, but not too dry.** Three similar lines is better than a premature abstraction.
8. **YAGNI.** Don't build for hypotheticals.
9. **Fail fast.** Validate at boundaries; don't smother errors.
10. **Match the surrounding code.** When existing patterns and these principles disagree on a project, the existing patterns win.

---

## Universal Comment Discipline

- Default to no comments. Names should do most of the work.
- Add a comment only when the *why* is non-obvious: hidden constraints, subtle invariants, workarounds for specific bugs, behavior that would surprise a reader.
- Don't explain *what* the code does. The code does that.
- Don't reference the current task, fix, ticket, or caller ("used by X", "added for Y", "handles case from #123"). That belongs in the PR description and rots fast.
- No zombie code (commented-out blocks). If it's not used, delete it. The history is in git.
- Project-scoped comment styles (QQQ flower-box, etc.) live in their project files.

---

## Naming Conventions (per language)

### Java
- Classes: `PascalCase` — `OrderService`, `CustomerEntity`
- Methods/variables: `camelCase` — `processOrder()`, `orderTotal`
- Constants: `UPPER_SNAKE_CASE` — `MAX_RETRY_COUNT`
- Packages: `lowercase.dotted` — `com.example.module`

### TypeScript / JavaScript
- Types/Classes/Components: `PascalCase` — `OrderService`, `<UserCard />`
- Functions/variables: `camelCase` — `processOrder`, `orderTotal`
- Constants: `UPPER_SNAKE_CASE` for module-level immutables; `camelCase` for local ones
- Files: `kebab-case.ts` for utilities, `PascalCase.tsx` for components, `camelCase.ts` if the codebase uses that
- Type vs. interface: prefer `type` aliases unless the codebase has decided otherwise; use `interface` for declaration-merging or class shape

### Swift (iOS)
- Types: `PascalCase`
- Methods/variables: `camelCase`
- Acronyms preserve case in declarations (`URLSession`, `urlSession` per Swift API guidelines)
- Constants: `camelCase` (Swift convention; not `UPPER_SNAKE_CASE`)

### Kotlin (Android)
- Types: `PascalCase`
- Functions/properties: `camelCase`
- Constants in `companion object`: `UPPER_SNAKE_CASE`
- Files: match the primary class name (`OrderService.kt`)

### C/C++ (Zephyr/NCS firmware)
- Functions: `snake_case` matching Zephyr style — `device_init`, `gpio_pin_configure`
- Macros/constants: `UPPER_SNAKE_CASE`
- Types: `snake_case_t` suffix for typedefs (Zephyr convention) — `struct device`, `gpio_dt_spec`
- Match the surrounding driver/subsystem; Zephyr is consistent and you should be too

### Rust
- Types/structs/enums: `PascalCase`
- Functions/variables/modules: `snake_case`
- Constants/statics: `UPPER_SNAKE_CASE`

### Python
- Classes: `PascalCase`
- Functions/variables: `snake_case`
- Constants: `UPPER_SNAKE_CASE`
- Private: `_leading_underscore`

### Nix
- Attributes: `camelCase` — `homeDirectory`, `userName`
- Packages: `kebab-case` — `nix-darwin`, `home-manager`
- Files: `default.nix` for module entry, otherwise `kebab-case.nix`

### Shell (Bash/Zsh)
- Variables: `UPPER_SNAKE_CASE` (env-style) or `lower_snake_case` for local — match the script
- Functions: `snake_case`
- Files: `kebab-case.sh`

### Terraform / HCL
- Resources: `snake_case` for local names (`aws_s3_bucket "media_library"`)
- Variables/outputs: `snake_case`
- Modules: `snake_case` directories

### YAML (k8s, GitHub Actions, CircleCI)
- Keys: per-tool convention. K8s uses `camelCase` for spec keys; GitHub Actions uses `kebab-case`; CircleCI uses `snake_case`. Match the schema.

---

## File & Project Structure

Conventions follow each ecosystem's defaults. Examples:

### TypeScript (Next.js app router)
```
app/
├── (marketing)/
│   ├── page.tsx
│   └── layout.tsx
├── api/
│   └── route.ts
components/
├── ui/                          # primitive components
└── feature-name/                # feature-scoped components
lib/                             # framework-agnostic utilities
```

### Zephyr application
```
app/
├── CMakeLists.txt
├── prj.conf                     # Kconfig overrides
├── sample.yaml
├── boards/                      # board overlays per target
│   └── nrf52840dk_nrf52840.overlay
├── src/
│   └── main.c
└── zephyr/
    └── module.yml
```

### Terraform (recommended layout)
```
terraform/
├── modules/                     # reusable modules
│   └── module-name/
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
├── environments/
│   ├── dev/
│   ├── staging/
│   └── prod/
└── shared/                      # state backend, providers
```

### Java (Maven multi-module — QQQ shape)
```
project/
├── pom.xml                      # parent POM
├── module-name/
│   ├── pom.xml
│   └── src/{main,test}/{java,resources}/
```

### Nix (this repo)
```
~/.config/nix/
├── flake.nix
├── flake.lock
├── modules/                     # system-level (homebrew, rectangle)
└── home/                        # home-manager modules
    ├── default.nix              # entry point
    └── <concern>/
        ├── default.nix
        └── ...
```

---

## Error Handling

### Universal principles
- Validate at system boundaries (user input, external APIs, file I/O); trust internal code.
- Fail with information: include the offending value, the expected shape, the operation.
- Don't catch-and-swallow. Don't catch-and-log-only — let the caller decide.
- Don't add fallbacks for impossible cases.

### Java
```java
// Specific exceptions, with context
throw new QUserFacingException("Order #" + orderId + " not found");

// try-with-resources for any AutoCloseable
try (Connection conn = dataSource.getConnection())
{
   // ...
}

// Validate early
Objects.requireNonNull(order, "order");
```

### TypeScript
```ts
// Throw Error subclasses, not strings
class OrderNotFoundError extends Error {
  constructor(public orderId: string) {
    super(`Order ${orderId} not found`);
  }
}

// Result types when error is part of the contract
type Result<T, E = Error> = { ok: true; value: T } | { ok: false; error: E };
```

### Rust
```rust
// Result + ? for recoverable errors
fn process_order(id: OrderId) -> Result<Order, ProcessError> {
    let order = load_order(id)?;
    validate_order(&order)?;
    Ok(order)
}

// thiserror for library errors, anyhow for application errors
```

### C (Zephyr)
- Return `int` error codes (negative errno values) per Zephyr convention.
- Use `LOG_ERR()` / `LOG_WRN()` / `LOG_INF()` / `LOG_DBG()` from the logging subsystem.
- Don't use `errno` from libc inside Zephyr code.

### Python
```python
# Specific exception types
raise ValueError(f"Invalid order ID: {order_id}")

# Context managers for resources
with open(config_path) as f:
    config = json.load(f)
```

---

## Logging Conventions

### Universal
- Structured logging beats string concatenation. Pass key/value pairs (or use a structured logger) so logs are queryable.
- Log levels: `error` for failures requiring action, `warn` for recoverable issues, `info` for normal flow milestones, `debug` for diagnostic detail. ~95% of "error" logging should actually be `warn`.
- Never `console.log`/`println`/`System.out.println` in production code.
- Don't log secrets, tokens, PII, or device identifiers without explicit policy.
- Healthcare context: dmdbrands work may eventually fall under HIPAA. Treat patient/device data as sensitive even before the formal policy lands.

### TypeScript (Pino/Winston example)
```ts
log.info({ orderId, customerId }, 'processing order');
log.warn({ orderId, err }, 'failed to send notification');
```

### Java (QQQ uses QLogger — see QQQ CLAUDE.md for the full convention)
```java
LOG.info("Processing order", logPair("orderId", orderId));
LOG.warn("Failed to send notification", e, logPair("orderId", orderId));  // exception BEFORE pairs
```

### C (Zephyr)
```c
LOG_MODULE_REGISTER(my_driver, CONFIG_MY_DRIVER_LOG_LEVEL);

LOG_INF("device init: %s", dev->name);
LOG_WRN("retry %d", attempt);
LOG_ERR("init failed (%d)", err);
```

---

## Git Commit Messages (universal)

### Format (Conventional Commits)
```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types
`feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`, `perf`, `build`, `ci`

### Rules
- Subject line under 72 characters.
- Body (if needed): 1–2 sentences max.
- Reference the ticket: `feat(MH-123): ...` for Jira; `fix(#45): ...` or `Closes #45` in body for GitHub.
- All commits GPG-signed (configured globally; do not hardcode the key).
- No AI attribution (no "Generated by Claude", "Co-Authored-By: Claude", etc.).

### Examples
```
feat(telemetry): batch device events before upload

Reduces MQTT publish frequency from ~1Hz to ~0.1Hz when
non-critical events accumulate. Hard-real-time events still
publish immediately via the priority topic.

Closes MH-417
```

```
fix(auth): handle null refresh token from new device flow
```

---

## Language Quick References

### TypeScript / JavaScript

- Use `strict` TypeScript. Don't use `any`; use `unknown` and narrow.
- Prefer named exports for utilities, default export for the primary symbol of a file (component, page, API route).
- Use `async/await`; avoid raw promise chains for new code.
- Don't reach for utility libraries (lodash, ramda) when modern JS does the job.
- React: prefer functional components and hooks; co-locate component, types, and small helpers in one file until they earn separation.
- Next.js (App Router): keep server components by default; use `'use client'` only when needed.

### Swift (iOS)

- Follow Swift API design guidelines (clarity at point of use).
- Prefer `let` over `var`; prefer value types (struct/enum) until you need reference semantics.
- `guard` for early returns; avoid pyramid-of-doom optionals.
- SwiftUI when possible; UIKit when integrating with existing screens.

### Kotlin (Android)

- Prefer `val` over `var`; data classes for value types; sealed classes/interfaces for state machines.
- Coroutines + Flow for async; structured concurrency.
- Jetpack Compose when possible; XML layouts only when required.

### C/C++ on Zephyr/NCS

- Match the Zephyr coding style (Linux kernel-derived: tabs, K&R braces, 80-column soft limit).
- Use the Zephyr device model: `DEVICE_DT_DEFINE`, `DEVICE_DT_GET`, `gpio_dt_spec`, etc.
- Configure via Kconfig + devicetree, not hardcoded constants.
- Use the logging subsystem (`LOG_MODULE_REGISTER`, `LOG_*`), not `printk` in production code.
- Be explicit about thread/ISR/preemption context for every function. Mark with comments when non-obvious.
- nRF Connect SDK: prefer NCS-provided abstractions over raw Nordic HAL when both exist.

### Rust

- `cargo fmt` + `cargo clippy --all-targets`; treat warnings as errors in CI.
- `Result<T, E>` for fallible operations; `Option<T>` for absence.
- `thiserror` for library errors, `anyhow` for application code.
- Avoid `unwrap()` outside tests and prototypes.

### Python

- `ruff` (or Black) for formatting, `mypy` for types where the codebase opts in.
- Type hints on public APIs.
- Dataclasses for value types; pydantic when validation is needed.
- Avoid mutable default arguments. Avoid implicit globals.

### Shell (Bash/Zsh)

- Always `#!/usr/bin/env bash`.
- `set -euo pipefail` at the top.
- Quote variable expansions: `"${VAR}"`.
- `[[ ... ]]` over `[ ... ]`.
- Functions for any logic that runs more than once. `local` for function-scoped variables.
- Provide `usage()` for any user-facing script.

### Nix

- Module pattern: `{ config, pkgs, lib, ... }: { ... }` with imports at the top.
- `let ... in { ... }` for local bindings.
- `home.file.<path>.text` for inline content; `home.file.<path>.source` for tracked files; `home.activation.<name>` for procedural setup.
- Comments explain the *why*: pinning rationale, security/order constraints, brew-vs-nix tradeoffs.
- Don't hardcode hostnames; route through `userConfig` or per-host overrides.

### Terraform / HCL

- One concern per module; environments compose modules with their own variable values.
- Pin provider versions in `required_providers`.
- Remote state with locking (S3 + DynamoDB, or Terraform Cloud).
- Run `terraform fmt` and `terraform validate` in pre-commit / CI.
- `apply` always requires explicit human confirmation. The Claude Code allowlist deliberately omits it.

### YAML

- 2-space indentation, no tabs.
- Quote ambiguous strings (e.g., `"yes"`, `"no"`, `"on"`, `"off"`, version numbers like `"1.0"`).
- Schema validation in CI when the tool supports it (k8s `kubeconform`, GitHub Actions `actionlint`).

---

## Project-Scoped Style References

These supersede this file inside their respective trees:

- **QQQ** — `~/Git.Local/QRun-IO/qqq/CLAUDE.md` and `~/Git.Local/QRun-IO/qqq/CODE_STYLE.md`. Owns: 3-space Java indentation, flower-box javadoc, `com.kingsrook.*` import order, wrapper-types-over-primitives, fluent-style setters, MetaDataProducer/RecordEntity patterns, V1 middleware endpoint specs, QLogger logging convention, `BooleanUtils.isTrue()` for nullable booleans, `BaseTest`/JUnit conventions, Maven multi-module structure, Checkstyle config.
- **dmdbrands repos** — per-repo `CLAUDE.md` owns repo conventions. The `local--brownfield-onboarding` skill produces or updates those files.
- **Personal tooling repos** — per-repo `CLAUDE.md` if the repo has earned one; otherwise this file.
