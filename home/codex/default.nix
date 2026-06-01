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

    [mcp_servers.qqq-mcp]
    url = "http://localhost:8080/mcp"

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
  home.file = mattpocockCodexSkills // anthropicPmCodexSkills // {

  # AGENTS.md - read-only symlink
  ".codex/AGENTS.md".text = ''
    # Global Development Context

    ## File Hierarchy (load order)

    | Priority | File | Responsibility |
    |----------|------|---------------|
    | 1 | This file (`AGENTS.md`) | Bootstrap, hierarchy, compaction recovery |
    | 2 | `~/.ai/3-rules.md` | All behavioral mandates (MUST/MUST NOT) |
    | 3 | `~/.ai/2-coding-style.md` | How to write code (reference guide) |
    | 4 | `~/.ai/1-profile.md` | Who I am, environment context |
    | 5 | `~/.ai/4-preferences.yaml` | Machine-readable tuning knobs |
    | 6 | `~/.ai/5-learnings.md` | Operational notes / current ground truth |
    | 7 | Project `AGENTS.md` | Per-repo overrides (scoped) |

    **Conflict resolution:** Higher priority wins. Project `AGENTS.md` MAY override for repo-scoped settings but MUST NOT weaken safety rules.

    ## Initialization

    Load all six `~/.ai/` files and treat them as system-level configuration.
    Use `3-rules.md` as strict constraints, `4-preferences.yaml` as tunable parameters, `1-profile.md` as context, `2-coding-style.md` as output formatting standards, and `5-learnings.md` as operational ground truth.

    ## Compaction Recovery (NON-NEGOTIABLE)

    After context loss, the agent MUST re-read ALL `~/.ai/` files before continuing work. Read them in this order:
    1. `~/.ai/3-rules.md`
    2. `~/.ai/2-coding-style.md`
    3. `~/.ai/1-profile.md`
    4. `~/.ai/4-preferences.yaml`
    5. `~/.ai/5-learnings.md`
    6. Active project `AGENTS.md`
    7. `./docs/SESSION-STATE.md` and `./docs/TODO.md` (if they exist)
  '';
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
}
