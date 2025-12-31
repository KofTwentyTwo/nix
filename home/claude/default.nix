# Claude Code Configuration Module
# ================================
# Manages all Claude Code configuration files.
#
# Files managed:
#   - ~/.claude.json: MCP servers (activation script, writable)
#   - ~/.claude/settings.json: User prefs like theme (activation script, writable)
#   - ~/.claude/settings.local.json: Permissions (activation script, writable)
#   - ~/.claude/CLAUDE.md: User-level memory (symlink, read-only)

{ config, pkgs, lib, ... }:

let
  homeDir = config.home.homeDirectory;

  # MCP Servers - consistent across machines
  mcpServers = {
    github = {
      type = "stdio";
      command = "npx";
      args = [ "-y" "@modelcontextprotocol/server-github" ];
      env = {
        GITHUB_TOKEN = "$" + "{GITHUB_TOKEN}";
      };
    };
    qqq-mcp = {
      type = "http";
      url = "http://localhost:8080/mcp";
    };
    circleci-mcp-server = {
      type = "stdio";
      command = "npx";
      args = [ "-y" "@circleci/mcp-server-circleci@latest" ];
      env = {
        CIRCLECI_TOKEN = "$" + "{CIRCLECI_TOKEN}";
      };
    };
    atlassian = {
      type = "sse";
      url = "https://mcp.atlassian.com/v1/sse";
    };
  };

  # Permissions - consistent across machines
  # Based on "Always Allowed Commands" from ~/.ai/3-rules.md
  permissions = {
    allow = [
      # Linting
      "Bash(/opt/homebrew/bin/markdownlint-cli2:*)"

      # File exploration
      "Bash(ls:*)"
      "Bash(tree:*)"
      "Bash(find:*)"
      "Bash(fd:*)"
      "Bash(pwd:*)"

      # File reading
      "Bash(cat:*)"
      "Bash(head:*)"
      "Bash(tail:*)"
      "Bash(less:*)"
      "Bash(wc:*)"
      "Bash(file:*)"
      "Bash(stat:*)"

      # Search
      "Bash(grep:*)"
      "Bash(rg:*)"
      "Bash(ack:*)"
      "Bash(ag:*)"

      # Git read-only (commits/push require approval)
      "Bash(git status:*)"
      "Bash(git diff:*)"
      "Bash(git log:*)"
      "Bash(git branch:*)"
      "Bash(git show:*)"
      "Bash(git blame:*)"
      "Bash(git stash list:*)"
      "Bash(git remote:*)"
      "Bash(git fetch:*)"
      "Bash(git rev-parse:*)"
      "Bash(git ls-files:*)"
      "Bash(git ls-tree:*)"
      "Bash(git config --get:*)"
      "Bash(git config --list:*)"

      # System info
      "Bash(which:*)"
      "Bash(whereis:*)"
      "Bash(type:*)"
      "Bash(env:*)"
      "Bash(printenv:*)"
      "Bash(uname:*)"
      "Bash(hostname:*)"
      "Bash(date:*)"
      "Bash(echo:*)"
      "Bash(printf:*)"

      # Process info
      "Bash(ps:*)"
      "Bash(pgrep:*)"

      # Temp files (safe sandbox)
      "Bash(mktemp:*)"
      "Bash(touch /tmp/*)"
      "Bash(mkdir /tmp/*)"
      "Bash(rm /tmp/*)"
      "Bash(cat /tmp/*)"
      "Bash(ls /tmp/*)"

      # Java/Maven
      "Bash(mvn:*)"
      "Bash(java -version:*)"
      "Bash(javac -version:*)"

      # JavaScript/Node
      "Bash(npm:*)"
      "Bash(npx:*)"
      "Bash(yarn:*)"
      "Bash(pnpm:*)"
      "Bash(node:*)"

      # Rust
      "Bash(cargo:*)"
      "Bash(rustc:*)"
      "Bash(rustup:*)"

      # Python
      "Bash(python:*)"
      "Bash(python3:*)"
      "Bash(pip:*)"
      "Bash(pip3:*)"
      "Bash(pytest:*)"
      "Bash(poetry:*)"
      "Bash(pipenv:*)"
      "Bash(uv:*)"
      "Bash(ruff:*)"
      "Bash(black:*)"
      "Bash(mypy:*)"
      "Bash(flake8:*)"
      "Bash(isort:*)"
      "Bash(pylint:*)"
      "Bash(pydoc:*)"
      "Bash(virtualenv:*)"
      "Bash(pip-compile:*)"
      "Bash(pip-sync:*)"

      # Nix (read-only)
      "Bash(nix flake check:*)"
      "Bash(nix flake show:*)"
      "Bash(nix flake metadata:*)"
      "Bash(nix search:*)"
      "Bash(nix-env -q:*)"
      "Bash(nix profile list:*)"
      "Bash(darwin-rebuild check:*)"
      "Bash(home-manager build:*)"

      # Docker (read-only)
      "Bash(docker ps:*)"
      "Bash(docker images:*)"
      "Bash(docker logs:*)"
      "Bash(docker inspect:*)"
      "Bash(docker-compose ps:*)"
      "Bash(docker-compose logs:*)"

      # Kubernetes (read-only)
      "Bash(kubectl get:*)"
      "Bash(kubectl describe:*)"
      "Bash(kubectl logs:*)"
      "Bash(kubectl config:*)"
      "Bash(k9s:*)"
      "Bash(helm list:*)"
      "Bash(helm status:*)"
      "Bash(helm get:*)"

      # Misc utilities
      "Bash(jq:*)"
      "Bash(yq:*)"
      "Bash(curl:*)"
      "Bash(wget:*)"
      "Bash(gh:*)"
      "Bash(brew:*)"
      "Bash(realpath:*)"
      "Bash(dirname:*)"
      "Bash(basename:*)"
      "Bash(sed:*)"
      "Bash(awk:*)"
      "Bash(sort:*)"
      "Bash(uniq:*)"
      "Bash(cut:*)"
      "Bash(tr:*)"
      "Bash(xargs:*)"
      "Bash(tee:*)"
      "Bash(diff:*)"
      "Bash(md5:*)"
      "Bash(shasum:*)"
      "Bash(base64:*)"
      "Bash(pbcopy:*)"
      "Bash(pbpaste:*)"
      "Bash(open:*)"

      # WezTerm
      "Bash(wezterm cli:*)"

      # Custom scripts (zsh functions)
      "Bash(zsh -ic:*)"

      # MCP - Atlassian (read-only operations)
      "mcp__atlassian__atlassianUserInfo"
      "mcp__atlassian__getAccessibleAtlassianResources"
      "mcp__atlassian__getConfluenceSpaces"
      "mcp__atlassian__getConfluencePage"
      "mcp__atlassian__getPagesInConfluenceSpace"
      "mcp__atlassian__getConfluencePageFooterComments"
      "mcp__atlassian__getConfluencePageInlineComments"
      "mcp__atlassian__getConfluencePageDescendants"
      "mcp__atlassian__searchConfluenceUsingCql"
      "mcp__atlassian__getJiraIssue"
      "mcp__atlassian__getTransitionsForJiraIssue"
      "mcp__atlassian__getJiraIssueRemoteIssueLinks"
      "mcp__atlassian__getVisibleJiraProjects"
      "mcp__atlassian__getJiraProjectIssueTypesMetadata"
      "mcp__atlassian__getJiraIssueTypeMetaWithFields"
      "mcp__atlassian__searchJiraIssuesUsingJql"
      "mcp__atlassian__lookupJiraAccountId"
      "mcp__atlassian__search"
      "mcp__atlassian__fetch"

      # MCP - CircleCI (read-only operations)
      "mcp__circleci-mcp-server__get_build_failure_logs"
      "mcp__circleci-mcp-server__find_flaky_tests"
      "mcp__circleci-mcp-server__get_latest_pipeline_status"
      "mcp__circleci-mcp-server__get_job_test_results"
      "mcp__circleci-mcp-server__config_helper"
      "mcp__circleci-mcp-server__list_followed_projects"
      "mcp__circleci-mcp-server__list_component_versions"

      # MCP - GitHub (read-only operations)
      "mcp__github__get_file_contents"
      "mcp__github__search_repositories"
      "mcp__github__search_code"
      "mcp__github__search_issues"
      "mcp__github__search_users"
      "mcp__github__get_issue"
      "mcp__github__list_issues"
      "mcp__github__get_pull_request"
      "mcp__github__list_pull_requests"
      "mcp__github__get_pull_request_files"
      "mcp__github__get_pull_request_status"
      "mcp__github__get_pull_request_comments"
      "mcp__github__get_pull_request_reviews"
      "mcp__github__list_commits"
    ];
  };

  # User preferences - consistent across machines
  userPrefs = {
    theme = "dark";
    terminalBellOnPrompt = true;
  };

  mcpServersJson = pkgs.writeText "mcp-servers.json" (builtins.toJSON mcpServers);
  permissionsJson = pkgs.writeText "permissions.json" (builtins.toJSON permissions);
  userPrefsJson = pkgs.writeText "user-prefs.json" (builtins.toJSON userPrefs);
in
{
  # CLAUDE.md - read-only symlink is fine
  home.file.".claude/CLAUDE.md".text = ''
    # Global Development Context

    See @~/.ai/0-init.md for initialization guidelines
    See @~/.ai/1-profile.md for profile information
    See @~/.ai/2-coding-style.md for coding style standards
    See @~/.ai/3-rules.md for development rules
    See @~/.ai/4-preferences.yaml for preferences
  '';

  # ~/.claude.json - merge mcpServers, preserve user data
  # IMPORTANT: This script is defensive - it won't overwrite if jq fails
  home.activation.syncClaudeJson = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    claude_json="${homeDir}/.claude.json"

    if [ ! -f "$claude_json" ]; then
      ${pkgs.jq}/bin/jq -n --slurpfile mcp "${mcpServersJson}" \
        '{ mcpServers: $mcp[0], hasCompletedOnboarding: true }' > "$claude_json"
      chmod 600 "$claude_json"
    else
      # Only update if jq succeeds (prevents data loss)
      if ${pkgs.jq}/bin/jq --slurpfile mcp "${mcpServersJson}" \
        '.mcpServers = $mcp[0] | .hasCompletedOnboarding = true' "$claude_json" > "$claude_json.tmp" \
        && [ -s "$claude_json.tmp" ]; then
        mv "$claude_json.tmp" "$claude_json"
        chmod 600 "$claude_json"
      else
        rm -f "$claude_json.tmp"
      fi
    fi
  '';

  # ~/.claude/settings.local.json - merge permissions, preserve user data
  home.activation.syncClaudeSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    settings_json="${homeDir}/.claude/settings.local.json"
    mkdir -p "${homeDir}/.claude"

    if [ ! -f "$settings_json" ] || [ ! -s "$settings_json" ]; then
      ${pkgs.jq}/bin/jq -n --slurpfile perms "${permissionsJson}" '{ permissions: $perms[0] }' > "$settings_json"
      chmod 600 "$settings_json"
    else
      if ${pkgs.jq}/bin/jq --slurpfile perms "${permissionsJson}" '.permissions = $perms[0]' "$settings_json" > "$settings_json.tmp" \
        && [ -s "$settings_json.tmp" ]; then
        mv "$settings_json.tmp" "$settings_json"
        chmod 600 "$settings_json"
      else
        rm -f "$settings_json.tmp"
      fi
    fi
  '';

  # ~/.claude/settings.json - user preferences (theme, etc.)
  home.activation.syncClaudeUserSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    user_settings="${homeDir}/.claude/settings.json"
    mkdir -p "${homeDir}/.claude"

    if [ ! -f "$user_settings" ] || [ ! -s "$user_settings" ]; then
      ${pkgs.jq}/bin/jq -n --slurpfile prefs "${userPrefsJson}" '$prefs[0]' > "$user_settings"
      chmod 600 "$user_settings"
    else
      if ${pkgs.jq}/bin/jq --slurpfile prefs "${userPrefsJson}" '. * $prefs[0]' "$user_settings" > "$user_settings.tmp" \
        && [ -s "$user_settings.tmp" ]; then
        mv "$user_settings.tmp" "$user_settings"
        chmod 600 "$user_settings"
      else
        rm -f "$user_settings.tmp"
      fi
    fi
  '';
}
