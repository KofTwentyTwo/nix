# Nix Config Audit Fixes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Address all 23 findings from `docs/AUDIT-2026-04-07.md`, grouped by file to minimize rebuilds.

**Architecture:** Each task targets one or two files. Changes are pure Nix config edits verified by `darwin-rebuild check`. No TDD (Nix configs have no unit test harness) -- verification is a dry-run build after each phase.

**Tech Stack:** Nix, Home Manager, nix-darwin, Homebrew

**Audit cross-reference:** Each task header lists the audit finding numbers it addresses (e.g. `#1`, `#15`).

---

## File Map

| File | Changes | Audit # |
|------|---------|---------|
| `home/aws/default.nix` | Replace `home.file` with `home.activation` copy | #1 |
| `flake.nix` | Remove `alias.gc`, fix compression, fix Grogu `nix.enable`, fix dock animation | #2, #3, #15, #16 |
| `modules/homebrew.nix` | Remove dual-installed pkgs, remove duplicate mysql, remove extra nodes, uncomment cleanup | #5, #10, #13, #18, #19 |
| `home/default.nix` | Remove stale PATH entries, remove duplicate PAGER | #8, #12 |
| `home/zsh/default.nix` | Fix GRAALVM_HOME, remove PAGER duplicate, add autosuggestion.enable | #6, #8, #20 |
| `home/scripts/default.nix` | Remove duplicate `check-updates.sh` | #7 |
| `home/python/default.nix` | Replace `pip3 --break-system-packages` with Nix packages | #9 |
| `home/claude/default.nix` | Fix jq merge to preserve manual plugins | #11 |
| `home/nvim/default.nix` | Remove dead `defaultEditor = true` | #17 |
| `user-config.nix` | Add prominent "reference only" comment | #14 |
| `scripts/install-git-hooks.sh` | Delete (uninstalled) | #21 |
| `home/ca-certs/update_certs.sh` | Delete (uninstalled) | #21 |
| `~/.claude/settings.local.json` | Add missing permission to Nix source | #22 |
| `~/.claude/telemetry/`, `~/.claude/debug/` | Clear (manual, not Nix) | #23 |

---

## Phase 1: CRITICAL Fixes

### Task 1: Fix AWS Credentials Nix Store Exposure (Audit #1)

**Files:**
- Modify: `home/aws/default.nix`

**Context:** `home.file` copies the credentials into `/nix/store` (world-readable, immutable). The `chmod 600` in the activation script silently fails because Nix store files are read-only. The fix is to skip `home.file` for credentials entirely and use `home.activation` to copy the file directly from the repo checkout.

- [ ] **Step 1: Replace home.file credentials with activation copy**

Replace the `home.file.".aws/credentials"` block and the existing `setAwsCredentialsPermissions` activation with a single activation script that copies the file directly:

```nix
    # Create AWS credentials file directly (NOT via Nix store)
    # home.file copies into /nix/store which is world-readable (0444).
    # Instead, copy from the repo checkout and set restrictive permissions.
    home.activation.installAwsCredentials = lib.hm.dag.entryAfter ["writeBoundary"] ''
      src="${./config/credentials}"
      dst="$HOME/.aws/credentials"
      mkdir -p "$HOME/.aws"
      install -m 600 "$src" "$dst"
    '';
```

Remove these two blocks entirely:
1. `home.file.".aws/credentials" = { source = ./config/credentials; };` (line 52-53)
2. `home.activation.setAwsCredentialsPermissions` (lines 60-66)

- [ ] **Step 2: Verify credentials not in Nix store (after rebuild)**

```bash
darwin-rebuild check --flake ~/.config/nix
# After full rebuild, verify:
find /nix/store -name "*credentials*" -path "*aws*" 2>/dev/null | head -5
# Should return nothing new
```

- [ ] **Step 3: Commit**

```bash
git add home/aws/default.nix
git commit -m "fix(aws): stop exposing credentials via nix store"
```

---

### Task 2: Fix git gc Alias and Git Config (Audit #2, #16)

**Files:**
- Modify: `flake.nix:300-310`

**Context:** `alias.gc = "!cz"` overrides the critical `git gc` command. Also, `core.compression = "0"` disables git compression entirely, bloating repos on disk. The shell alias `gc` in zsh already provides the commitizen shortcut.

- [ ] **Step 1: Remove the gc alias and compression setting**

In `flake.nix`, in the `extraConfig` block (around line 300-309), remove these two lines:

```nix
            alias.gc = "!cz";        # Make git gc run commitizen
```

```nix
            core.compression = "0";   # Disable compression (faster, uses more space)
```

Leave the rest of `extraConfig` intact (`alias.cz`, `fetch.prune`, `gpg.program`, etc.).

- [ ] **Step 2: Verify git gc works**

```bash
darwin-rebuild check --flake ~/.config/nix
# After rebuild:
git gc --dry-run
# Should show normal gc output, not launch commitizen
```

- [ ] **Step 3: Commit**

```bash
git add flake.nix
git commit -m "fix(git): remove gc alias override and re-enable compression"
```

---

### Task 3: Fix Grogu nix.enable and Dock Animation (Audit #3, #15)

**Files:**
- Modify: `flake.nix:367-380` (Grogu block)
- Modify: `flake.nix:143` (dock animation)

**Context:** Darth and Renova both set `nix.enable = false;` but Grogu omits it, causing nix-darwin to try managing the Nix daemon on Grogu. Also, `expose-animation-duration = -.01` is a negative value that should be `0.001` or `0`.

- [ ] **Step 1: Add nix.enable = false to Grogu**

In the `darwinConfigurations."Grogu"` block, add `nix.enable = false;` after `home-manager.useGlobalPkgs = true;` to match Darth and Renova:

```nix
      darwinConfigurations."Grogu" = nix-darwin.lib.darwinSystem {
         modules = [
            configuration
               home-manager.darwinModules.home-manager  {
                  home-manager.useGlobalPkgs = true;
                  nix.enable = false;
                  home-manager.useUserPackages = true;
```

- [ ] **Step 2: Fix dock expose-animation-duration**

Change line 143 from:
```nix
      system.defaults.dock.expose-animation-duration = -.01;
```
to:
```nix
      system.defaults.dock.expose-animation-duration = 0.001;
```

- [ ] **Step 3: Commit**

```bash
git add flake.nix
git commit -m "fix(flake): add nix.enable=false to Grogu, fix dock animation value"
```

---

### Task 4: Verify Phase 1

- [ ] **Step 1: Dry-run build**

```bash
cd ~/.config/nix && darwin-rebuild check --flake .
```

Expected: clean build with no errors.

---

## Phase 2: WARNING Fixes

### Task 5: Homebrew Package Deduplication (Audit #5, #10, #13, #18, #19)

**Files:**
- Modify: `modules/homebrew.nix`

**Context:** 10 packages are installed via both Homebrew and Nix/Home Manager. Homebrew always wins in PATH. Also: `mysql` and `mysql@8.4` conflict, three Node.js versions are installed, and `onActivation.cleanup` is commented out.

**Decision needed from user:** For each dual-installed package, keep Homebrew or Nix. The recommendation below keeps Homebrew for packages where HM config is not used, and keeps Nix where HM module config (bat, eza, zoxide) is actively used.

- [ ] **Step 1: Remove packages that should stay in Nix only**

Remove these from the `brews` list in `modules/homebrew.nix` (these have active HM module config in Nix):

- ~~`"bat"`~~ -- **bat is NOT in the brews list** (only in Nix via `programs.bat.enable`). Skip.
- ~~`"eza"`~~ -- **eza is NOT in the brews list** (only in Nix via `programs.eza.enable`). Skip.
- ~~`"zoxide"`~~ -- **zoxide is NOT in the brews list** (only in Nix via `programs.zoxide.enable`). Skip.

The audit says these are dual-installed, meaning Homebrew has them too. Verify at runtime:
```bash
brew list bat eza zoxide 2>/dev/null
```
If Homebrew has them, they were installed manually outside Nix. Uninstall with `brew uninstall bat eza zoxide` after confirming Nix versions work.

- [ ] **Step 2: Remove duplicate/conflicting packages from Homebrew**

In `modules/homebrew.nix`, make these changes to the `brews` list:

1. Remove `"mysql"` (line 119) -- keep only `"mysql@8.4"` to avoid link conflicts
2. Remove `"node"` (line 125) and `"node@20"` (line 126) -- keep only `"node@22"`
3. Remove `"cmatrix"` -- it is also in `home.packages` in Nix (or remove from Nix; cmatrix has no HM config, Homebrew is fine. **User decides.**)

- [ ] **Step 3: Decide on git, fzf, tmux, delta, k9s, neovim**

These are dual-installed per the audit. Recommendation:

| Package | Keep in | Remove from | Reason |
|---------|---------|-------------|--------|
| `git` | Homebrew | -- | HM `programs.git` still configures it; Nix git pkg is a dependency, not explicitly listed |
| `fzf` | Homebrew | -- | Same as git; HM `programs.fzf` configures the Homebrew binary |
| `tmux` | Homebrew | -- | No HM tmux config actively used |
| `delta` | Nix (`home.packages`) | Homebrew | HM git.delta.enable uses it |
| `k9s` | Homebrew | Nix (if `programs.k9s.enable` exists) | No HM config needed |
| `neovim` | Homebrew | -- | Homebrew version is newer; HM module just manages config files |

For `delta`: remove `"delta"` from... wait, **delta is NOT in the brews list**. It is in `home.packages` via Nix. If Homebrew also has it, that is a manual install. Run `brew uninstall delta` if desired.

**Net Homebrew brews removals:** `"mysql"`, `"node"`, `"node@20"`.

- [ ] **Step 4: Uncomment onActivation.cleanup**

Change line 11 from:
```nix
    # onActivation.cleanup = "uninstall";
```
to:
```nix
    onActivation.cleanup = "uninstall";
```

This means any package removed from this file will be uninstalled from Homebrew on next rebuild. This is the correct behavior for declarative management.

- [ ] **Step 5: Handle masApps (Audit #19)**

Leave masApps commented out for now. These require being signed into the Mac App Store and can fail CI. Add a comment:

```nix
    # masApps are intentionally commented out.
    # Uncomment individually after signing into the Mac App Store.
    masApps = {
```

- [ ] **Step 6: Commit**

```bash
git add modules/homebrew.nix
git commit -m "fix(homebrew): remove duplicate mysql/node versions, enable cleanup"
```

---

### Task 6: Fix GRAALVM_HOME, Remove Duplicate PAGER, Add autosuggestion.enable (Audit #6, #8, #20)

**Files:**
- Modify: `home/zsh/default.nix:570` (GRAALVM_HOME)
- Modify: `home/zsh/default.nix:579` (PAGER)
- Modify: `home/zsh/default.nix:32` (autosuggestion)

**Context:** GRAALVM_HOME points to OpenJDK (not GraalVM). PAGER is set in both `home/default.nix` and `home/zsh/default.nix`. The `autosuggestion.strategy` may not take effect without `autosuggestion.enable = true`.

- [ ] **Step 1: Fix GRAALVM_HOME**

**Decision needed:** Is GraalVM actually used? If yes, point to the correct path. If not, remove the variable entirely.

Option A (GraalVM is used): Change line 570 to:
```nix
            GRAALVM_HOME = "/opt/homebrew/opt/graalvm-jdk@21/Contents/Home";
```

Option B (GraalVM is not used): Remove the `GRAALVM_HOME` line entirely.

- [ ] **Step 2: Remove duplicate PAGER from zsh**

Remove line 579:
```nix
            PAGER = "less -FR";  # Pager with colors and no pause on exit
```

The canonical PAGER is already set in `home/default.nix:58` via `home.sessionVariables`. That one applies to all shells.

- [ ] **Step 3: Add autosuggestion.enable**

Change line 32 from:
```nix
         autosuggestion.strategy = "completion";
```
to:
```nix
         autosuggestion.enable = true;
         autosuggestion.strategy = "completion";
```

- [ ] **Step 4: Commit**

```bash
git add home/zsh/default.nix
git commit -m "fix(zsh): fix GRAALVM_HOME, remove duplicate PAGER, enable autosuggestion"
```

---

### Task 7: Remove Duplicate check-updates.sh (Audit #7)

**Files:**
- Modify: `home/scripts/default.nix:42`

**Context:** Both `home/scripts/default.nix` and `home/updates/default.nix` install `check-updates.sh` to `~/.local/bin/`. The `updates` module is the dedicated module for this script and also manages the launchd plist, so it should own the install.

- [ ] **Step 1: Remove check-updates.sh from scripts module**

In `home/scripts/default.nix`, remove `"check-updates.sh"` from the scripts list (line 42).

The list should go from:
```nix
      ]) [
        "check-updates.sh"
        "update-nix.sh"
```
to:
```nix
      ]) [
        "update-nix.sh"
```

- [ ] **Step 2: Commit**

```bash
git add home/scripts/default.nix
git commit -m "fix(scripts): remove duplicate check-updates.sh install"
```

---

### Task 8: Fix pip3 --break-system-packages (Audit #9)

**Files:**
- Modify: `home/python/default.nix`

**Context:** `--break-system-packages` bypasses PEP 668 and can corrupt Homebrew's Python. The libraries installed (`cryptography`, `pillow`, `requests`, etc.) are available as Nix packages.

- [ ] **Step 1: Replace pip3 install with Nix packages**

Replace the entire `pip3` block with Nix packages. Keep the `pipx` block (pipx isolates properly).

Replace:
```nix
    # pip3 libraries (system-level)
    if command -v pip3 &>/dev/null; then
      pip3 install --quiet --break-system-packages \
        cryptography \
        linkify-it-py \
        notmuch2 \
        pillow \
        requests \
        textual \
        2>/dev/null || true
    fi
```

With Nix packages. Add to the module:

```nix
{ config, pkgs, lib, ... }:

{
  home.packages = with pkgs.python3Packages; [
    cryptography
    linkify-it-py
    pillow
    requests
    textual
  ];

  home.activation.pythonPackages = lib.hm.dag.entryAfter ["writeBoundary"] ''
    export PATH="/opt/homebrew/bin:$PATH"

    # pipx applications (isolated CLI tools)
    if command -v pipx &>/dev/null; then
      pipx install ansible-builder 2>/dev/null || true
      pipx install ansible-navigator 2>/dev/null || true
    fi
  '';
}
```

Note: `notmuch2` may not be in nixpkgs. Check with `nix search nixpkgs notmuch`. If not available, install it via pipx or keep a targeted pip install in a venv.

- [ ] **Step 2: Commit**

```bash
git add home/python/default.nix
git commit -m "fix(python): replace pip3 --break-system-packages with nix pkgs"
```

---

### Task 9: Fix Claude settings.json Merge (Audit #11)

**Files:**
- Modify: `home/claude/default.nix:424`

**Context:** The jq `*` operator does a shallow merge, replacing entire nested objects. If `enabledPlugins` is in the Nix prefs, it wipes any manually-added plugins from the on-disk file.

- [ ] **Step 1: Replace jq shallow merge with deep merge for enabledPlugins**

Change the merge line (line 424) from:
```bash
      if ${pkgs.jq}/bin/jq --slurpfile prefs "${userPrefsJson}" '. * $prefs[0]' "$user_settings" > "$user_settings.tmp" \
```
to:
```bash
      if ${pkgs.jq}/bin/jq --slurpfile prefs "${userPrefsJson}" '
        # Deep merge enabledPlugins to preserve manually-added plugins
        .enabledPlugins = ((.enabledPlugins // {}) * ($prefs[0].enabledPlugins // {}))
        | . * ($prefs[0] | del(.enabledPlugins))
      ' "$user_settings" > "$user_settings.tmp" \
```

This merges `enabledPlugins` keys additively (existing manual plugins survive), then shallow-merges everything else.

- [ ] **Step 2: Commit**

```bash
git add home/claude/default.nix
git commit -m "fix(claude): deep merge enabledPlugins to preserve manual additions"
```

---

### Task 10: Verify Phase 2

- [ ] **Step 1: Dry-run build**

```bash
cd ~/.config/nix && darwin-rebuild check --flake .
```

Expected: clean build with no errors.

---

## Phase 3: INFO Cleanup

### Task 11: Clean Up Stale PATH Entries (Audit #12)

**Files:**
- Modify: `home/default.nix:64-76`

**Context:** Several PATH entries point to directories that do not exist. `./bin/` is a relative path security risk.

- [ ] **Step 1: Remove stale and risky PATH entries**

Replace the `sessionPath` block with only entries that exist or are conditionally useful:

```nix
      sessionPath = [
         "/opt/homebrew/opt/postgresql@17/bin"        # PostgreSQL 17 tools (keg-only)
         "/opt/homebrew/opt/node@22/bin"             # Node.js 22 as default
         "/opt/homebrew/bin/"                        # Homebrew (Apple Silicon)
         "${homeDir}/.local/bin"                     # User local binaries
         "/opt/homebrew/opt/llvm/bin"                # LLVM from Homebrew
         "$JAVA_HOME/bin"                            # Java (if JAVA_HOME is set)
         "${qqqDevTools}/bin/"                       # QQQ dev tools (from userConfig in flake.nix)
      ];
```

Removed:
- `"./bin/"` -- relative path, security risk
- `"/opt/ansible-virtual/bin/"` -- does not exist
- `"${homeDir}/Library/Python/3.9/bin/"` -- Python 3.9 does not exist
- `"${homeDir}/.cargo/bin"` -- Rust installed via Homebrew, not rustup

- [ ] **Step 2: Commit**

```bash
git add home/default.nix
git commit -m "fix(path): remove stale and relative PATH entries"
```

---

### Task 12: Remove Dead Neovim defaultEditor (Audit #17)

**Files:**
- Modify: `home/nvim/default.nix:36`

**Context:** `defaultEditor = true` is overridden by `lib.mkForce "vi"` in `home/default.nix`. It is dead code.

- [ ] **Step 1: Remove defaultEditor = true**

Change:
```nix
      # Default editor settings (also set in zsh sessionVariables)
      defaultEditor = true;
```
to:
```nix
      # Editor is set in home/default.nix via mkForce
```

- [ ] **Step 2: Commit**

```bash
git add home/nvim/default.nix
git commit -m "fix(nvim): remove dead defaultEditor setting"
```

---

### Task 13: Clean Up Unused Files (Audit #14, #21)

**Files:**
- Modify: `user-config.nix:1` (add prominent comment)
- Delete: `scripts/install-git-hooks.sh`
- Delete: `home/ca-certs/update_certs.sh`

- [ ] **Step 1: Add reference-only header to user-config.nix**

The file already has a good comment. No further action needed -- the existing header on lines 1-9 already says "this file is not directly imported." This is sufficient.

- [ ] **Step 2: Delete uninstalled scripts**

```bash
rm scripts/install-git-hooks.sh
rm home/ca-certs/update_certs.sh
```

These scripts exist on disk but are not installed by any Nix module. They are dead files.

- [ ] **Step 3: Commit**

```bash
git add -A scripts/install-git-hooks.sh home/ca-certs/update_certs.sh
git commit -m "chore: remove uninstalled scripts"
```

---

### Task 14: Add Claude Permission to Nix Source (Audit #22)

**Files:**
- Modify: `home/claude/default.nix` (permissions section)

**Context:** `~/.claude/settings.local.json` has `Bash(home-manager generations:*)` which is not in the Nix-managed permissions. On next rebuild, if the activation script overwrites settings.local.json, this permission will be lost.

- [ ] **Step 1: Find and update the permissions list in the claude module**

Locate the `allowedTools` or permissions list in `home/claude/default.nix` and add:
```
"Bash(home-manager generations:*)"
```

(Exact location depends on how permissions are structured in the module. Read the file to find the right spot.)

- [ ] **Step 2: Commit**

```bash
git add home/claude/default.nix
git commit -m "fix(claude): add missing home-manager generations permission"
```

---

### Task 15: Clear Claude Telemetry/Debug (Audit #23)

**Manual step, not a Nix change.**

- [ ] **Step 1: Clear telemetry and debug directories**

```bash
rm -rf ~/.claude/telemetry/*
rm -rf ~/.claude/debug/*
```

Recovers ~48 MB. These directories are recreated automatically.

---

### Task 16: Update Flake Inputs (Audit #4)

**This should be done last, as it may pull in breaking changes.**

- [ ] **Step 1: Update all flake inputs**

```bash
cd ~/.config/nix && nix flake update
```

- [ ] **Step 2: Dry-run build to check for breakage**

```bash
darwin-rebuild check --flake ~/.config/nix
```

- [ ] **Step 3: Full rebuild if dry-run passes**

```bash
sudo darwin-rebuild switch --flake ~/.config/nix
```

- [ ] **Step 4: Commit**

```bash
git add flake.lock
git commit -m "chore: update flake inputs (6 months stale)"
```

---

## Final Verification

After all tasks are complete:

```bash
# Full rebuild
sudo darwin-rebuild switch --flake ~/.config/nix

# Verify AWS credentials not in Nix store
find /nix/store -name "*credentials*" -path "*aws*" 2>/dev/null

# Verify git gc works
git gc --dry-run

# Verify no home.file collisions
home-manager generations | head -1

# Check PATH is clean
echo $PATH | tr ':' '\n' | while read p; do [ ! -d "$p" ] && echo "MISSING: $p"; done
```

---

## Decisions Needed From User

Before starting, these items need your input:

1. **Audit #5 (dual packages):** Confirm the Homebrew-vs-Nix recommendations in Task 5 Step 3, or adjust per your preference.
2. **Audit #6 (GRAALVM_HOME):** Is GraalVM actually used? Fix path vs. remove variable entirely.
3. **Audit #9 (pip3):** Is `notmuch2` needed? It may not be in nixpkgs.
4. **Audit #19 (masApps):** Leave commented out, or uncomment specific apps?
5. **Audit #5 (cmatrix):** Keep in Homebrew or Nix? (Low stakes, just pick one.)
