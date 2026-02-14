# Ongoing Tool and Workflow Learnings

## Confluence API

### Blog Posts vs Pages (v1 vs v2 API)
- **MCP Atlassian tools** (`getConfluencePage`, `updateConfluencePage`, `fetch`) use the **v2 pages API** which does NOT support blog posts. Calls with blog post IDs return 404.
- **Blog posts require the v1 REST API** via `curl`:
  - Read: `GET /wiki/rest/api/content/{id}?expand=body.storage,version`
  - Update: `PUT /wiki/rest/api/content/{id}` with version increment and full body replacement
  - Content format for v1 is `storage` (Confluence XHTML), not `markdown`
- **CQL search** (`searchConfluenceUsingCql`) finds blog posts -- use `type = blogpost` filter
- **Regular pages** work fine with MCP v2 tools -- use `contentFormat: "markdown"`
- `createConfluencePage` creates pages only, not blog posts. Use v1 API with `type: "blogpost"` for blog posts.
- When a page is "converted to blog post" in Confluence UI, the original page is trashed and a new blog post is created with a new ID.

### Content Updates
- All updates (v1 and v2) require **full body replacement** -- no partial/diff updates
- Always fetch current content and version before updating to avoid conflicts
- v1 API updates require incrementing `version.number` by 1
- `contentFormat: "markdown"` works for v2 MCP tools only

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
