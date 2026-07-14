# Claude Code Configuration Module
# ================================
# Manages Claude Code installation + configuration.
#
# Binary installation:
#   - ~/.local/bin/claude → ~/.local/share/claude/versions/<ver>/ (native installer)
#     Bootstrapped once via bootstrapClaude; self-updates afterward.
#
# Files managed:
#   - ~/.claude.json: MCP servers for non-plugin services (activation script, writable)
#   - ~/.claude/settings.json: User prefs like theme (activation script, writable)
#   - ~/.claude/settings.local.json: Permissions (activation script, writable)
#   - ~/.claude/CLAUDE.md: User-level memory (symlink, read-only)

{ config, pkgs, lib, inputs ? {}, machineConfig ? {}, ... }:

let
  homeDir = config.home.homeDirectory;
  isWsl = machineConfig.isWsl or false;

  # MCP Servers - only non-plugin servers belong here
  # GitHub and Atlassian removed: plugin:github:github and plugin:atlassian:atlassian
  # provide superset functionality via the enabled plugins
  mcpServers = {
    circleci-mcp-server = {
      type = "stdio";
      command = "npx";
      args = [ "-y" "@circleci/mcp-server-circleci@0.17.0" ];
      env = {
        CIRCLECI_TOKEN = "$" + "{CIRCLECI_TOKEN}";
      };
    };
    firecrawl = {
      type = "stdio";
      command = "npx";
      args = [ "-y" "firecrawl-mcp@3.22.3" ];
      env = {
        FIRECRAWL_API_KEY = "$" + "{FIRECRAWL_API_KEY}";
      };
    };
    # ruflo's multi-agent orchestration backbone. Uses the global CLI
    # installed via home/npm-globals so the version stays unified with the
    # `ruflo` shell command.
    #
    # Absolute path is intentional: Claude Code's MCP spawner inherits whatever
    # PATH the parent Claude process had at launch. If Claude was launched from
    # Spotlight/Dock/an IDE plugin instead of a login shell, ~/.npm-global/bin
    # won't be on PATH and `command = "ruflo"` would fail with "command not
    # found". The absolute path makes spawning deterministic regardless of how
    # Claude was launched.
    #
    # Inherits Claude's env (ANTHROPIC_API_KEY etc.) — add explicit `env`
    # entries here only for keys Claude doesn't already set (e.g. OPENAI_API_KEY,
    # GOOGLE_API_KEY) if you want ruflo to drive other models.
    ruflo = {
      type = "stdio";
      command = "${homeDir}/.npm-global/bin/ruflo";
      args = [ "mcp" "start" ];
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
      "Bash(node --version:*)"
      "Bash(node -v:*)"

      # Rust
      "Bash(cargo:*)"
      "Bash(rustc:*)"
      "Bash(rustup:*)"

      # Python
      "Bash(python --version:*)"
      "Bash(python3 --version:*)"
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

      # KingsRook root-admin scoped grants. These intentionally relax the
      # "tofu apply deliberately omitted" policy above, but ONLY for the
      # kingsrook_root_admin AWS profile invoked inline. Route53 / Route53
      # Domains management runs unprompted under that profile.
      "Bash(AWS_PROFILE=kingsrook_root_admin aws route53*)"
      "Bash(AWS_PROFILE=kingsrook_root_admin aws route53domains*)"
      "Bash(AWS_PROFILE=kingsrook_root_admin tofu -chdir=*apply*)"

      # Terragrunt read/plan operations. Mutating operations such as apply,
      # taint, run, or arbitrary state edits deliberately require approval.
      "Bash(terragrunt init:*)"
      "Bash(terragrunt plan:*)"
      "Bash(terragrunt state list:*)"
      "Bash(terragrunt state show:*)"
      "Bash(terragrunt output:*)"
      "Bash(terragrunt validate:*)"

      # AWS SSO credential rotation
      # Lets the agent rotate workload-account role credentials from a fresh
      # SSO bearer token without harness blocking. Used by the AWS infra
      # workflow (terragrunt apply against vended workload accounts).
      # The first rule reads the cached SSO bearer; the second exchanges it
      # for short-lived role credentials.
      "Bash(jq -r .accessToken ${homeDir}/.aws/sso/cache/*.json)"
      "Bash(aws sso get-role-credentials:*)"
      "Bash(aws sso list-account-roles:*)"
      "Bash(${homeDir}/bin/get-gg-prod-bg-creds.sh)"

      # AWS CLI — read-only / inspection verbs across services used in DMD infra.
      "Bash(aws sts:*)"
      "Bash(aws ssm:*)"
      "Bash(aws eks:*)"
      "Bash(aws kms list-aliases:*)"
      "Bash(aws kms describe-key:*)"
      "Bash(aws iam get-role:*)"
      "Bash(aws iam list-attached-role-policies:*)"
      "Bash(aws iam list-role-policies:*)"
      "Bash(aws backup describe-region-settings:*)"
      "Bash(aws backup list-backup-plans:*)"
      "Bash(aws backup list-backup-vaults:*)"
      "Bash(aws ec2 describe-instances:*)"
      "Bash(aws ec2 describe-client-vpn-endpoints:*)"
      "Bash(aws s3api head-bucket:*)"
      "Bash(aws s3api list-objects-v2:*)"
      "Bash(aws dynamodb describe-table:*)"

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

      # MCP - Ruflo (intentionally NOT wildcarded yet)
      # Ruflo exposes file-modifying / agent-spawning tools (mcp__ruflo__agent_spawn,
      # mcp__ruflo__swarm_init, mcp__ruflo__memory_*, etc). Letting them auto-fire
      # without prompts would let an orchestration loop write/refactor files
      # without your sign-off. Strategy: leave the prompts on initially so you
      # see what each tool actually does, then narrow this allow list to the
      # specific ones you trust (read-only memory queries, status checks, etc.).
      # When ready, replace the comment with either a wildcard:
      #   "mcp__ruflo__*"
      # or a specific subset, e.g.:
      #   "mcp__ruflo__memory_search"
      #   "mcp__ruflo__agent_list"
      #   "mcp__ruflo__swarm_status"

      # MCP - CircleCI (read-only operations)
      "mcp__circleci-mcp-server__get_build_failure_logs"
      "mcp__circleci-mcp-server__find_flaky_tests"
      "mcp__circleci-mcp-server__get_latest_pipeline_status"
      "mcp__circleci-mcp-server__get_job_test_results"
      "mcp__circleci-mcp-server__config_helper"
      "mcp__circleci-mcp-server__list_followed_projects"
      "mcp__circleci-mcp-server__list_component_versions"
      "mcp__firecrawl__*"

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

      # Web access (read-only) — universal allow, no prompts for any site.
      # Per docs (code.claude.com/docs/en/settings), the bare tool name matches
      # all invocations; the domain-wildcard form is added explicitly as a
      # belt-and-suspenders in case a future Claude Code version evaluates
      # rules more strictly.
      "WebSearch"
      "WebFetch"
      "WebFetch(domain:*)"
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

    # Second-brain vault path (see home/secondbrain + docs/PLAN-secondbrain.md).
    # settings.json `env` reaches every session regardless of launch context
    # (Dock/IDE launches don't source the login shell).
    env.SECOND_BRAIN_VAULT =
      if pkgs.stdenv.isDarwin
      then "${homeDir}/Git.Local/KofTwentyTwo/second-brain"
      else if isWsl
      then "/mnt/r/Git.Local/KofTwentyTwo/second-brain"
      else "${homeDir}/Git.Local/KofTwentyTwo/second-brain";

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
      "csharp-lsp@claude-plugins-official"             = true;   # C#/.NET
      "rust-analyzer-lsp@claude-plugins-official"      = true;   # Rust
      "swift-lsp@claude-plugins-official"              = true;   # iOS
      "typescript-lsp@claude-plugins-official"         = true;   # TS/JS
      # No HCL/Terraform LSP exists in the official marketplace (2026-07);
      # the `terraform` plugin below covers IaC via an MCP server instead.

      # --- Integrations (issue trackers, design, browser, source-of-truth) ---
      "agent-sdk-dev@claude-plugins-official"          = true;
      "atlassian@claude-plugins-official"              = true;
      "figma@claude-plugins-official"                  = true;
      "frontend-design@claude-plugins-official"        = true;
      "github@claude-plugins-official"                 = true;
      "playwright@claude-plugins-official"             = true;
      # HashiCorp's Terraform MCP server — ON per James (devops is core
      # stack, 2026-07-03). Counts against the MCP context budget
      # (docs/PLAN-secondbrain.md); demote to false if context gets tight.
      "terraform@claude-plugins-official"              = true;

      # --- Product management (anthropics/knowledge-work-plugins marketplace) ---
      # Full plugin parity for `claude plugin install product-management@
      # knowledge-work-plugins`: ships 8 PM skills (roadmap-update, write-spec,
      # competitive-brief, metrics-review, product-brainstorming, sprint-planning,
      # stakeholder-update, synthesize-research), a /brainstorm command, and a
      # bundle of HTTP MCP servers (linear, asana, notion, amplitude, pendo,
      # intercom, fireflies, similarweb, slack, monday, clickup, gmail, gcal, +
      # atlassian/figma which overlap the official plugins above).
      "product-management@knowledge-work-plugins"      = true;
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
  windowsFirecrawlMcpJson = pkgs.writeText "windows-firecrawl-mcp.json" (builtins.toJSON {
    firecrawl = {
      type = "stdio";
      command = "cmd";
      args = [ "/c" "npx" "-y" "firecrawl-mcp@3.22.3" ];
      env.FIRECRAWL_API_KEY = "$" + "{FIRECRAWL_API_KEY}";
    };
  });
  permissionsJson = pkgs.writeText "permissions.json" (builtins.toJSON permissions);
  userPrefsJson = pkgs.writeText "user-prefs.json" (builtins.toJSON userPrefs);

  # Second-brain hook registration (scripts/skills live in home/secondbrain;
  # the settings.json entries live here because this module owns the settings
  # merge). Merged by MARKER in syncClaudeUserSettings — existing hook entries
  # whose JSON mentions "secondbrain" are replaced, everything else (notably
  # GSD's self-installed hooks on the Macs) is preserved untouched.
  secondBrainHooks = {
    SessionStart = [ { hooks = [ { type = "command"; command = "${homeDir}/.claude/hooks/secondbrain-session-start.sh"; } ]; } ];
    SessionEnd   = [ { hooks = [ { type = "command"; command = "${homeDir}/.claude/hooks/secondbrain-session-end.sh"; } ]; } ];
  };
  secondBrainHooksJson = pkgs.writeText "secondbrain-hooks.json" (builtins.toJSON secondBrainHooks);
in
{
  imports = [ ./skills.nix ];
  # CLAUDE.md - read-only symlink is fine
  home.file.".claude/CLAUDE.md".text =
    (import ../lib/agent-context.nix).mkAgentHierarchyDoc { selfRef = "~/.claude/CLAUDE.md"; selfName = "CLAUDE.md"; };

  # ~/.claude.json - merge mcpServers, preserve user data
  # IMPORTANT: This script is defensive - it won't overwrite if jq fails
  # Runs AFTER installClaudePluginMarketplaces so any ~/.claude.json the
  # `claude plugin marketplace add` invocation lazily created gets our managed
  # mcpServers re-merged in. Otherwise the marketplace call would either
  # create the file root-owned with no mcpServers, or wipe an existing one.
  home.activation.syncClaudeJson = lib.hm.dag.entryAfter [ "writeBoundary" "installClaudePluginMarketplaces" ] ''
    claude_json="${homeDir}/.claude.json"
    hm_user="$(stat -c %U "${homeDir}" 2>/dev/null || /usr/bin/stat -f %Su "${homeDir}")"

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
    # Activation runs as root under `sudo darwin-rebuild switch`; any file we
    # mv/create here lands root-owned and breaks Claude's own writes. Restore
    # user ownership unconditionally.
    /usr/sbin/chown "$hm_user" "$claude_json" 2>/dev/null || true

    # MCP context-budget assert (docs/PLAN-secondbrain.md): always-on
    # user-scope servers should stay ≤ 5. Warn-only — never fails the switch.
    sb_mcp_count=$(${pkgs.jq}/bin/jq '.mcpServers | length' "$claude_json" 2>/dev/null || echo 0)
    if [ "''${sb_mcp_count:-0}" -gt 5 ]; then
      echo "[claude] WARN: $sb_mcp_count user-scope MCP servers configured; budget is 5 (see docs/PLAN-secondbrain.md). Demote extras to swap-ins." >&2
    fi
  '';

  # ~/.claude/settings.local.json - merge permissions, preserve user data
  home.activation.syncClaudeSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    settings_json="${homeDir}/.claude/settings.local.json"
    hm_user="$(stat -c %U "${homeDir}" 2>/dev/null || /usr/bin/stat -f %Su "${homeDir}")"
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
    # See syncClaudeJson for the ownership-restoration rationale.
    /usr/sbin/chown "$hm_user" "$settings_json" 2>/dev/null || true
  '';

  # ~/.claude/settings.json - user preferences (theme, etc.)
  # Same ordering rationale as syncClaudeJson: must run after the marketplace
  # registration so we re-merge our managed prefs on top of anything Claude's
  # CLI wrote during the marketplace add.
  home.activation.syncClaudeUserSettings = lib.hm.dag.entryAfter [ "writeBoundary" "installClaudePluginMarketplaces" ] ''
    user_settings="${homeDir}/.claude/settings.json"
    hm_user="$(stat -c %U "${homeDir}" 2>/dev/null || /usr/bin/stat -f %Su "${homeDir}")"
    mkdir -p "${homeDir}/.claude"

    if [ ! -f "$user_settings" ] || [ ! -s "$user_settings" ]; then
      ${pkgs.jq}/bin/jq -n --slurpfile prefs "${userPrefsJson}" --slurpfile sb "${secondBrainHooksJson}" \
        '$prefs[0] | .hooks = $sb[0]' > "$user_settings"
      chmod 600 "$user_settings"
    else
      if ${pkgs.jq}/bin/jq --slurpfile prefs "${userPrefsJson}" --slurpfile sb "${secondBrainHooksJson}" '
        # Deep merge enabledPlugins to preserve manually-added plugins
        .enabledPlugins = ((.enabledPlugins // {}) * ($prefs[0].enabledPlugins // {}))
        | . * ($prefs[0] | del(.enabledPlugins))
        # Second-brain hooks: marker-based merge. Drop any prior entry that
        # mentions "secondbrain", append the managed ones. All other hook
        # entries (e.g. GSD-installed) pass through untouched.
        | .hooks.SessionStart = (((.hooks.SessionStart // []) | map(select((tojson | contains("secondbrain")) | not))) + $sb[0].SessionStart)
        | .hooks.SessionEnd   = (((.hooks.SessionEnd   // []) | map(select((tojson | contains("secondbrain")) | not))) + $sb[0].SessionEnd)
      ' "$user_settings" > "$user_settings.tmp" \
        && [ -s "$user_settings.tmp" ]; then
        mv "$user_settings.tmp" "$user_settings"
        chmod 600 "$user_settings"
      else
        rm -f "$user_settings.tmp"
      fi
    fi
    # See syncClaudeJson for the ownership-restoration rationale.
    /usr/sbin/chown "$hm_user" "$user_settings" 2>/dev/null || true
  '';

  # LORE: Windows-native Claude Code parity — plugins + skills.
  # The secondbrain bridge (home/secondbrain) owns hooks/env/CLAUDE.md for the
  # Windows side; THIS activation owns enabledPlugins, the skills tree, and
  # marketplace registration, because this module defines them. Linux-only,
  # guarded on the /mnt/c mount. Windows keeps its own model/theme prefs —
  # only enabledPlugins is merged.
  home.activation.syncWindowsClaudePlugins = lib.mkIf pkgs.stdenv.isLinux (lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    win="/mnt/c/Users/james/.claude"
    if [ -d "$win" ]; then
      ws="$win/settings.json"
      [ -f "$ws" ] || echo '{}' > "$ws"
      if ${pkgs.jq}/bin/jq --slurpfile prefs "${userPrefsJson}" \
        '.enabledPlugins = ((.enabledPlugins // {}) * ($prefs[0].enabledPlugins // {}))' \
        "$ws" > "$ws.tmp" && [ -s "$ws.tmp" ]; then
        mv "$ws.tmp" "$ws"
        echo "[claude-win] enabledPlugins merged into Windows settings.json"
      else
        rm -f "$ws.tmp"
        echo "[claude-win] WARN: enabledPlugins merge failed; Windows plugins unchanged" >&2
      fi
      cj="/mnt/c/Users/james/.claude.json"
      [ -f "$cj" ] || echo '{}' > "$cj"
      if ${pkgs.jq}/bin/jq --slurpfile mcp "${windowsFirecrawlMcpJson}" \
        '.mcpServers = ((.mcpServers // {}) * $mcp[0])' \
        "$cj" > "$cj.tmp" && [ -s "$cj.tmp" ]; then
        mv "$cj.tmp" "$cj"
        echo "[claude-win] Firecrawl MCP merged into Windows .claude.json"
      else
        rm -f "$cj.tmp"
        echo "[claude-win] WARN: Firecrawl MCP merge failed" >&2
      fi
      # Skills: copy the resolved WSL skills tree (cp -L dereferences the
      # nix-store symlinks — Windows cannot follow them).
      if [ -d "${homeDir}/.claude/skills" ]; then
        cp -rLf "${homeDir}/.claude/skills/." "$win/skills/" 2>/dev/null \
          || echo "[claude-win] WARN: skills copy failed" >&2
      fi
      # Marketplaces Windows lacks (network fetch — warn-only, never fatal).
      for mp in anthropics/claude-plugins-official anthropics/knowledge-work-plugins; do
        name="''${mp#*/}"
        if [ ! -d "$win/plugins/marketplaces/$name" ]; then
          /mnt/c/Users/james/.local/bin/claude.exe plugin marketplace add "$mp" >/dev/null 2>&1 \
            && echo "[claude-win] registered marketplace $mp" \
            || echo "[claude-win] WARN: could not register marketplace $mp (register manually: claude plugin marketplace add $mp)" >&2
        fi
      done
      # Install every enabled-but-missing plugin so a fresh Windows shell has
      # the full set immediately (enablement alone defers install to first
      # session start). Warn-only per plugin; converges on later rebuilds.
      installed="$win/plugins/installed_plugins.json"
      [ -f "$installed" ] || echo '{}' > "$installed"
      ${pkgs.jq}/bin/jq -r '.enabledPlugins | to_entries[] | select(.value) | .key' "${userPrefsJson}" \
        | while IFS= read -r plugin; do
            if ! ${pkgs.jq}/bin/jq -e --arg p "$plugin" 'tostring | contains($p)' "$installed" >/dev/null 2>&1; then
              /mnt/c/Users/james/.local/bin/claude.exe plugin install "$plugin" >/dev/null 2>&1 \
                && echo "[claude-win] installed $plugin" \
                || echo "[claude-win] WARN: install failed for $plugin" >&2
            fi
          done
    fi
  '');

  # QQQ project-level CLAUDE.md bootstrap — drop the extracted QQQ rules
  # template into ~/Git.Local/QRun-IO/qqq/CLAUDE.md if the QQQ checkout exists
  # and doesn't already have one. Copy-if-missing only; once the file lands
  # in the QQQ repo, that repo owns it and subsequent rebuilds do nothing.
  # Silent no-op on machines without the QQQ checkout.
  # NB: never use bare `exit 0` to skip — home-manager runs all
  # `home.activation.*` blocks as one bash process, so `exit` aborts every
  # downstream activation (notably syncClaudeJson). Use if/then to skip.
  home.activation.bootstrapQqqClaudeMd = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    qqq_dir="${homeDir}/Git.Local/QRun-IO/qqq"
    qqq_claude_md="$qqq_dir/CLAUDE.md"
    template_path="${./workspace-templates/qqq-CLAUDE.md}"

    if [ -d "$qqq_dir" ] && [ ! -f "$qqq_claude_md" ]; then
      cp "$template_path" "$qqq_claude_md"
      chmod 644 "$qqq_claude_md"
      echo "[qqq-bootstrap] Wrote CLAUDE.md template into $qqq_dir/. Review and commit from the QQQ checkout." >&2
    fi
  '';

  # Serena dashboard auto-open — pin to false so launching Claude (which
  # spawns Serena's MCP server) doesn't pop the dashboard in the default
  # browser every time. Serena owns ~/.serena/serena_config.yml (auto-
  # generated on first run, occasionally rewritten with new options), so a
  # home.file symlink would either go stale or block Serena's writes. An
  # idempotent in-place patch is the right hammer: runs every rebuild,
  # survives Serena regenerating the config, and only touches the one line.
  # The dashboard remains reachable manually at http://localhost:24282/dashboard/.
  # Warns (rather than failing) if upstream renames the key, so unrelated
  # rebuilds don't break — we just lose dashboard suppression until the
  # sed pattern is updated.
  # NB: never use bare `exit 0` to skip — see bootstrapQqqClaudeMd note above.
  home.activation.serenaDisableDashboardAutoOpen = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    cfg="${homeDir}/.serena/serena_config.yml"
    if [ -f "$cfg" ]; then
      if ! /usr/bin/grep -q '^web_dashboard_open_on_launch:' "$cfg"; then
        echo "[serena] WARN: web_dashboard_open_on_launch key not found in $cfg — upstream may have renamed it" >&2
      else
        # Nixpkgs GNU sed on both platforms — /usr/bin/sed is BSD on macOS
        # and GNU on Linux, and their -i syntaxes are incompatible.
        ${pkgs.gnused}/bin/sed -i \
          's/^web_dashboard_open_on_launch:.*/web_dashboard_open_on_launch: false/' \
          "$cfg"
      fi
    fi
  '';

  # Claude Code native binary — bootstrap once, then hands-off.
  # Anthropic ships claude as a self-updating native binary that lives at
  # ~/.local/share/claude/versions/<ver>/ with a stable symlink at
  # ~/.local/bin/claude. After bootstrap, the binary self-updates; we don't
  # touch it on subsequent rebuilds.
  #
  # Why not npm: Anthropic is deprecating the npm channel in favor of the
  # native installer. On 2026-05-11 the CLI's auto-migrator ran
  # `npm uninstall -g @anthropic-ai/claude-code` mid-session, removed the
  # ~/.npm-global/bin/claude symlink, then failed to clean up the package
  # dir (ENOTEMPTY), leaving claude missing from PATH. Combining that
  # auto-migrator with home/npm-globals' always-upgrade activation script
  # was the root cause — keep them separated.
  #
  # Why not brew cask: same upstream-lag concern as the other AI CLIs
  # (see home/npm-globals header). The native installer pulls same-day
  # releases directly from Anthropic.
  #
  # Idempotent on existence: if ~/.local/bin/claude is already executable,
  # we skip and let claude self-update.
  #
  # NPM-channel detection: Claude's auto-migrator (or a user reset) can
  # leave an npm-installed claude at ~/.npm-global/bin/claude. That puts us
  # back on the deprecated npm channel, which is exactly the situation the
  # header note warns about. If we find one, evict it and force a native
  # reinstall so the install channel stays consistent across machines.
  #
  # Brew-prefix npm fallback: if ~/.claude.json ever ends up root-owned
  # (sudo-side write into $HOME), claude's auto-updater reads stale
  # installMethod, falls back to npm, and `npm install -g` lands in brew's
  # node prefix (/opt/homebrew/lib/node_modules/@anthropic-ai/claude-code)
  # with a /opt/homebrew/bin/claude symlink that wins on PATH because
  # /opt/homebrew/bin sits before ~/.local/bin. We evict that too. The brew
  # `claude` cask at /opt/homebrew/Caskroom/claude/ (the desktop app) is
  # deliberately left alone — different artifact, different path.
  # NB: never use bare `exit 0` to skip — see bootstrapQqqClaudeMd note above.
  home.activation.bootstrapClaude = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    hm_user="$(stat -c %U "${homeDir}" 2>/dev/null || /usr/bin/stat -f %Su "${homeDir}")"
    native_claude="${homeDir}/.local/bin/claude"
    npm_claude="${homeDir}/.npm-global/bin/claude"
    npm_pkg_dir="${homeDir}/.npm-global/lib/node_modules/@anthropic-ai"
    brew_claude_bin="/opt/homebrew/bin/claude"
    brew_claude_pkg="/opt/homebrew/lib/node_modules/@anthropic-ai"

    if [ -e "$npm_claude" ] || [ -d "$npm_pkg_dir" ]; then
      echo "[claude] npm-channel claude detected at $npm_claude; evicting (we use the native installer)" >&2
      /bin/rm -f "$npm_claude" 2>/dev/null || true
      /bin/rm -rf "$npm_pkg_dir" 2>/dev/null || true
    fi

    # Only evict /opt/homebrew/bin/claude when it's the npm-self-heal
    # symlink (→ @anthropic-ai/claude-code). The brew `claude` cask
    # installs Claude.app under /opt/homebrew/Caskroom/, not under
    # /opt/homebrew/bin — so a real path through ../lib/node_modules
    # uniquely identifies the npm reincarnation we want gone.
    if [ -L "$brew_claude_bin" ] && \
       /usr/bin/readlink "$brew_claude_bin" 2>/dev/null | /usr/bin/grep -q '@anthropic-ai/claude-code'; then
      echo "[claude] brew-prefix npm claude-code detected at $brew_claude_bin; evicting" >&2
      # /opt/homebrew is user-owned but the npm-installed @anthropic-ai/
      # tree can be root-owned when claude's self-update fired with cached
      # sudo. Try unprivileged first; fall back to sudo if root-owned.
      /bin/rm -f "$brew_claude_bin" 2>/dev/null || /usr/bin/sudo -n /bin/rm -f "$brew_claude_bin" 2>/dev/null || true
      /bin/rm -rf "$brew_claude_pkg" 2>/dev/null || /usr/bin/sudo -n /bin/rm -rf "$brew_claude_pkg" 2>/dev/null || true
    fi

    # Helper: run a command as the home-dir owner. Under `sudo darwin-rebuild`
    # the activation runs as root; we need anything that writes into $HOME to
    # land user-owned. Outside sudo this is a no-op for the current user.
    runAsOwner() {
      if [ "$(id -u)" = "0" ] && [ "$hm_user" != "root" ]; then
        /usr/bin/sudo -u "$hm_user" -H /bin/bash -c "$1"
      else
        /bin/bash -c "$1"
      fi
    }

    if [ -x "$native_claude" ]; then
      echo "[claude] already installed at $native_claude (self-updates)"
    else
      # Repair path: if a previous install left a version binary on disk but
      # the launcher symlink at ~/.local/bin/claude is gone (e.g. user wiped
      # ~/.local/bin, or our own npm-eviction step nuked an old symlink),
      # we can rebuild the launcher without any network call by invoking the
      # latest existing version binary's `install` subcommand. install.sh
      # itself does the same thing on its last line after downloading the
      # binary, so this is the same code path Anthropic ships, just without
      # the download step.
      versions_dir="${homeDir}/.local/share/claude/versions"
      repaired=0
      if [ -d "$versions_dir" ]; then
        # Pick the most recently modified executable file under versions/.
        # `ls -t` orders by mtime descending; we just want the first hit.
        latest_bin="$(/bin/ls -t "$versions_dir" 2>/dev/null \
          | /usr/bin/awk -v d="$versions_dir" '{print d"/"$0; exit}')"
        if [ -n "$latest_bin" ] && [ -x "$latest_bin" ]; then
          echo "[claude] launcher missing but binary present at $latest_bin; repairing without network" >&2
          if runAsOwner "'$latest_bin' install latest"; then
            repaired=1
          else
            echo "[claude] WARN local repair via '$latest_bin install latest' failed; will try network installer" >&2
          fi
        fi
      fi

      if [ "$repaired" -eq 0 ]; then
        echo "[claude] running native installer (curl claude.ai/install.sh)"
        if [ -x /usr/bin/curl ]; then
          # Capture installer output so a failure is diagnosable on the next
          # rebuild instead of being absorbed by the trailing `|| echo WARN`.
          install_log="$(/usr/bin/mktemp -t claude-install.XXXXXX)"
          if runAsOwner "/usr/bin/curl -fsSL https://claude.ai/install.sh | /bin/bash" \
               >"$install_log" 2>&1; then
            echo "[claude] installer reported success"
          else
            echo "[claude] WARN installer exited non-zero; tail of log:" >&2
            /usr/bin/tail -n 20 "$install_log" >&2 || true
            echo "[claude] full installer log retained at $install_log" >&2
          fi
        else
          echo "[claude] WARN /usr/bin/curl not available; skipping" >&2
        fi
      fi

      # Hard verification: by this point either the local repair or the
      # network installer should have produced an executable launcher. If
      # not, log loudly so the next rebuild surfaces the problem instead
      # of silently leaving claude off PATH again.
      if [ ! -x "$native_claude" ]; then
        echo "[claude] ERROR launcher still missing at $native_claude after install attempts" >&2
        echo "[claude] ERROR check ~/.local/share/claude/versions and the installer log above" >&2
      fi
    fi
  '';

  # Claude Code plugin marketplaces — declarative registration.
  # Without this, the enabledPlugins entries in settings.json silently fail
  # on a fresh machine because the marketplace isn't registered yet.
  # Idempotent: `claude plugin marketplace add` is a no-op when already added.
  # Non-fatal: skips silently if claude isn't on PATH yet (cold-start case).
  #
  # CRITICAL: invokes the `claude` CLI, which writes to ~/.claude.json and
  # ~/.claude/. When darwin-rebuild runs under `sudo`, those writes land
  # root-owned and break every subsequent user-side Claude write. We drop to
  # the home-dir owner before invoking claude.
  # NB: never use bare `exit 0` to skip — see bootstrapQqqClaudeMd note above.
  home.activation.installClaudePluginMarketplaces = lib.hm.dag.entryAfter [ "bootstrapClaude" ] ''
    hm_user="$(stat -c %U "${homeDir}" 2>/dev/null || /usr/bin/stat -f %Su "${homeDir}")"
    runUser() {
      if [ "$(id -u)" = "0" ] && [ "$hm_user" != "root" ]; then
        /usr/bin/sudo -u "$hm_user" -H /bin/bash -c "$1"
      else
        /bin/bash -c "$1"
      fi
    }

    if ! runUser 'export PATH="'"${homeDir}"'/.local/bin:'"${homeDir}"'/.npm-global/bin:/opt/homebrew/opt/node@24/bin:$PATH"; command -v claude >/dev/null 2>&1'; then
      echo "[claude-marketplaces] claude CLI not on PATH yet; skipping (will register on next rebuild)" >&2
    else
      # Marketplaces we want present on every machine.
      marketplaces=(
        "claude-plugins-official:anthropics/claude-plugins-official"
        "knowledge-work-plugins:anthropics/knowledge-work-plugins"
      )
      for entry in "''${marketplaces[@]}"; do
        name="''${entry%%:*}"
        source="''${entry#*:}"
        # Force HTTPS for claude's internal `git clone`: marketplace repos are
        # public so HTTPS is auth-free, whereas the SSH form (git@github.com:)
        # fails in the sudo-dropped activation context (no ssh-agent/keys) and
        # silently skipped knowledge-work-plugins on first add. The GIT_CONFIG_*
        # env vars inject an insteadOf rewrite into every git subprocess claude
        # spawns. Detection matches the unique "(owner/repo)" Source line rather
        # than the ❯-prefixed name (which only marks the *selected* marketplace,
        # so a registered-but-unselected one would be re-added every rebuild).
        runUser 'export PATH="'"${homeDir}"'/.local/bin:'"${homeDir}"'/.npm-global/bin:/opt/homebrew/opt/node@24/bin:$PATH"; \
          export GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0="url.https://github.com/.insteadOf" GIT_CONFIG_VALUE_0="git@github.com:"; \
          current="$(claude plugin marketplace list 2>/dev/null || true)"; \
          if echo "$current" | /usr/bin/grep -qF "('"$source"')"; then :; else \
            echo "[claude-marketplaces] Adding '"$name"' ('"$source"')..."; \
            claude plugin marketplace add "'"$source"'" 2>&1 || \
              echo "[claude-marketplaces] WARN: add of '"$name"' failed; continuing" >&2; \
          fi'
      done
    fi
  '';

  # GSD (Get-Shit-Done) — install/upgrade on every rebuild via upstream's
  # own installer. Brew-style: nix declares intent, npx owns the file layout.
  # Runs AFTER syncClaudeUserSettings so GSD's hooks/statusline writes to
  # settings.json aren't clobbered by our merge.
  #
  # Uses brew-managed node@24 (not pkgs.nodejs) because GSD's installer
  # internally runs `npm install -g .` to build its SDK, and `-g` writes to
  # NPM_CONFIG_PREFIX. Nix's nodejs pins its prefix to a read-only /nix/store
  # path, which fails with EACCES. node@24 + ~/.npm-global mirrors the
  # home/npm-globals pattern so everything lands in a user-writable tree.
  # CRITICAL: like installClaudePluginMarketplaces, npx + the GSD installer
  # write into ~/.claude/, ~/.npm-global/, and several user-side state dirs.
  # Must run as the home-dir owner — otherwise sudo'd rebuilds leak root
  # ownership into npm-global and Claude's data tree.
  home.activation.installGsd = lib.hm.dag.entryAfter [ "syncClaudeUserSettings" "installNpmGlobals" ] ''
    hm_user="$(stat -c %U "${homeDir}" 2>/dev/null || /usr/bin/stat -f %Su "${homeDir}")"

    if [ ! -x "/opt/homebrew/opt/node@24/bin/npx" ]; then
      echo "[gsd] /opt/homebrew/opt/node@24/bin/npx not found; skipping (install node@24 via Homebrew first)" >&2
    else
      # GSD's installer migrates leftover artifacts on every update. Some
      # categories the classifier can't auto-resolve and need a keep/remove
      # decision. Activation has no TTY; without `GSD_INSTALLER_MIGRATION_RESOLVE=keep`
      # the installer hard-aborts on the "non-interactive runs … no stdin TTY"
      # path and we lose the update silently. `keep` preserves user-owned
      # artifacts; bundled GSD-managed hooks get auto-removed via
      # classifyPromptUserAction regardless.
      install_cmd='export NPM_CONFIG_PREFIX="'"${homeDir}"'/.npm-global"; \
        export PATH="'"${homeDir}"'/.npm-global/bin:/opt/homebrew/opt/node@24/bin:$PATH"; \
        export GSD_INSTALLER_MIGRATION_RESOLVE=keep; \
        /bin/mkdir -p "$NPM_CONFIG_PREFIX"; \
        echo "[gsd] Installing/updating to latest..."; \
        if /opt/homebrew/opt/node@24/bin/npx -y get-shit-done-cc@latest --global 2>&1; then \
          echo "[gsd] Install/update complete."; \
        else \
          echo "[gsd] WARNING: Install/update failed — GSD may be stale or missing." >&2; \
        fi'

      if [ "$(id -u)" = "0" ] && [ "$hm_user" != "root" ]; then
        /usr/bin/sudo -u "$hm_user" -H /bin/bash -c "$install_cmd"
      else
        /bin/bash -c "$install_cmd"
      fi
    fi
  '';

  # Final ownership sweep — runs LAST after every Claude-touching activation.
  # `bootstrapClaude`, `installClaudePluginMarketplaces`, and `installGsd` all
  # shell out to processes (curl|bash, the `claude` CLI, npx) that write into
  # $HOME with whatever UID the activation is running under. When darwin-rebuild
  # is invoked via `sudo`, those writes land root-owned and Claude can never
  # modify its own state again. The sync activations above already chown the
  # specific files they touch; this sweep handles everything else those
  # sub-processes can create (mcp-needs-auth-cache.json, plans/, plugin state,
  # etc.) so we don't accumulate root-owned crud across rebuilds.
  home.activation.fixClaudeOwnership = lib.hm.dag.entryAfter [
    "bootstrapClaude"
    "installClaudePluginMarketplaces"
    "installGsd"
    "syncClaudeJson"
    "syncClaudeSettings"
    "syncClaudeUserSettings"
  ] ''
    hm_user="$(stat -c %U "${homeDir}" 2>/dev/null || /usr/bin/stat -f %Su "${homeDir}")"
    if [ -z "$hm_user" ] || [ "$hm_user" = "root" ]; then
      echo "[claude-ownership] homeDir owned by root; refusing to sweep" >&2
    else
      # -h chowns symlinks (not their targets); -depth ensures children before parents.
      for target in "${homeDir}/.claude" "${homeDir}/.claude.json"; do
        if [ -e "$target" ]; then
          /usr/bin/find "$target" ! -user "$hm_user" -print0 2>/dev/null \
            | /usr/bin/xargs -0 -r /usr/sbin/chown -h "$hm_user" 2>/dev/null || true
        fi
      done
    fi
  '';
}
