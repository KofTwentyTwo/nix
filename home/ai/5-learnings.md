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
