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

### kingsrook/qqq-orb — node_app_* jobs (added 0.6.5)
- `node_app_test_only` and `node_app_build` jobs for pnpm-based Next.js/Vite apps
- Requires `"typecheck": "tsc --noEmit"` script in package.json (default `typecheck_script` param)
- **qqq_helpers.sh fallback stubs:** Orb scripts source `qqq_helpers.sh` by path, but packed orbs inline scripts as YAML — the file doesn't exist on CI disk. Fix: add fallback stubs after the source attempt: `source ... 2>/dev/null || true; if ! type banner &>/dev/null; then banner() { ...; }; fi`
- **Cache key checksum failure:** `{{ checksum "pnpm-lock.yaml" }}` fails hard if the file doesn't exist. Never combine multiple lockfile checksums. Use per-pkg_manager conditional `restore_cache`/`save_cache` blocks.
- **corepack enable EACCES:** `cimg/node` images have pnpm pre-installed at `/usr/local/bin/pnpm` (owned by root). Check `command -v pnpm` first and skip corepack enable entirely if already available.
- **No private packages:** No `qqq-maven-registry-credentials` or npm registry context needed for this project.

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

### QQQ Admin UI — Flat URL Scheme
- QQQ routes are flat: `/app/{name}` for all entity types (apps, tables, processes). The app tree hierarchy is for sidebar visual grouping only — it does NOT appear in URLs. `use-routes.ts` must start `buildRoutes` with `parentPath = '/app'` and use flat `/app/{tableName}` paths for TABLE/PROCESS/REPORT nodes (not nested under their parent app).
