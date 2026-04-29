# Claude Code Configuration Module
# ================================
# Manages all Claude Code configuration files.
#
# Files managed:
#   - ~/.claude.json: MCP servers for non-plugin services (activation script, writable)
#   - ~/.claude/settings.json: User prefs like theme (activation script, writable)
#   - ~/.claude/settings.local.json: Permissions (activation script, writable)
#   - ~/.claude/CLAUDE.md: User-level memory (symlink, read-only)

{ config, pkgs, lib, inputs ? {}, ... }:

let
  homeDir = config.home.homeDirectory;

  # MCP Servers - only non-plugin servers belong here
  # GitHub and Atlassian removed: plugin:github:github and plugin:atlassian:atlassian
  # provide superset functionality via the enabled plugins
  mcpServers = {
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
  };

  # Permissions - consistent across machines
  # Based on "Always Allowed Commands" from ~/.ai/3-rules.md
  permissions = {
    allow = [
      # Linting
      "Bash(/opt/homebrew/bin/markdownlint-cli2:*)"

      # AI agents
      "Bash(pi:*)"
      "Bash(claude:*)"

      # File exploration
      "Bash(cd:*)"
      "Bash(ls:*)"
      "Bash(tree:*)"
      "Bash(find:*)"
      "Bash(fd:*)"
      "Bash(pwd:*)"
      "Bash(du:*)"
      "Bash(df:*)"
      "Bash(exa:*)"
      "Bash(eza:*)"
      "Bash(lsd:*)"
      "Bash(readlink:*)"
      "Bash(ncdu:*)"
      "Bash(gdu:*)"
      "Bash(dua:*)"
      "Bash(dust:*)"
      "Bash(duf:*)"
      "Bash(watch:*)"

      # File reading
      "Bash(cat:*)"
      "Bash(head:*)"
      "Bash(tail:*)"
      "Bash(less:*)"
      "Bash(more:*)"
      "Bash(wc:*)"
      "Bash(file:*)"
      "Bash(stat:*)"
      "Bash(bat:*)"
      "Bash(glow:*)"

      # Search
      "Bash(grep:*)"
      "Bash(rg:*)"
      "Bash(ack:*)"
      "Bash(ag:*)"
      "Bash(ast-grep:*)"
      "Bash(sg:*)"

      # Documentation/help
      "Bash(man:*)"
      "Bash(info:*)"
      "Bash(tldr:*)"
      "Bash(shelp:*)"
      "Bash(ghelp:*)"
      "Bash(git-help.sh:*)"
      "Bash(tmux-help.sh:*)"

      # Git (all operations)
      "Bash(git:*)"

      # Read AI config files (must use absolute path - tilde not expanded in permissions)
      "Read(${homeDir}/.ai/*)"

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
      "Bash(whoami:*)"
      "Bash(id:*)"
      "Bash(groups:*)"
      "Bash(uptime:*)"
      "Bash(w:*)"
      "Bash(tty:*)"
      "Bash(locale:*)"

      # macOS system info (read-only)
      "Bash(sw_vers:*)"
      "Bash(system_profiler:*)"
      "Bash(defaults read:*)"
      "Bash(defaults domains:*)"
      "Bash(launchctl list:*)"
      "Bash(mdfind:*)"
      "Bash(fastfetch:*)"

      # Process info
      "Bash(ps:*)"
      "Bash(pgrep:*)"
      "Bash(procs:*)"
      "Bash(lsof:*)"

      # Networking (read-only diagnostics)
      "Bash(ping:*)"
      "Bash(ping6:*)"
      "Bash(gping:*)"
      "Bash(prettyping:*)"
      "Bash(traceroute:*)"
      "Bash(mtr:*)"
      "Bash(dig:*)"
      "Bash(host:*)"
      "Bash(nslookup:*)"
      "Bash(doggo:*)"
      "Bash(ifconfig:*)"
      "Bash(netstat:*)"
      "Bash(arp:*)"
      "Bash(iperf3:*)"
      "Bash(xh:*)"

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

      # Compilers & linkers (general native toolchain)
      "Bash(make:*)"
      "Bash(gmake:*)"
      "Bash(bmake:*)"
      "Bash(gcc:*)"
      "Bash(g++:*)"
      "Bash(clang:*)"
      "Bash(clang++:*)"
      "Bash(cc:*)"
      "Bash(c++:*)"
      "Bash(ld:*)"
      "Bash(ar:*)"
      "Bash(as:*)"
      "Bash(nm:*)"
      "Bash(objcopy:*)"
      "Bash(objdump:*)"
      "Bash(readelf:*)"
      "Bash(size:*)"
      "Bash(strip:*)"
      "Bash(addr2line:*)"
      "Bash(c++filt:*)"
      "Bash(pkg-config:*)"
      "Bash(ldd:*)"
      "Bash(otool:*)"
      "Bash(install_name_tool:*)"
      "Bash(libtool:*)"
      "Bash(ranlib:*)"

      # Build systems (in addition to mvn / cmake / ninja / npm / cargo / west)
      "Bash(bazel:*)"
      "Bash(bazelisk:*)"
      "Bash(meson:*)"
      "Bash(autoreconf:*)"
      "Bash(autoconf:*)"
      "Bash(automake:*)"
      "Bash(scons:*)"

      # iOS / macOS native build (Xcode + Swift + CocoaPods + fastlane + Ruby)
      "Bash(xcodebuild:*)"
      "Bash(xcrun:*)"
      "Bash(xcode-select:*)"
      "Bash(xcbeautify:*)"
      "Bash(xcpretty:*)"
      "Bash(xcodes:*)"
      "Bash(swift:*)"
      "Bash(swiftc:*)"
      "Bash(swift-format:*)"
      "Bash(swiftformat:*)"
      "Bash(swiftlint:*)"
      "Bash(simctl:*)"
      "Bash(pod:*)"
      "Bash(cocoapods:*)"
      "Bash(fastlane:*)"
      "Bash(bundle:*)"
      "Bash(bundler:*)"
      "Bash(gem:*)"
      "Bash(rake:*)"
      "Bash(rbenv:*)"

      # Android / Kotlin / JVM build
      "Bash(gradle:*)"
      "Bash(gradlew:*)"
      "Bash(./gradlew:*)"
      "Bash(kotlinc:*)"
      "Bash(kotlin:*)"
      "Bash(ktlint:*)"
      "Bash(detekt:*)"
      "Bash(adb:*)"
      "Bash(emulator:*)"

      # Firmware (Zephyr/NCS/PlatformIO)
      "Bash(west:*)"
      "Bash(nrfutil:*)"
      "Bash(nrfjprog:*)"
      "Bash(pyocd:*)"
      "Bash(JLinkExe:*)"
      "Bash(JLinkGDBServer:*)"
      "Bash(cmake:*)"
      "Bash(ninja:*)"
      "Bash(platformio:*)"
      "Bash(pio:*)"
      "Bash(arm-none-eabi-gcc:*)"
      "Bash(arm-none-eabi-gdb:*)"
      "Bash(arm-none-eabi-size:*)"
      "Bash(arm-none-eabi-objcopy:*)"
      "Bash(openocd:*)"

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
      "Bash(nix eval:*)"
      "Bash(nix show-config:*)"
      "Bash(nix-env -q:*)"
      "Bash(nix profile list:*)"
      "Bash(nix-store --query:*)"
      "Bash(nix-instantiate --eval:*)"
      "Bash(darwin-rebuild check:*)"
      "Bash(home-manager build:*)"
      "Bash(home-manager generations:*)"
      "Bash(home-manager packages:*)"
      "Bash(home-manager option:*)"
      "Bash(home-manager info:*)"

      # Infrastructure-as-Code (read-only / safe)
      # `terraform apply` and `tofu apply` deliberately omitted — confirm before applying.
      "Bash(terraform plan:*)"
      "Bash(terraform validate:*)"
      "Bash(terraform init:*)"
      "Bash(terraform fmt:*)"
      "Bash(terraform output:*)"
      "Bash(terraform show:*)"
      "Bash(terraform graph:*)"
      "Bash(terraform providers:*)"
      "Bash(terraform state list:*)"
      "Bash(terraform state show:*)"
      "Bash(terraform version:*)"
      "Bash(terraform workspace list:*)"
      "Bash(terraform workspace show:*)"
      "Bash(tofu plan:*)"
      "Bash(tofu validate:*)"
      "Bash(tofu init:*)"
      "Bash(tofu fmt:*)"
      "Bash(tofu output:*)"
      "Bash(tofu show:*)"
      "Bash(tofu graph:*)"
      "Bash(tofu providers:*)"
      "Bash(tofu state list:*)"
      "Bash(tofu state show:*)"
      "Bash(tofu version:*)"
      "Bash(tofu workspace list:*)"
      "Bash(tofu workspace show:*)"
      "Bash(ansible --version:*)"
      "Bash(ansible-lint:*)"
      "Bash(ansible-playbook --check:*)"
      "Bash(ansible-playbook --syntax-check:*)"

      # Go (read-only)
      "Bash(go version:*)"
      "Bash(go env:*)"
      "Bash(go list:*)"
      "Bash(go doc:*)"
      "Bash(go vet:*)"

      # Read-only code analysis & linters
      "Bash(tokei:*)"
      "Bash(cloc:*)"
      "Bash(shellcheck:*)"
      "Bash(yamllint:*)"
      "Bash(sqlfluff lint:*)"
      "Bash(sqlfluff parse:*)"
      "Bash(gitleaks detect:*)"
      "Bash(gitleaks protect:*)"
      "Bash(semgrep scan:*)"
      "Bash(difft:*)"
      "Bash(difftastic:*)"

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
      "Bash(kubectx:*)"
      "Bash(kubens:*)"
      "Bash(stern:*)"
      "Bash(helm list:*)"
      "Bash(helm status:*)"
      "Bash(helm get:*)"
      "Bash(helm search:*)"
      "Bash(helm repo list:*)"

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
      "Bash(column:*)"
      "Bash(nl:*)"
      "Bash(fold:*)"
      "Bash(expand:*)"
      "Bash(unexpand:*)"
      "Bash(strings:*)"
      "Bash(xxd:*)"
      "Bash(hexdump:*)"
      "Bash(od:*)"
      "Bash(rev:*)"
      "Bash(tac:*)"
      "Bash(paste:*)"
      "Bash(join:*)"
      "Bash(comm:*)"
      "Bash(pv:*)"
      "Bash(sleep:*)"
      "Bash(seq:*)"
      "Bash(true:*)"
      "Bash(false:*)"

      # WezTerm
      "Bash(wezterm cli:*)"

      # Custom scripts (zsh functions)
      "Bash(zsh -ic:*)"

      # MCP - Atlassian plugin (all Jira + Confluence reads and writes)
      # Wildcard covers every tool exposed by the atlassian plugin: issue CRUD,
      # transitions, worklogs, comments, links, page CRUD, comment CRUD, search,
      # CQL/JQL, plus any new tools added by future plugin releases.
      "mcp__plugin_atlassian_atlassian__*"

      # MCP - CircleCI (read-only operations)
      "mcp__circleci-mcp-server__get_build_failure_logs"
      "mcp__circleci-mcp-server__find_flaky_tests"
      "mcp__circleci-mcp-server__get_latest_pipeline_status"
      "mcp__circleci-mcp-server__get_job_test_results"
      "mcp__circleci-mcp-server__config_helper"
      "mcp__circleci-mcp-server__list_followed_projects"
      "mcp__circleci-mcp-server__list_component_versions"

      # MCP - GitHub plugin (read operations)
      "mcp__plugin_github_github__get_file_contents"
      "mcp__plugin_github_github__search_repositories"
      "mcp__plugin_github_github__search_code"
      "mcp__plugin_github_github__search_issues"
      "mcp__plugin_github_github__search_pull_requests"
      "mcp__plugin_github_github__search_users"
      "mcp__plugin_github_github__get_commit"
      "mcp__plugin_github_github__get_label"
      "mcp__plugin_github_github__get_latest_release"
      "mcp__plugin_github_github__get_me"
      "mcp__plugin_github_github__get_release_by_tag"
      "mcp__plugin_github_github__get_tag"
      "mcp__plugin_github_github__get_team_members"
      "mcp__plugin_github_github__get_teams"
      "mcp__plugin_github_github__issue_read"
      "mcp__plugin_github_github__list_branches"
      "mcp__plugin_github_github__list_commits"
      "mcp__plugin_github_github__list_issue_types"
      "mcp__plugin_github_github__list_issues"
      "mcp__plugin_github_github__list_pull_requests"
      "mcp__plugin_github_github__list_releases"
      "mcp__plugin_github_github__list_tags"
      "mcp__plugin_github_github__pull_request_read"
      "mcp__plugin_github_github__get_pull_request"
      "mcp__plugin_github_github__get_pull_request_files"
      "mcp__plugin_github_github__get_pull_request_status"
      "mcp__plugin_github_github__get_pull_request_comments"
      "mcp__plugin_github_github__get_pull_request_reviews"

      # MCP - GitHub plugin (write operations for ticket tracking)
      "mcp__plugin_github_github__create_issue"
      "mcp__plugin_github_github__update_issue"
      "mcp__plugin_github_github__add_issue_comment"
      "mcp__plugin_github_github__issue_write"

      # Current working directory (where Claude was started)
      "Edit"
      "Write"
      "Bash(mkdir:*)"
      "Bash(touch:*)"
      "Bash(rm:*)"

      # Web access (read-only)
      "WebSearch"
      "WebFetch"
    ];
  };

  # GSD hooks and statusline are NOT managed here. The `npx get-shit-done-cc`
  # installer (run from home.activation.installGsd) writes its own hooks and
  # statusline entries into settings.json. Our syncClaudeUserSettings activation
  # does a merge (nix overlays on top of existing), so omitting `hooks` and
  # `statusLine` from userPrefs means npx's values stick.

  # User preferences - consistent across machines
  userPrefs = {
    theme = "dark";
    terminalBellOnPrompt = true;
    effortLevel = "high";

    # Plugins from anthropics/claude-plugins-official marketplace.
    #
    # Grouped by purpose for sanity. LSPs are silent until a relevant file is
    # open, so adding them is cheap. Skill-heavy plugins (workflow, review)
    # contribute to skill-resolution surface area — keep that count bounded.
    enabledPlugins = {
      # --- Core workflow ---
      "claude-code-setup@claude-plugins-official"      = true;
      "claude-md-management@claude-plugins-official"   = true;
      "commit-commands@claude-plugins-official"        = true;
      "context7@claude-plugins-official"               = true;
      "explanatory-output-style@claude-plugins-official" = true;
      "feature-dev@claude-plugins-official"            = true;
      "ralph-loop@claude-plugins-official"             = true;
      "skill-creator@claude-plugins-official"          = true;   # codify (was manually added on Dark-Horse)
      "superpowers@claude-plugins-official"            = true;

      # --- Code review / quality / security ---
      "code-review@claude-plugins-official"            = true;
      "code-simplifier@claude-plugins-official"        = true;
      "pr-review-toolkit@claude-plugins-official"      = true;
      "security-guidance@claude-plugins-official"      = true;

      # --- Semantic codebase navigation ---
      # Trial flip from false. Semantic indexing across 100+ repos is high-leverage.
      # Revisit after a week if it's noisy or competes with serena's MCP server.
      "serena@claude-plugins-official"                 = true;

      # --- Language servers (silent until relevant file is open) ---
      "clangd-lsp@claude-plugins-official"             = true;   # C/C++ for Zephyr/NCS firmware
      "gopls-lsp@claude-plugins-official"              = true;   # Go (occasional, cheap to keep on)
      "jdtls-lsp@claude-plugins-official"              = true;   # Java for QQQ
      "kotlin-lsp@claude-plugins-official"             = true;   # Android
      "pyright-lsp@claude-plugins-official"            = true;   # Python
      "rust-analyzer-lsp@claude-plugins-official"      = true;   # Rust
      "swift-lsp@claude-plugins-official"              = true;   # iOS
      "typescript-lsp@claude-plugins-official"         = true;   # TS/JS

      # --- Integrations (issue trackers, design, browser, source-of-truth) ---
      "agent-sdk-dev@claude-plugins-official"          = true;
      "atlassian@claude-plugins-official"              = true;
      "figma@claude-plugins-official"                  = true;
      "frontend-design@claude-plugins-official"        = true;
      "github@claude-plugins-official"                 = true;
      "playwright@claude-plugins-official"             = true;
    };

    # Additional MCP servers (settings.json scope)
    mcpServers = {
      sonarqube = {
        type = "stdio";
        command = "docker";
        args = [
          "run" "-i" "--rm"
          "-e" ("SONARQUBE_TOKEN=$" + "{SONARQUBE_TOKEN}")
          "-e" ("SONARQUBE_ORG=$" + "{SONARQUBE_ORG}")
          "mcp/sonarqube"
        ];
      };
    };
  };

  mcpServersJson = pkgs.writeText "mcp-servers.json" (builtins.toJSON mcpServers);
  permissionsJson = pkgs.writeText "permissions.json" (builtins.toJSON permissions);
  userPrefsJson = pkgs.writeText "user-prefs.json" (builtins.toJSON userPrefs);
in
{
  imports = [ ./skills.nix ];
  # CLAUDE.md - read-only symlink is fine
  home.file.".claude/CLAUDE.md".text = ''
    # Global Development Context

    ## File Hierarchy (load order)

    | Priority | File | Authority |
    |----------|------|-----------|
    | 1 | This file (`~/.claude/CLAUDE.md`) | Bootstrap, hierarchy, compaction recovery |
    | 2 | `~/.ai/3-rules.md` | Behavioral mandates (MUST/MUST NOT) — **binding** |
    | 3 | `~/.ai/2-coding-style.md` | Output formatting / code style — **normative** |
    | 4 | `~/.ai/1-profile.md` | Identity, role, environment — informational |
    | 5 | `~/.ai/4-preferences.yaml` | Machine-readable tuning knobs — advisory |
    | 6 | `~/.ai/5-learnings.md` | Operational notes / current ground truth — reference |
    | 7 | Project `CLAUDE.md` (and project style/contributing files) | Per-repo overrides — scoped |

    **Conflict resolution:** Higher priority wins on the dimension it owns. Project-level files MAY override `3-rules.md` for repo-scoped settings (allowed commands, module structure, language conventions) but MUST NOT weaken safety rules.

    `~/.ai/0-init.md` is a launcher only — not part of the hierarchy.

    ## Initialization

    Load all six files in `~/.ai/` and treat them as system-level configuration.
    Use `3-rules.md` as strict constraints, `2-coding-style.md` as output formatting standards, `1-profile.md` as context, `4-preferences.yaml` as tunable parameters, and `5-learnings.md` as current operational ground truth.

    ## Compaction Recovery (NON-NEGOTIABLE)

    After context compaction, the agent MUST re-read ALL `~/.ai/` files before continuing work. Compaction discards these files from context. Read them in this order:
    1. `~/.ai/3-rules.md`
    2. `~/.ai/2-coding-style.md`
    3. `~/.ai/1-profile.md`
    4. `~/.ai/4-preferences.yaml`
    5. `~/.ai/5-learnings.md`
    6. Active project `CLAUDE.md` (and any project-local style/contributing files)
    7. `./docs/SESSION-STATE.md` and `./docs/TODO.md` (if they exist)
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
      if ${pkgs.jq}/bin/jq --slurpfile prefs "${userPrefsJson}" '
        # Deep merge enabledPlugins to preserve manually-added plugins
        .enabledPlugins = ((.enabledPlugins // {}) * ($prefs[0].enabledPlugins // {}))
        | . * ($prefs[0] | del(.enabledPlugins))
      ' "$user_settings" > "$user_settings.tmp" \
        && [ -s "$user_settings.tmp" ]; then
        mv "$user_settings.tmp" "$user_settings"
        chmod 600 "$user_settings"
      else
        rm -f "$user_settings.tmp"
      fi
    fi
  '';

  # QQQ project-level CLAUDE.md bootstrap — drop the extracted QQQ rules
  # template into ~/Git.Local/QRun-IO/qqq/CLAUDE.md if the QQQ checkout exists
  # and doesn't already have one. Copy-if-missing only; once the file lands
  # in the QQQ repo, that repo owns it and subsequent rebuilds do nothing.
  # Silent no-op on machines without the QQQ checkout.
  home.activation.bootstrapQqqClaudeMd = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    qqq_dir="${homeDir}/Git.Local/QRun-IO/qqq"
    qqq_claude_md="$qqq_dir/CLAUDE.md"
    template_path="${./workspace-templates/qqq-CLAUDE.md}"

    if [ ! -d "$qqq_dir" ]; then
      exit 0
    fi

    if [ ! -f "$qqq_claude_md" ]; then
      cp "$template_path" "$qqq_claude_md"
      chmod 644 "$qqq_claude_md"
      echo "[qqq-bootstrap] Wrote CLAUDE.md template into $qqq_dir/. Review and commit from the QQQ checkout." >&2
    fi
  '';

  # Claude Code plugin marketplaces — declarative registration.
  # Without this, the enabledPlugins entries in settings.json silently fail
  # on a fresh machine because the marketplace isn't registered yet.
  # Idempotent: `claude plugin marketplace add` is a no-op when already added.
  # Non-fatal: skips silently if claude isn't on PATH yet (cold-start case).
  home.activation.installClaudePluginMarketplaces = lib.hm.dag.entryAfter [ "installNpmGlobals" ] ''
    export PATH="${homeDir}/.npm-global/bin:/opt/homebrew/opt/node@22/bin:$PATH"

    if ! command -v claude >/dev/null 2>&1; then
      echo "[claude-marketplaces] claude CLI not on PATH yet; skipping (will register on next rebuild)" >&2
      exit 0
    fi

    # Marketplaces we want present on every machine. Add new ones here.
    # Format: "<short-name>:<github-source>"
    marketplaces=(
      "claude-plugins-official:anthropics/claude-plugins-official"
    )

    current="$(claude plugin marketplace list 2>/dev/null || true)"
    for entry in "''${marketplaces[@]}"; do
      name="''${entry%%:*}"
      source="''${entry#*:}"
      if echo "$current" | grep -q "❯ $name$\|❯ $name "; then
        echo "[claude-marketplaces] $name already registered"
      else
        echo "[claude-marketplaces] Adding $name ($source)..."
        claude plugin marketplace add "$source" 2>&1 || \
          echo "[claude-marketplaces] WARN: add of $name failed; continuing" >&2
      fi
    done
  '';

  # GSD (Get-Shit-Done) — install/upgrade on every rebuild via upstream's
  # own installer. Brew-style: nix declares intent, npx owns the file layout.
  # Runs AFTER syncClaudeUserSettings so GSD's hooks/statusline writes to
  # settings.json aren't clobbered by our merge.
  #
  # Uses brew-managed node@22 (not pkgs.nodejs) because GSD's installer
  # internally runs `npm install -g .` to build its SDK, and `-g` writes to
  # NPM_CONFIG_PREFIX. Nix's nodejs pins its prefix to a read-only /nix/store
  # path, which fails with EACCES. node@22 + ~/.npm-global mirrors the
  # home/npm-globals pattern so everything lands in a user-writable tree.
  home.activation.installGsd = lib.hm.dag.entryAfter [ "syncClaudeUserSettings" "installNpmGlobals" ] ''
    export NPM_CONFIG_PREFIX="${homeDir}/.npm-global"
    # Include ~/.npm-global/bin so GSD's post-install PATH check (which looks
    # for gsd-sdk on PATH) passes. The interactive shell already gets this via
    # home.sessionPath, but activation runs with a minimal environment.
    export PATH="${homeDir}/.npm-global/bin:/opt/homebrew/opt/node@22/bin:$PATH"
    mkdir -p "$NPM_CONFIG_PREFIX"

    if [ ! -x "/opt/homebrew/opt/node@22/bin/npx" ]; then
      echo "[gsd] /opt/homebrew/opt/node@22/bin/npx not found; skipping (install node@22 via Homebrew first)" >&2
    else
      echo "[gsd] Installing/updating to latest..."
      if /opt/homebrew/opt/node@22/bin/npx -y get-shit-done-cc@latest --global 2>&1; then
        echo "[gsd] Install/update complete."
      else
        echo "[gsd] WARNING: Install/update failed — GSD may be stale or missing." >&2
      fi
    fi
  '';
}
