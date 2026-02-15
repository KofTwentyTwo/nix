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

### confluence-blog.sh: ALWAYS USE THIS FOR BLOG POSTS
- **Location:** `~/.local/bin/confluence-blog.sh` (installed via Nix, always in PATH)
- **Source:** `~/config/nix/scripts/confluence-blog.sh`
- **Usage:**
  - Read: `confluence-blog.sh read <blog-id>` (prints TITLE, VERSION, then ---BODY--- followed by storage-format HTML)
  - Update: `confluence-blog.sh update <blog-id> <body-file>` (reads body from file, auto-increments version, sends PUT)
- **Workflow for updating a blog post:**
  1. `confluence-blog.sh read <id>` (pipe body to a temp file if needed)
  2. Edit the body file (storage-format HTML)
  3. `confluence-blog.sh update <id> <body-file>`
- **NEVER use raw curl commands for Confluence blog posts.** Always use this script.
- Requires `CONFLUENCE_API_TOKEN` env var to be set

### Full-Width Layout (MANDATORY for all pages and blog posts)
Every Confluence page or blog post we create or edit MUST be full-width. Three things to set:

1. **Page-level appearance property:** Set `content-appearance-published` and `content-appearance-draft` properties via v1 REST API. Value must be the **string** `"full-width"` (NOT `{"appearance": "full-width"}`).
   ```
   POST /rest/api/content/{id}/property
   {"key": "content-appearance-published", "value": "full-width"}
   {"key": "content-appearance-draft", "value": "full-width"}
   ```
2. **Tables:** All `<table>` tags in storage format must have `data-layout="full-width"` (never `"default"`).
3. **Code blocks:** All `<ac:structured-macro ac:name="code">` tags should have `data-layout="full-width"` attribute added. Note: this sets the storage format attribute; ADF `codeBlock` nodes may not pick up `layout` the same way tables do.

**Workflow for new pages:**
1. Create page via MCP `createConfluencePage` (markdown)
2. Set both appearance properties via v1 REST API
3. Fetch storage format via v1 API, replace `data-layout="default"` with `data-layout="full-width"` on all tables and code macros, PUT back via v1 API

**Workflow for edits:**
- Before pushing any update, check and fix `data-layout="default"` to `"full-width"` in storage format
- Verify appearance properties are set

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
