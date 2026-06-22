# Codex CLI Configuration Module
# ===============================
# Manages OpenAI Codex CLI configuration files.
#
# Files managed:
#   - ~/.codex/config.toml: Settings + MCP servers (activation script, write-once)
#   - ~/.codex/AGENTS.md: Instruction file pointing to shared ~/.ai/ context (symlink, read-only)
#   - ~/.codex/skills/<name>: mattpocock/aihero "Skills for Real Engineers"
#     (read-only symlinks into the nix store; same SKILL.md set Claude gets)

{ config, pkgs, lib, inputs ? {}, ... }:

let
  homeDir = config.home.homeDirectory;

  # mattpocock/skills (aihero.dev). Same flake input the Claude module consumes;
  # Codex discovers skills at ~/.codex/skills/<name>/SKILL.md, so we symlink the
  # same engineering + productivity set in under plain names (matching Codex's
  # native bundled-skill convention, e.g. /tdd, /triage). Mirrors the selection
  # in home/claude/skills.nix; keep the two lists in sync.
  mattpocock = inputs.claude-skills-mattpocock or null;

  mkCodexSkill = name: category: {
    ".codex/skills/${name}".source = "${mattpocock}/skills/${category}/${name}";
  };

  mattpocockCodexSkills = lib.optionalAttrs (mattpocock != null) (lib.attrsets.mergeAttrsList [
    # engineering/ — setup-matt-pocock-skills is the documented prerequisite;
    # run `/setup-matt-pocock-skills` once per repo before the others.
    (mkCodexSkill "setup-matt-pocock-skills" "engineering")
    (mkCodexSkill "diagnose" "engineering")
    (mkCodexSkill "grill-with-docs" "engineering")
    (mkCodexSkill "improve-codebase-architecture" "engineering")
    (mkCodexSkill "prototype" "engineering")
    (mkCodexSkill "tdd" "engineering")
    (mkCodexSkill "to-issues" "engineering")
    (mkCodexSkill "to-prd" "engineering")
    (mkCodexSkill "triage" "engineering")
    (mkCodexSkill "zoom-out" "engineering")

    # productivity/
    (mkCodexSkill "caveman" "productivity")
    (mkCodexSkill "grill-me" "productivity")
    (mkCodexSkill "handoff" "productivity")
    (mkCodexSkill "write-a-skill" "productivity")
  ]);

  # anthropics/knowledge-work-plugins — product-management skill set. Same flake
  # input the Claude module consumes; skills at product-management/skills/<name>/.
  # Mirrors the selection in home/claude/skills.nix; keep the two lists in sync.
  anthropicKW = inputs.claude-skills-anthropic-knowledge-work or null;

  anthropicPmCodexSkills = lib.optionalAttrs (anthropicKW != null) (lib.attrsets.mergeAttrsList (
    map (name: { ".codex/skills/${name}".source = "${anthropicKW}/product-management/skills/${name}"; }) [
      "competitive-brief"
      "metrics-review"
      "product-brainstorming"
      "roadmap-update"
      "sprint-planning"
      "stakeholder-update"
      "synthesize-research"
      "write-spec"
    ]
  ));

  # DietrichGebert/ponytail: minimalism skill set. Same flake input the Claude
  # module consumes; skills at skills/<name>/. Mirrors the selection in
  # home/claude/skills.nix (core `ponytail` + review/audit/debt; gain/help
  # skipped). Keep the two lists in sync. Skills ONLY — we never wire ponytail's
  # plugin hooks into Codex: its SessionStart/UserPromptSubmit hooks would hit
  # the same Claude-plugin compat-layer drift as security-guidance's Stop hook
  # (see disableSgStopHook below), so we take the SKILL.md files alone.
  ponytail = inputs.claude-skills-ponytail or null;

  ponytailCodexSkills = lib.optionalAttrs (ponytail != null) (lib.attrsets.mergeAttrsList (
    map (name: { ".codex/skills/${name}".source = "${ponytail}/skills/${name}"; }) [
      "ponytail"
      "ponytail-review"
      "ponytail-audit"
      "ponytail-debt"
    ]
  ));

  # Disable the security-guidance plugin's Stop hook for Codex.
  # ----------------------------------------------------------------
  # Codex 0.135.0's Claude-plugin compat layer loads
  # security-guidance@claude-plugins-official's hooks/hooks.json and maps its
  # `Stop` hook into a Codex stop hook. That hook runs security_reminder_hook.py,
  # whose emit_metrics() UNCONDITIONALLY prints Claude Code's SyncHookJSONOutput
  # ({"metrics": {...}}) to stdout — even on the disabled/skip path. Codex's stop
  # hook expects its OWN JSON schema, so it rejects every firing with
  # "hook returned invalid stop hook JSON output". ENABLE_STOP_REVIEW=0 /
  # SECURITY_GUIDANCE_DISABLE=1 do NOT help: the disabled path still calls
  # emit_metrics (skip_reason -1). The plugin cache is Codex-managed (re-cloned
  # on update), so we can't patch the script declaratively.
  #
  # Codex's per-hook state struct (HookStateToml) carries an `enabled` bool
  # alongside `trusted_hash`, so we can disable JUST this one hook event without
  # touching the rest of the plugin (PostToolUse pattern warnings, SessionStart
  # SDK setup keep working). This script idempotently sets `enabled = false` on
  # every [hooks.state."security-guidance@...:stop:*"] entry, creating the
  # canonical entry if none exists. It only rewrites the file when something
  # actually changed. Matches by the stop-event prefix so it survives Codex
  # renumbering the :group:hook index suffix.
  #
  # Limitation: config.toml is Codex-owned. If Codex rewrites hooks.state on a
  # trust event it may drop the flag until the next rebuild re-applies it.
  disableSgStopHook = pkgs.writeText "codex-disable-sg-stop-hook.py" ''
    import os, sys, tempfile

    path = sys.argv[1]
    prefix = "[hooks.state.\"security-guidance@claude-plugins-official:hooks/hooks.json:stop:"
    canonical = "[hooks.state.\"security-guidance@claude-plugins-official:hooks/hooks.json:stop:0:0\"]"

    try:
        with open(path, "r", encoding="utf-8") as fh:
            lines = fh.read().split("\n")
    except FileNotFoundError:
        sys.exit(0)

    def is_table_header(s):
        t = s.strip()
        return t.startswith("[") and t.endswith("]")

    targets = [i for i, ln in enumerate(lines) if ln.strip().startswith(prefix)]
    changed = False

    if not targets:
        # No stop-hook entry yet (plugin not installed/trusted, or fresh seed).
        # Pre-create it so the flag is in place if/when Codex loads the hook.
        if lines and lines[-1].strip() != "":
            lines.append("")
        lines.append(canonical)
        lines.append("enabled = false")
        changed = True
    else:
        # Walk targets back-to-front so insertions don't shift later indices.
        for idx in sorted(targets, reverse=True):
            j = idx + 1
            enabled_idx = None
            while j < len(lines) and not is_table_header(lines[j]):
                if lines[j].split("=", 1)[0].strip() == "enabled":
                    enabled_idx = j
                j += 1
            if enabled_idx is not None:
                if lines[enabled_idx].strip() != "enabled = false":
                    lines[enabled_idx] = "enabled = false"
                    changed = True
            else:
                lines.insert(idx + 1, "enabled = false")
                changed = True

    if changed:
        data = "\n".join(lines)
        fd, tmp = tempfile.mkstemp(dir=os.path.dirname(path))
        with os.fdopen(fd, "w", encoding="utf-8") as fh:
            fh.write(data)
        os.chmod(tmp, 0o600)
        os.replace(tmp, path)
        print("codex: disabled security-guidance Stop hook (enabled=false)")
    else:
        print("codex: security-guidance Stop hook already disabled")
  '';

  # Fix MCP server entries in Codex's (write-once, Codex-owned) config.toml.
  # ----------------------------------------------------------------
  # Same problem as the Stop-hook patcher above: the codexConfigToml seed only
  # lands on a fresh machine (syncCodexConfig is write-once), so corrections to
  # MCP-server config never reach an existing live file — and Codex itself
  # rewrites this file. This idempotent patcher reconciles the MCP servers that
  # otherwise misbehave at `codex` startup:
  #
  #   0. Removals — circleci-mcp-server (duplicate of circleci), qqq-mcp (dead
  #      localhost server), ruflo (leaks ONNX-loader logs onto stdout, breaking
  #      the strict MCP JSON-RPC stream; kept in Claude, dropped from Codex).
  #   1. circleci — older seeds wrote `command = "npx -y @circleci/..."` as a
  #      SINGLE string. Codex execs that literally as one binary name and dies
  #      with "No such file or directory (os error 2)". Force the command/args
  #      split form (matches the corrected seed below).
  #   2. github — the plugin-provided GitHub remote MCP (api.githubcopilot.com)
  #      authenticates via a PAT in an env var. Set bearer_token_env_var so it
  #      reads CODEX_GITHUB_PERSONAL_ACCESS_TOKEN (sourced from sops by zsh; see
  #      home/sops + home/zsh). A [mcp_servers.github] table needs a transport
  #      to parse, so the url is set too. Created if no override exists.
  #   3. figma — disable the plugin-provided figma MCP (enabled=false override)
  #      while keeping its skills.
  #
  # Same Codex-ownership limitation as the Stop-hook patcher: if Codex rewrites
  # mcp_servers on its own, the flags hold until the next darwin-rebuild switch.
  fixMcpServers = pkgs.writeText "codex-fix-mcp-servers.py" ''
    import os, sys, tempfile

    path = sys.argv[1]
    try:
        with open(path, "r", encoding="utf-8") as fh:
            lines = fh.read().split("\n")
    except FileNotFoundError:
        sys.exit(0)

    def is_header(s):
        t = s.strip()
        return t.startswith("[") and t.endswith("]")

    def find_block(header):
        start = None
        for i, ln in enumerate(lines):
            if ln.strip() == header:
                start = i
                break
        if start is None:
            return None
        end = len(lines)
        for j in range(start + 1, len(lines)):
            if is_header(lines[j]):
                end = j
                break
        return (start, end)

    def key_idx(start, end, key):
        for i in range(start + 1, end):
            if is_header(lines[i]):
                break
            ln = lines[i]
            if "=" in ln and ln.split("=", 1)[0].strip() == key:
                return i
        return None

    def last_key_line(start, end):
        last = start
        for i in range(start + 1, end):
            if is_header(lines[i]):
                break
            if lines[i].strip() != "":
                last = i
        return last

    changed = False

    def ensure_table(header):
        global changed
        if find_block(header) is None:
            if lines and lines[-1].strip() != "":
                lines.append("")
            lines.append(header)
            changed = True

    def set_key(header, key, value_line, only_if_absent=False):
        global changed
        blk = find_block(header)
        if blk is None:
            return
        s, e = blk
        ki = key_idx(s, e, key)
        if ki is not None:
            if only_if_absent:
                return
            if lines[ki].strip() != value_line:
                lines[ki] = value_line
                changed = True
            return
        lines.insert(last_key_line(s, e) + 1, value_line)
        changed = True

    def remove_table(header):
        global changed
        blk = find_block(header)
        if blk is None:
            return
        # find_block runs to the next header, so the block already absorbs its
        # own trailing blank line(s); a plain delete leaves the single blank
        # that preceded the table as the separator. No extra trimming needed.
        s, e = blk
        del lines[s:e]
        changed = True

    # 0. Drop dead / redundant servers:
    #    - circleci-mcp-server duplicates `circleci` (same npx package, with a
    #      non-standard `env_vars` key).
    #    - qqq-mcp pointed at a local server (localhost:8080) that no longer
    #      exists.
    #    - ruflo leaks ONNX-loader progress logs onto stdout, which corrupts
    #      the MCP stdio JSON-RPC stream; Codex's strict rmcp client closes the
    #      connection on the first non-JSON line. ruflo stays in Claude (lenient
    #      client) where it's actually used; it's dropped from Codex.
    remove_table("[mcp_servers.circleci-mcp-server]")
    remove_table("[mcp_servers.qqq-mcp]")
    remove_table("[mcp_servers.ruflo]")

    # 1. circleci: collapse the broken single-string command into command/args.
    if find_block("[mcp_servers.circleci]") is not None:
        set_key("[mcp_servers.circleci]", "command", 'command = "npx"')
        set_key("[mcp_servers.circleci]", "args",
                'args = ["-y", "@circleci/mcp-server-circleci@latest"]')

    # 2. github: point the remote MCP at the PAT env var. A [mcp_servers.github]
    #    table in config.toml is validated as a STANDALONE server definition —
    #    Codex requires a transport, so a bare table (bearer only) fails to load
    #    with "invalid transport". Provide the streamable_http `url` (same
    #    endpoint the plugin uses) alongside the bearer so the table is complete.
    ensure_table("[mcp_servers.github]")
    set_key("[mcp_servers.github]", "url",
            'url = "https://api.githubcopilot.com/mcp/"', only_if_absent=True)
    set_key("[mcp_servers.github]", "bearer_token_env_var",
            'bearer_token_env_var = "CODEX_GITHUB_PERSONAL_ACCESS_TOKEN"',
            only_if_absent=True)

    # 3. figma: disable the plugin-provided figma MCP via a config.toml override
    #    (same name as the plugin server -> Codex applies enabled=false). The
    #    figma skills stay; only the MCP is suppressed. `enabled` is enforced
    #    (not only-if-absent) so it re-disables if Codex flips it back on. The
    #    url just satisfies the "table needs a transport" parse requirement.
    ensure_table("[mcp_servers.figma]")
    set_key("[mcp_servers.figma]", "url",
            'url = "https://mcp.figma.com/mcp"', only_if_absent=True)
    set_key("[mcp_servers.figma]", "enabled", "enabled = false")

    if changed:
        data = "\n".join(lines)
        fd, tmp = tempfile.mkstemp(dir=os.path.dirname(path))
        with os.fdopen(fd, "w", encoding="utf-8") as fh:
            fh.write(data)
        os.chmod(tmp, 0o600)
        os.replace(tmp, path)
        print("codex: patched MCP servers (circleci/ruflo/github)")
    else:
        print("codex: MCP servers already patched")
  '';

  # Codex config in TOML format
  # Write-once: no TOML merge tool exists, so we only write if file is missing.
  # Codex itself writes back to this file (project trust levels, marketplaces,
  # plugins), so we cannot use a symlink. To force re-seed: rm ~/.codex/config.toml
  # then re-run darwin-rebuild switch.
  codexConfigToml = pkgs.writeText "codex-config.toml" ''
    model = "gpt-5.5"
    approval_policy = "on-failure"
    sandbox_mode = "workspace-write"
    model_reasoning_effort = "xhigh"

    # Relax the workspace-write sandbox for code-writing tasks:
    #   - network_access lets the agent install deps and hit APIs
    #   - writable_roots extends writes to common package/build caches outside cwd
    [sandbox_workspace_write]
    network_access = true
    exclude_tmpdir_env_var = false
    exclude_slash_tmp = false
    writable_roots = [
      "${homeDir}/.cache",
      "${homeDir}/.npm",
      "${homeDir}/.cargo",
      "${homeDir}/.rustup",
      "${homeDir}/.gradle",
      "${homeDir}/.m2",
      "${homeDir}/.local/share",
      "${homeDir}/Library/Caches",
    ]

    # Codex expects `command` to be a single executable; args go separately.
    # The previous single-string form parsed the whole thing as a binary name.
    [mcp_servers.circleci]
    command = "npx"
    args = ["-y", "@circleci/mcp-server-circleci@latest"]

    [mcp_servers.circleci.env]
    CIRCLECI_TOKEN = "$CIRCLECI_TOKEN"
  '';
in
{
  # mattpocock/aihero skills are read-only symlinks into the nix store at
  # ~/.codex/skills/<name>/, merged with the AGENTS.md symlink below.
  home.file = mattpocockCodexSkills // anthropicPmCodexSkills // ponytailCodexSkills // {

  # AGENTS.md - read-only symlink
  ".codex/AGENTS.md".text =
    (import ../lib/agent-context.nix).mkAgentHierarchyDoc { selfRef = "AGENTS.md"; selfName = "AGENTS.md"; };
  };

  # ~/.codex/config.toml - write-once (no TOML merge tool like jq)
  home.activation.syncCodexConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    codex_toml="${homeDir}/.codex/config.toml"
    mkdir -p "${homeDir}/.codex"

    if [ ! -f "$codex_toml" ] || [ ! -s "$codex_toml" ]; then
      cp "${codexConfigToml}" "$codex_toml"
      chmod 600 "$codex_toml"
    fi
  '';

  # Disable the security-guidance Stop hook in Codex's config.toml.
  # Runs after the write-once seed so it operates on the live (Codex-owned)
  # file. Idempotent: rewrites only when the flag is missing or wrong. See the
  # disableSgStopHook comment above for the why.
  home.activation.disableCodexSgStopHook = lib.hm.dag.entryAfter [ "syncCodexConfig" ] ''
    codex_toml="${homeDir}/.codex/config.toml"
    if [ -f "$codex_toml" ]; then
      ${pkgs.python3}/bin/python3 "${disableSgStopHook}" "$codex_toml" || true
    fi
  '';

  # Reconcile MCP server entries (circleci/ruflo/github) in the live config.
  # Serialized after the Stop-hook patcher so the two never race on rewriting
  # the same Codex-owned file. See the fixMcpServers comment for the why.
  home.activation.fixCodexMcpServers = lib.hm.dag.entryAfter [ "disableCodexSgStopHook" ] ''
    codex_toml="${homeDir}/.codex/config.toml"
    if [ -f "$codex_toml" ]; then
      ${pkgs.python3}/bin/python3 "${fixMcpServers}" "$codex_toml" || true
    fi
  '';
}
