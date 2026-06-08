# Homebrew Package Management
# ===========================
# All Homebrew taps, formulae, casks, and Mac App Store apps.
# Imported by flake.nix as a nix-darwin module.

{ pkgs, config, ... }:

let
  # Third-party (non-official) Homebrew taps. Each is explicitly vouched for
  # here, so all of them are marked trusted via trust.json below. Referenced by
  # both `homebrew.taps` and the tap-trust writer so the two can never drift.
  trustedTaps = [
    "antoniorodr/memo"
    "charmbracelet/tap"
    "koftwentytwo/tap"
    "qrun-io/qctl"
    "steipete/tap"
    "tilt-dev/tap"
  ];
in
{
  # Trust all declared third-party taps.
  # ====================================
  # Homebrew 5.1+ refuses to load formulae/casks from non-official taps unless
  # they're trusted (`HOMEBREW_REQUIRE_TAP_TRUST` defaults to true). An
  # untrusted tap aborts `brew upgrade` with "Refusing to load formula ... from
  # untrusted tap" and makes `brew bundle` spam outdated-check warnings.
  #
  # The `HOMEBREW_NO_REQUIRE_TAP_TRUST` escape hatch is a dead end: it's
  # deprecated upstream (slated for removal) and never reached the brew commands
  # anyway — nix-darwin runs `brew bundle` / `brew upgrade` under
  # `sudo --preserve-env=PATH`, which strips every other env var, so setting it
  # in `environment.variables` silently did nothing in the activation context.
  #
  # brew reads `~/.homebrew/trust.json` regardless of the environment, and
  # trusting a tap short-circuits the per-formula/per-cask trust check, so we
  # write that file declaratively from `trustedTaps`. preActivation runs as root
  # early — before both nix-darwin's `brew bundle` and the upgrade hook below —
  # so the trust file is in place before any tap is loaded.
  system.activationScripts.preActivation.text =
    let
      user = config.system.primaryUser;
      trustJson = pkgs.writeText "homebrew-trust.json"
        (builtins.toJSON { trustedtaps = trustedTaps; });
    in
    ''
      echo >&2 "Trusting declared Homebrew taps (trust.json)..."
      install -d -o ${user} -g staff -m 0755 "/Users/${user}/.homebrew"
      install -o ${user} -g staff -m 0644 ${trustJson} "/Users/${user}/.homebrew/trust.json"
    '';

  # Post-bundle global brew upgrade.
  # ================================
  # nix-darwin's brew bundle (below) only operates on what's declared in
  # this file. Transitive dependencies (e.g. libheif, luajit pulled in by
  # other casks) and any one-off `brew install foo` packages that aren't
  # declared here are left untouched on every rebuild and drift behind
  # upstream until manually upgraded. This hook closes that gap: after
  # nix-darwin runs its brew bundle, we run a global `brew upgrade` so
  # everything brew knows about — declared, transitive, or manual — gets
  # bumped on every `darwin-rebuild switch`.
  #
  # This is the ONLY upgrade path: `onActivation.upgrade` is deliberately false
  # (see below) because nix-darwin's `brew bundle` runs unguarded under the
  # activation's `set -e`, so an upgrade failure there would abort the whole
  # switch. That option also only touches Brewfile-declared deps; a bare
  # `brew upgrade` outside the bundle catches transitive + undeclared brews too.
  #
  # Runs as the primary user via `sudo --user=<primaryUser>`: brew refuses
  # to operate on its prefix as root, so we mirror the same sudo-drop
  # pattern nix-darwin's own brew bundle activation uses. HOMEBREW_NO_AUTO_UPDATE=1
  # avoids a redundant metadata refresh — `onActivation.autoUpdate = true`
  # already refreshed it before the bundle step.
  #
  # Non-fatal: a single broken formula or transient network hiccup logs
  # a warning but does not abort the rest of the activation.
  system.activationScripts.postActivation.text = ''
    if [ -x /opt/homebrew/bin/brew ]; then
      echo >&2 "Upgrading remaining brew packages (transitive deps + undeclared brews)..."
      PATH="/opt/homebrew/bin:$PATH" \
      sudo \
        --preserve-env=PATH \
        --user=${config.system.primaryUser} \
        --set-home \
        env HOMEBREW_NO_AUTO_UPDATE=1 \
        /opt/homebrew/bin/brew upgrade 2>&1 \
        || echo >&2 "[brew-upgrade-all] non-zero exit; some packages may not be current"
    fi
  '';

  homebrew = {
    enable = true;
    # Uninstall any formula/cask/MAS app not declared here on every switch.
    # We drive this with `--force-cleanup` (via extraFlags) rather than
    # nix-darwin's `onActivation.cleanup = "uninstall"`: that option emits the
    # bare `--cleanup` switch, which Homebrew now deprecates ("Calling the
    # `--cleanup` switch is deprecated! There is no replacement."). Per brew's
    # source (bundle/subcommand/install.rb) `--force-cleanup` alone performs the
    # same non-interactive cleanup — `cleanup_requested = args.force_cleanup? ||
    # args.cleanup?` — without the deprecation warning.
    onActivation.extraFlags = [ "--force-cleanup" ];
    # Do NOT upgrade during the bundle. nix-darwin's `brew bundle` runs unguarded
    # under the system activation's `set -e`, so with upgrade enabled a single
    # flaky cask/formula upgrade (a 404, a build failure, a transient network
    # hiccup) aborts the ENTIRE `darwin-rebuild switch` with exit 1. Instead the
    # bundle only installs missing declared deps + cleans up undeclared ones
    # (rarely fails), and all upgrades are handled by the `|| echo`-guarded
    # `brew upgrade` postActivation hook above — which keeps AI tools (claude,
    # codex, gemini-cli, etc.) and everything else current without ever aborting
    # the switch. The `switch` wrapper's error scan still surfaces brew failures
    # as a clear ✗ box.
    onActivation.upgrade = false;
    # Refresh brew's package metadata before upgrading so we pull the latest versions.
    onActivation.autoUpdate = true;

    taps = trustedTaps;

    # Mac App Store apps (managed via mas CLI 6.0+)
    # IMPORTANT: `--force-cleanup` (extraFlags above) uninstalls anything not
    # declared here, so any MAS app not listed is removed on
    # `darwin-rebuild switch`. Re-add any you want to keep.
    masApps = {
      "1Password for Safari"         = 1569813296;
      "aSPICE Pro"                   = 1560593107;
      "Airmail"                      = 918858936;
      "Blackmagic Disk Speed Test"   = 425264550;
      "DaisyDisk"                    = 411643860;
      "GarageBand"                   = 682658836;
      "iMovie"                       = 408981434;
      "Kagi for Safari"              = 1622835804;
      "Keynote"                      = 409183694;
      "LanScan"                      = 472226235;
      "MindNode"                     = 6446116532;
      "Numbers"                      = 409203825;
      "Pages"                        = 409201541;
      "Parcel - Delivery Tracking"   = 375589283;
      "Unread"                       = 1363637349;
      "Xcode"                        = 497799835;
    };

    brews = [
      "ack"
      "act"
      "age"
      "aerc"
      "aicommits"
      "ansible"
      "ansible-creator"
      "ansible-lint"
      "argocd"
      "arping"
      "asciiquarium"
      "ast-grep"
      "awscli"
      "bash"
      "bfg"
      "binwalk"
      "boxes"
      "btop"
      "calicoctl"
      "cargo-dist"        # `dist` release/installer generator (generated workflows pin dist 0.x)
      "cargo-spellcheck"
      "cbonsai"
      "charmbracelet/tap/gum"
      "circleci"
      "cloudflare-speed-cli"
      "clang-format"
      "cloc"
      "cmake"
      "cmatrix"
      "colima"
      "cmctl"
      "commitizen"
      "commitlint"
      "composer"
      "cosign"
      "coreutils"
      "coturn"
      "cowsay"
      "curl"
      "dialog"
      "difftastic"
      "dua-cli"
      "doggo"
      "duf"
      "dust"
      "eksctl"
      "fastfetch"
      "fd"
      "firebase-cli"
      "ffmpeg"
      "gemini-cli"
      "fish"
      "fzf"
      "gh"
      "git"
      "git-absorb"
      "git-crypt"
      "gitea"
      "gitleaks"
      "gdu"
      "genact"
      "glow"
      "gnu-sed"
      "gnupg"
      "go"
      "go-task"
      "gradle"
      "gping"
      "helm"
      "helmfile"
      "himalaya"
      "htop"
      "hyperfine"
      "imagemagick"
      "steipete/tap/imsg"
      { name = "inetutils"; link = false; }
      "iperf3"
      "jq"
      "julia"
      "k9s"
      "krew"
      "kubectx"
      "kubernetes-cli"
      "kubeseal"
      "kustomize"
      "lazydocker"
      "lavat"
      "lazygit"
      "ldapvi"
      "liquibase"
      "llvm"
      "lua"
      "luarocks"
      "markdownlint-cli2"
      "mas"
      "maven"
      "antoniorodr/memo/memo"
      "mtr"
      "minio-mc"
      "mysql@8.4"
      "ncdu"
      "neovim"
      "ninja"
      "no-more-secrets"
      "nmap"
      "node@24"  # current Active LTS; the default node (see home/default.nix sessionPath)
      "koftwentytwo/tap/notion-sql"  # Notion CLI manager + scripts
      "numpy"
      "openai-whisper"
      "opencode"
      "openjdk@21"
      "opentofu"
      "pandoc"
      "steipete/tap/peekaboo"
      "pinentry-mac"
      "pipes-sh"
      "pipx"
      "platformio"
      "pnpm"
      "poppler"
      "prettyping"
      "postgresql@17"
      "procs"
      "pv"
      "pwgen"
      "python-packaging"
      "python@3.13"
      "pytorch"
      "qrun-io/qctl/qctl"
      "steipete/tap/remindctl"
      "ripgrep"
      # Rust toolchain is managed by rustup (NOT the `rust` formula). rustup is
      # required for the cross-compile targets `dist` checks/installs, and it
      # conflicts_with "rust" in Homebrew — they cannot coexist. rustfmt, clippy
      # AND rust-analyzer come from rustup components, NOT brew: rustup proxies
      # those tool names on PATH, so a brew `rust-analyzer` would be shadowed by
      # rustup's proxy and recurse infinitely. See home/rust for toolchain setup.
      "rustup"
      "sd"
      "sdl2"
      "semgrep"
      "shellcheck"
      "sops"
      "sqlfluff"
      "sshpass"
      "stern"
      "stuntman"
      "talosctl"
      "terragrunt"
      "tfenv"
      "tilt"
      "tokei"
      "tldr"
      "tmux"
      "tree"
      "tty-clock"
      "uv"
      "velero"
      "w3m"
      "watch"
      "weasyprint"
      "wget"
      "wimlib"
      "wireshark"
      "xcodegen"
      "xh"
      "yamllint"
      "yq"
      "zlib"
    ];

    casks = [
      "1password"
      "1password-cli"
      "adobe-creative-cloud"
      "alfred"
      "alt-tab"
      "arc"
      "aws-vpn-client"
      "backblaze"
      "balenaetcher"
      "bambu-studio"
      "bettertouchtool"
      "chatgpt"
      "claude"
      # claude-code: installed via npm (-g @anthropic-ai/claude-code) instead of Homebrew
      # Reason: Homebrew cask lags Anthropic's release cadence. npm gives same-day releases.
      "cleanshot"
      "codex"      # Codex CLI (terminal coding agent)
      "codex-app"  # Codex desktop GUI (manages coding agents)
      "connectmenow"
      "darktable"
      "dbeaver-community"
      "devonthink"
      "docker-desktop"
      "drawio"
      "ecamm-live"
      "elgato-camera-hub"
      "elgato-stream-deck"
      "fantastical"
      "freecad"
      "github"
      "graalvm-jdk"
      "graalvm-jdk@21"
      "inkscape"
      "intellij-idea"
      "istat-menus"
      "jetbrains-toolbox"
      "jump-desktop"
      "karabiner-elements"
      "keyboard-maestro"
      "lens"
      "lm-studio"
      "loopback"
      "mactex-no-gui"
      "notion-calendar"
      "notion-mail"
      "notion"
      "obsidian"
      "ollama-app"
      "omnifocus"
      "omnigraffle"
      "omniplan"
      "openwebstart"
      # Not adding 1kc-razer or openrgb: neither supports the Huntsman V3 Pro
      # (PID 0x02a6) as of 2026-04. Verified by inspecting 1kc-razer v0.4.10's
      # bundled device list — covers V1/V2 families but not V3. Reliable fix
      # for V3 Pro RGB-on-wake remains physical unplug/replug; pmset settings
      # in flake.nix reduce how often that's needed. Re-evaluate when
      # community Mac support catches up to V3 protocol.
      "rectangle"
      "rustdesk"
      "session-manager-plugin"
      "slack"
      "slack-cli"
      "tailscale-app"
      "viscosity"
      "typora"
      "visual-studio-code"
      "warp"
      "wezterm"
      "wireshark-chmodbpf"
      "zoom"
    ];
  };
}
