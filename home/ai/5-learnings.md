# Ongoing Tool and Workflow Learnings

## Confluence API

### Blog Posts vs Pages (v1 vs v2 API)
- **MCP Atlassian tools** (`getConfluencePage`, `updateConfluencePage`, `fetch`) use the **v2 pages API** which does NOT support blog posts. Calls with blog post IDs return 404.
- **Regular pages** work fine with MCP v2 tools -- use `contentFormat: "markdown"`
- **CQL search** (`searchConfluenceUsingCql`) finds blog posts -- use `type = blogpost` filter
- `createConfluencePage` creates pages only, not blog posts.
- When a page is "converted to blog post" in Confluence UI, the original page is trashed and a new blog post is created with a new ID.

### confluence-blog.sh -- ALWAYS USE THIS FOR BLOG POSTS
- **Location:** `~/.local/bin/confluence-blog.sh` (installed via Nix, always in PATH)
- **Source:** `~/config/nix/scripts/confluence-blog.sh`
- **Usage:**
  - Read: `confluence-blog.sh read <blog-id>` -- prints TITLE, VERSION, then ---BODY--- followed by storage-format HTML
  - Update: `confluence-blog.sh update <blog-id> <body-file>` -- reads body from file, auto-increments version, sends PUT
- **Workflow for updating a blog post:**
  1. `confluence-blog.sh read <id>` -- pipe body to a temp file if needed
  2. Edit the body file (storage-format HTML)
  3. `confluence-blog.sh update <id> <body-file>`
- **NEVER use raw curl commands for Confluence blog posts** -- always use this script
- Requires `CONFLUENCE_API_TOKEN` env var to be set

### Content Updates
- All updates (v1 and v2) require **full body replacement** -- no partial/diff updates
- Always fetch current content and version before updating to avoid conflicts
- `contentFormat: "markdown"` works for v2 MCP tools (pages only)

## ~/.ai/ File Management
- All files in `~/.ai/` are **Nix symlinks** (read-only) managed by Home Manager
- Source files live at: `~/config/nix/home/ai/`
- To add/update:
  1. Edit source file in `~/config/nix/home/ai/`
  2. If new, register in `default.nix` with `home.file.".ai/filename".source = ./filename;`
  3. Update `0-init.md` to reference new files
  4. Rebuild: `home-manager switch --flake ~/config/nix`
- `1-profile.md` is special -- inline in `default.nix`, not a separate source file
- Do NOT write to `~/.ai/` directly -- always edit the Nix source
