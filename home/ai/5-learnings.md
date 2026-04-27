# Ongoing Tool and Workflow Learnings

## General Output Rules

- **Never use `--` (double dash) in any output.** Use proper punctuation (periods, commas, colons, semicolons, or em dash `—`) instead. This applies to all generated content: documentation, comments, Jira tickets, Slack messages, Confluence pages, commit messages, and conversational responses.

## Confluence API

### Blog Posts vs Pages (v1 vs v2 API)
- **MCP Atlassian tools** (`getConfluencePage`, `updateConfluencePage`, `fetch`) use the **v2 pages API** which does NOT support blog posts. Calls with blog post IDs return 404.
- **Regular pages** work fine with MCP v2 tools. Use `contentFormat: "markdown"`
- **CQL search** (`searchConfluenceUsingCql`) finds blog posts. Use `type = blogpost` filter
- `createConfluencePage` creates pages only, not blog posts.
- When a page is "converted to blog post" in Confluence UI, the original page is trashed and a new blog post is created with a new ID.

### confluence.sh: USE THIS FOR ALL CONFLUENCE CONTENT
- **Location:** `~/.local/bin/confluence.sh` (installed via Nix, always in PATH)
- **Source:** `~/config/nix/scripts/confluence.sh`
- **Auto-detects** content type (page vs blogpost) from the API response
- **Usage:**
  - Read: `confluence.sh read <id>` (prints TYPE, TITLE, VERSION, then ---BODY--- with storage-format HTML)
  - Update: `confluence.sh update <id> <body-file>` (updates content, auto-fixes full-width layout)
  - Fix layout: `confluence.sh fix-layout <id>` (fixes full-width layout without changing body)
- **Workflow for updating any content:**
  1. `confluence.sh read <id>` (pipe body to a temp file if needed)
  2. Edit the body file (storage-format HTML)
  3. `confluence.sh update <id> <body-file>` (auto-fixes tables, code blocks, appearance properties)
- **NEVER use raw curl commands for Confluence.** Always use this script or MCP tools.
- **After creating pages via MCP:** run `confluence.sh fix-layout <id>` to set full-width properties
- Requires `CONFLUENCE_API_TOKEN` env var
- Legacy `confluence-blog.sh` still works but `confluence.sh` is preferred

### Full-Width Layout (MANDATORY, handled by confluence.sh)
Every Confluence page or blog post we create or edit MUST be full-width. The `confluence.sh` script handles all of this automatically on `update` and `fix-layout`:
1. Sets `content-appearance-published` and `content-appearance-draft` properties to `"full-width"`
2. Fixes `data-layout="default"` to `data-layout="full-width"` on all tables
3. Adds `data-layout="full-width"` to code block macros that lack it

**Blog post version bumps:** The v1 REST API silently ignores blog post body updates that result in identical content (no version increment). Use the **v2 API** (`PUT /api/v2/blogposts/{id}`) for blog post version bumps; it works reliably.

### Content Updates
- All updates (v1 and v2) require **full body replacement**. No partial/diff updates.
- Always fetch current content and version before updating to avoid conflicts.
- `contentFormat: "markdown"` works for v2 MCP tools (pages only)

## ~/.ai/ File Management
- All files in `~/.ai/` are **Nix symlinks** (read-only) managed by Home Manager
- Source files live at: `~/config/nix/home/ai/`
- To add/update:
  1. Edit source file in `~/config/nix/home/ai/`
  2. If new, register in `default.nix` with `home.file.".ai/filename".source = ./filename;`
  3. Update `0-init.md` to reference new files
  4. Rebuild: `home-manager switch --flake ~/config/nix`
- `1-profile.md` is special: inline in `default.nix`, not a separate source file
- Do NOT write to `~/.ai/` directly. Always edit the Nix source.

## CircleCI / Faber Orb

### cimg/base executor
- **No python/pip installed.** Use `apt-get install` for Python tools (e.g., `yamllint`), not `pip3 install`.
- Has curl, tar, git, sudo, and standard Unix tools.

### GitHub Release Asset URL Quirks
- **kustomize**: Path segment uses URL-encoded slash: `kustomize%2Fv{VERSION}` (not `kustomize/v{VERSION}`)
- **kube-linter**: Assets use OS-only filenames (`kube-linter-linux.tar.gz`), no `_amd64` arch suffix
- **kubesec**: Standard pattern with OS and arch (`kubesec_linux_amd64.tar.gz`)
- Always verify actual release asset names on GitHub before writing install scripts.

### CircleCI Deploy Keys
- **Read-only.** Cannot `git push` tags or branches. Use `gh release create` API or HTTPS with `x-access-token:${GITHUB_TOKEN}`.

### yq Boolean Handling
- `yq '.field // true'` treats `false` as falsy and returns `true`. Read raw value first, then check explicitly in bash.

### CD/GitOps Repo Linting
- YAML lint in CD repos should be **non-blocking** (always exit 0). Helm-rendered manifests have trailing spaces and indentation quirks from template engines that aren't real problems.

### Workspace Persistence
- `attach_workspace: at: .` overwrites `.git/` if workspace was persisted with `root: .`. Always `checkout` first, then `attach_workspace`.
- For kustomize output, persist with `root: /tmp/kustomize-output` and attach at the same path to avoid conflicts.

## Munitor Orb (`kof22/munitor`)

### Image Tagging (export_version_vars.sh)
- `main` branch: clean semver only (e.g., `0.1.0`). No env tag, no `main` or `latest` alias.
- `develop`: `{semver}-SNAPSHOT.{sha}` + env tag `develop`
- `staging`: `{semver}-staging.{sha}` + env tag `staging`
- `release/*`: `{semver}-rc.{sha}` (no env tag)
- Feature branches: `{semver}-{sanitized-branch}-{sha}-SNAPSHOT` (no env tag)

### CD Repo Update (update_cd_repo.sh)
- Clones the CD repo, updates kustomization.yaml via yq, commits, pushes.
- For kustomize format: updates `overlays/{environment}/kustomization.yaml` using `(.images[] | select(.name == "{image}")).newTag`
- Default env names: `develop`, `staging`, `prod`. Override via `.munitor.yml` `cd.env.*` if CD repo uses different directory names (e.g., `cd.env.develop: dev`, `cd.env.prod: production`).

### ArgoCD Image Updater Conflict
- Do NOT use ArgoCD Image Updater alongside Munitor's `update-cd-repo` job. They compete and overwrite each other's tags within seconds. Image Updater replaces Munitor's version tags with digest hashes (dev/staging) or rewrites them to branch names (prod).
- When Munitor handles CD updates, remove all `argocd-image-updater.argoproj.io/*` annotations from ArgoCD Application resources.

### yq Empty String Handling
- `yq '.field // "default"'` treats `""` (empty string) as falsy and returns `"default"`. When empty string is a valid value (e.g., `base_path: ""`), use an explicit null check: `yq -e '.field != null' file &>/dev/null` then read the raw value.

### Bash Default Substitution: `:-` vs `-`
- `${VAR:-default}` uses default for both **unset** AND **empty**. `${VAR-default}` only uses default when **unset**. Use `-` (not `:-`) when an empty string is a valid value that should be preserved (e.g., `KUSTOMIZE_BASE_PATH=""` meaning "skip base build").

### Orb Stable Release Required for Consumer Setup Config
- Consumer `.circleci/config.yml` references the orb directly (e.g., `kof22/munitor@1`). If no stable release exists, CircleCI rejects the config at parse time with "Cannot find orb in registry". Both the setup config AND `.munitor.yml` `orb_version` must use `dev:snapshot` until a stable release is cut.

### Same-SHA Multi-Branch Push
- Pushing the same commit to multiple branches (e.g., staging + main fast-forward) causes CircleCI to run separate pipelines but GitHub commit statuses merge across all pipelines for that SHA. This makes it hard to distinguish per-branch CI results via the status API.

### kingsrook/qqq-orb — node_app_* jobs (added 0.6.5)
- `node_app_test_only` and `node_app_build` jobs for pnpm-based Next.js/Vite apps
- Requires `"typecheck": "tsc --noEmit"` script in package.json (default `typecheck_script` param)
- **qqq_helpers.sh fallback stubs:** Orb scripts source `qqq_helpers.sh` by path, but packed orbs inline scripts as YAML — the file doesn't exist on CI disk. Fix: add fallback stubs after the source attempt: `source ... 2>/dev/null || true; if ! type banner &>/dev/null; then banner() { ...; }; fi`
- **Cache key checksum failure:** `{{ checksum "pnpm-lock.yaml" }}` fails hard if the file doesn't exist. Never combine multiple lockfile checksums. Use per-pkg_manager conditional `restore_cache`/`save_cache` blocks.
- **corepack enable EACCES:** `cimg/node` images have pnpm pre-installed at `/usr/local/bin/pnpm` (owned by root). Check `command -v pnpm` first and skip corepack enable entirely if already available.
- **No private packages:** No `qqq-maven-registry-credentials` or npm registry context needed for this project.

## ArgoCD

### AppProject Permissions Must Be Wide
Restrictive AppProject CRDs (single namespace destination, limited resource whitelists) cause "not permitted to use project" errors on the Application. Use wildcard destinations (`name: "*", namespace: "*", server: "*"`), all resource types whitelisted (`group: "*", kind: "*"`), and `sourceNamespaces: [argocd]`. If fixing an AppProject doesn't resolve the error, delete and recreate the Application to clear the cached rejection.

### ExternalSecret Operator Default Fields Cause Drift
The ESO adds default values to fields not specified in the manifest (e.g., `deletionPolicy: Retain`, `conversionStrategy: Default`, `decodingStrategy: None`, `metadataPolicy: None`, `engineVersion: v2`, `mergePolicy: Replace`). ArgoCD sees these as drift. Include all operator-defaulted fields explicitly in Helm templates.

### ExternalSecret API Version
Use `external-secrets.io/v1`, not `v1beta1`. Newer clusters may not have the beta CRD installed.

### Tracking Label: One Owner Per Resource
ArgoCD uses the `argocd.argoproj.io/instance` label to track which Application owns a resource. Only one Application can own a given resource. If multiple Applications manage the same resource (e.g., via a shared/ directory included by all envs), each sync overwrites the tracking label and causes the other apps to report OutOfSync, creating a perpetual sync cycle. **Fix:** Shared resources (AppProject, SealedSecrets for repo-creds) must be owned by a single dedicated root Application, not included by multiple apps.

### ignoreDifferences for Controller-Managed Fields
SealedSecrets controller mutates `/status` after apply. AppProject status fields also drift. Use `ignoreDifferences` with `jqPathExpressions: [".status"]` on Applications that manage these resources to avoid false OutOfSync.

## Next.js / MSW Development

### MSW Race Condition with Next.js Auth
- When using MSW for mocking and an auth provider that fires API calls on mount, the service worker must be fully started BEFORE any children render. The fix: gate rendering of the provider tree behind a `mockReady` state in `providers.tsx` — only render children after `worker.start()` resolves.

### MSW Handler URL Patterns
- MSW handler `BASE` URL should use hardcoded path (`/qqq/v1`), NOT `process.env.NEXT_PUBLIC_API_BASE_URL`. The env var is unreliable in the service worker context and at handler module-load time. Use path-only patterns and MSW will match against the current origin.

### Next.js Route Groups in URLs
- Route group directory names (e.g., `(auth)`, `(dashboard)`) NEVER appear in the browser URL. Redirects must use `/login` not `/(auth)/login`. This applies everywhere: `router.push()`, `redirect()`, `href` attributes.

### Next.js Stale .next Cache
- After adding new packages or significant code changes, the `.next/` build cache can serve stale manifests causing Internal Server Errors. Fix: `rm -rf .next && pnpm dev`.

### lucide-react Named Import Shadowing
- Never import `{ File }` from `lucide-react` — it shadows the global browser `File` constructor, breaking `instanceof File` checks. Rename: `import { File as FileIcon } from 'lucide-react'`.

### Next.js App Router — Multiple Dynamic Segments at Same Depth
- You CANNOT have multiple dynamic route directories at the same depth (e.g., `[appName]/`, `[tableName]/`, `[processName]/` as siblings). Next.js only allows one dynamic segment per directory level. Solution: use a single `[slug]` and resolve the type at render time via metadata lookup.

### Jest + ESM Modules (react-markdown, remark-gfm, etc.)
- `react-markdown`, `remark-gfm`, `rehype-raw`, etc. are pure ESM packages. Jest with `ts-jest` preset cannot import them directly (SyntaxError: Unexpected token 'export').
- **Fix:** Extract pure logic (parsing, slugify, etc.) into separate utility files that don't import React/ESM components, then test those directly. Don't try to import React component files that transitively pull in ESM-only deps.
- Alternative: add `transformIgnorePatterns` to jest.config.cjs to transform specific node_modules, but extracting pure logic is cleaner.

### CSS `group-focus-within` Keeps Dropdowns Open After Navigation
- Tailwind `group-focus-within:` utility keeps dropdown menus visible as long as any child has focus. After clicking a link and navigating (client-side), focus remains on the now-invisible link element, keeping the dropdown open.
- **Fix:** Use `useEffect` watching `usePathname()` to blur the active element when pathname changes:
  ```typescript
  useEffect(() => {
    if (containerRef.current?.contains(document.activeElement)) {
      ;(document.activeElement as HTMLElement)?.blur()
    }
  }, [pathname])
  ```

### QQQ Admin UI — Flat URL Scheme
- QQQ routes are flat: `/app/{name}` for all entity types (apps, tables, processes). The app tree hierarchy is for sidebar visual grouping only — it does NOT appear in URLs. `use-routes.ts` must start `buildRoutes` with `parentPath = '/app'` and use flat `/app/{tableName}` paths for TABLE/PROCESS/REPORT nodes (not nested under their parent app).

### JSDoc + ESLint jsdoc/require-jsdoc
- The `jsdoc/require-jsdoc` rule requires the JSDoc block to **directly precede** the export it annotates. If a type alias, interface, or any other declaration is inserted between the JSDoc block and the function/export, the function is seen as undocumented and the rule fires. Always place helper type declarations (e.g. `type Foo = ...`) **above** the JSDoc block, not between it and the function.

### Test localStorage Isolation
- When a component test writes to `localStorage` (e.g. a dismiss callback that persists state), subsequent tests in the same `describe` block will initialise with that stale value — even though each test renders a fresh component. Fix: add `beforeEach(() => localStorage.clear())` at the top of any `describe` block that tests components with localStorage persistence (e.g. Banner, ColumnConfig, SavedViews).

### Stateful Regex with `g` Flag in React Render
- A regex created with `new RegExp(pattern, 'gi')` and reused across multiple `.test()` calls in a `.map()` loop is stateful — `lastIndex` advances after each match, causing alternating true/false results. When using `split(captureGroupRegex)` to highlight matches, odd-indexed parts (`i % 2 !== 0`) are always the captured matches — use index parity instead of `regex.test(part)` to avoid the stale `lastIndex` bug entirely.

### Next.js App Router: Async Layout Blocks All Children
- An `async` Layout component blocks ALL `{children}` from rendering until every `await` in the Layout resolves. If Layout fetches nav data (menus, blogs for dropdowns), every page is delayed by those API calls. Fix: make Layout synchronous and wrap data-dependent parts (header, footer) in `<Suspense>` around async server components (e.g., `AsyncHeader`, `AsyncFooter`). Children render immediately.

### React `cache()` for API Deduplication
- Next.js App Router calls `generateMetadata()` and the page component in the same request. Without `cache()`, identical API calls execute twice. Wrapping exported API functions in React `cache()` deduplicates within a single request. Cache keys must match exactly: `getBlogPosts(slug, 1)` and `getBlogPosts(slug)` are different cache keys even if page 1 is the default.

### Next.js `remotePatterns` Image Domain Security
- Using `hostname: '**'` in `next.config.mjs` `images.remotePatterns` allows ANY external domain to serve images through the Next.js image optimizer, which is a security risk. Restrict to known domains (e.g., `*.kof22.com`). For dev with mock data using placeholder domains like `example.com`, conditionally allow them only when `MOCK_API=true`.

### OpenAPI Generated Code: Do Not Modify runtime.ts
- The `runtime.ts` file in OpenAPI-generated API clients is auto-generated and will be overwritten on spec regeneration. Apply cross-cutting concerns (timeouts, logging, auth) via the `Configuration` middleware chain in `client.ts`, not by editing generated files. For fetch timeouts, wrap the `fetchApi` function with an `AbortController` timeout wrapper.

## Munitor Orb — CD Environment Key Names

### cd.env Keys Are Fixed Convention Names, Not Branch Names
- The munitor orb's `extract_munitor_vars.sh` reads `.cd.env.develop`, `.cd.env.staging`, `.cd.env.prod` as hardcoded yq paths. The key names (`develop`, `staging`, `prod`) are **convention names in the orb**, not git branch names.
- The **values** (e.g., `dev`, `staging`, `production`) map to overlay directory names in the CD repo (e.g., `overlays/production/`).
- The orb templates hardcode `only: main` as the branch filter for the production workflow. So `prod: production` means "when building main branch, update `overlays/production/` in the CD repo."
- Using a custom key like `main: production` causes the orb to miss `.cd.env.prod`, falling back to the default `"prod"`, which looks for `overlays/prod/` (doesn't exist).

### Orb Version Pinning
- Pin to minor version (e.g., `kof22/munitor@0.2`) to float with patch updates. Avoid `@dev:snapshot` in staging/production.

### test.setup Behavior (node-webapp pipeline)
- `test.setup` in `.munitor.yml` is NOT a shell command string and NOT an npm script name. It expects an executable command name resolvable in PATH. Neither shell strings (`corepack enable && ...`) nor npm script names (`ci:setup`) work — both produce "Test setup script 'X' not found."
- For pnpm projects on `cimg/node:22`, pnpm is pre-installed. **Remove `test.setup` entirely** and put any needed setup as the first `test.commands` entry if necessary.

### gitleaks — Scanning Git History
- gitleaks scans the **full git history** by default, not just the working tree. Dev credentials in old commits are flagged even after deletion.
- Add `.gitleaks.toml` with `[allowlist] regexes = [...]` to suppress known dev placeholder values.
- File-path-based allowlisting covers those paths across all commits.

### semgrep — child_process and Shell Injection
- `child_process` functions used with template literals are flagged by semgrep's `detect-child-process` rule.
- The `// nosemgrep` inline comment is blocked by a security hook in this codebase when the offending pattern is present.
- **Correct fix:** Use `execFileSync("cmd", ["subcmd", ...argsArray])` instead of shell-interpolated strings. Eliminates the finding AND the real injection risk.
- Applied to `packages/api/src/services/job-scheduler.ts` in praesidium.

### package-lock.json in pnpm Projects
- This project uses pnpm but Munitor CI always runs `npm ci` first. The root `package-lock.json` must be tracked in git.
- Do NOT add `package-lock.json` to `.gitignore` for this project.
- Regenerate after package name changes: `npm install --package-lock-only --ignore-scripts`

### Health Check Step Order (v0.2.2+)
- `build_push_supplemental` must run BEFORE `health_check` so the migrations image is in local Docker cache
- `docker_push_ghcr` must run BEFORE `build_push_supplemental` because it does `docker login`
- Correct order: `docker_build` -> `trivy` -> `docker_push_ghcr` -> `build_push_supplemental` -> `health_check`
- For dev/staging branches, prior tags exist in GHCR so the old order worked. New version tags (prod) fail because nothing to pull.

### Maven SNAPSHOT Resolution (v0.2.3+)
- `mvn_build.sh` now includes `-U` flag to force SNAPSHOT updates on every build
- Without `-U`, CircleCI Maven cache serves stale SNAPSHOTs even after new ones are published
- This caused builds to silently use old dependency versions

## Me Health Portal — Dev Kubernetes Environment (Authentik)

### Dev Authentik Has No Pre-Created Portal Users
- The local Docker blueprint (`docker/blueprints/me-health-portal.yaml`) creates test users (`cs-rep`, `cs-admin`, `system-admin`, etc.) with `password: admin123`. These only exist in local Docker.
- The k8s dev blueprint (`overlays/dev/authentik-blueprints-patch.yaml` in the CD repo) creates NO users — only groups, flows, stages, and the OAuth2 provider.
- To log in to the dev portal, users must be manually created in the Authentik admin UI at `auth-dev.me.health` and added to an appropriate group.

### akadmin Cannot Log Into the Portal Without Group Membership
- `akadmin` is the Authentik bootstrap superuser. Its JWT has no `mhCompanyId`, `mhAllAccess`, or `policies` claims because it belongs to no Me Health groups.
- The portal will log `akadmin` in via OAuth2 but show empty data everywhere (security filters reject all queries).
- Fix: add `akadmin` to the `internal-admin` group in Authentik. That group has `mhAllAccess: true`, which bypasses company security filters.

### Dev Environment Credentials
- Authentik admin: `auth-dev.me.health` — username `akadmin`, password `MeHealth-Dev-2026`
- Portal: `portal-dev.me.health` — requires Authentik user with Me Health group membership

## Nix + Claude Code Configuration

### Flake evaluator only sees git-tracked files

Nix flakes evaluate against the git tree, not the working directory. New untracked files referenced by Nix paths (`${./path/to/file}`, `home.file."x".source = ./y`) are invisible to the evaluator and produce errors like:

```
error: Path 'home/claude/workspace-templates/qqq-CLAUDE.md' in the repository "..." is not tracked by Git.
```

Fix: `git add <path>` (no commit needed). Staging alone makes the file visible to flake evaluation. This bites whenever activation scripts or `home.file` entries reference newly-created files in this Nix repo. `nix flake check` may pass (it doesn't evaluate activation scripts) and the failure surfaces only at `darwin-rebuild switch`.

### Claude Code plugin marketplace vs enabledPlugins

`settings.json` `enabledPlugins.<name>@<marketplace> = true` only marks a plugin as enabled. The actual install requires the marketplace itself to be registered first. On a fresh machine without the marketplace, every entry in `enabledPlugins` silently fails to install.

Fix in `home/claude/default.nix` is the `installClaudePluginMarketplaces` activation script: runs `claude plugin marketplace add anthropics/claude-plugins-official` idempotently. Add new marketplaces there, not just to `enabledPlugins`.

CLI commands:
- `claude plugin marketplace list` — inspect what's registered
- `claude plugin marketplace add <github-org/repo>` — idempotent add
- `claude plugin list` — see installed plugins
- `claude plugin install <name>@<marketplace>` — manual install (the activation handles auto-install on enable)

### Compound-command permission decomposition

Claude Code splits commands separated by `&&`, `||`, `;`, and `|` and matches each part independently against `permissions.allow`. So `cd:*` plus `git:*` is enough to allow `cd /some/path && git status` without a separate compound-pattern entry. Keep the allowlist atomic; rely on decomposition for chains.

This means `Bash(cd:*)` is broad in scope (allows any `cd`) but safe in practice because the chained command must also match an allowed pattern. Adding `cd:*` does not implicitly allow `cd /tmp && rm -rf ~` — the `rm -rf ~` part still needs to match an allow rule (it doesn't, so it'd prompt).

### Defensive jq deep-merge for settings.json

`home/claude/default.nix` uses defensive `jq` activation scripts to merge Nix-declared values over existing `settings.json` content rather than overwriting. Two patterns matter:

1. **Preserve user state**: `enabledPlugins` is deep-merged so manually-added plugins (claude-hud, supabase, skill-creator on this machine) survive a rebuild even though they're not in the Nix-declared map.
2. **Preserve foreign-managed sections**: `hooks` and `statusLine` are deliberately omitted from the Nix-declared `userPrefs` because GSD's `npx get-shit-done-cc` installer writes them. The `* (... | del(.enabledPlugins))` jq pattern lets the merge layer Nix values on top while leaving GSD's writes intact.

Don't add `hooks` or `statusLine` management to the Nix module without rewriting the merge logic — you'll clobber GSD's authoritative entries.

## QRun-IO Discussions (Daily Build Log)

### Publishing recipe

Daily build log posts go to the "Daily Build Log" category of the `QRun-IO/qqq` repo discussions. Voice/tone preferences live in `4-preferences.yaml` under `blog_writing`. Posting is a single GraphQL mutation:

- **Location URL:** `https://github.com/orgs/QRun-IO/discussions/categories/daily-build-log`
- **Repository ID:** `R_kgDOHu3fHQ`
- **Category ID:** `DIC_kwDOHu3fHc4C0kC3`

```bash
gh api graphql -f query='
mutation {
  createDiscussion(input: {
    repositoryId: "R_kgDOHu3fHQ",
    categoryId: "DIC_kwDOHu3fHc4C0kC3",
    title: "YOUR_TITLE",
    body: "YOUR_BODY_WITH_ESCAPED_QUOTES"
  }) {
    discussion { url }
  }
}'
```

Body uses GitHub-flavored markdown. Escape internal double quotes when embedding in the GraphQL string. Returns the discussion URL on success.

## Healthcare Context (dmdbrands)

dmdbrands is a healthcare device company. HIPAA / BAA / PHI handling is a future layer not yet formalized in this rules system. Until that layer lands:

- Treat any patient data, device telemetry tied to a person, or clinical metadata as sensitive — same caution level as credentials.
- Don't include such data in logs, error messages, AI prompts to external services, or commit messages without explicit policy.
- When in doubt, ask before logging or transmitting.

## Calico CNI / Kubernetes Networking

### `to: []` in Calico NetworkPolicy = DENY
- An empty `to:` array (`to: []`) in a Calico NetworkPolicy egress rule means "match no destinations" = effectively deny. Omit `to:` entirely to mean "all destinations."

### LoadBalancer VIPs Unreachable via ipBlock
- Calico evaluates NetworkPolicy AFTER kube-proxy DNAT. Traffic to a LoadBalancer VIP (e.g., `10.120.208.205:443`) gets rewritten to `backend-pod:8443` before Calico sees it. The original port 443 rule never matches.
- Fix: Use `podSelector` rules for in-cluster services. Generic `ports:` rules (no `to:`) only work for external IPs (no DNAT).

### CoreDNS Override for Internal Service Access
- Use CoreDNS `template` plugin to resolve specific hostnames to ClusterIPs, bypassing LoadBalancer VIP hairpin issues
- Example: `auth.kof22.com` -> Authentik ClusterIP `172.19.49.208` so backend pods reach Authentik directly
