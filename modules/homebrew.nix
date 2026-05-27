# Homebrew Package Management
# ===========================
# All Homebrew taps, formulae, casks, and Mac App Store apps.
# Imported by flake.nix as a nix-darwin module.

{ pkgs, config, ... }:

{
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
  # Why a separate hook rather than relying on `homebrew.onActivation.upgrade`:
  # that option just toggles `--no-upgrade` on `brew bundle`, which still
  # only touches Brewfile-declared deps. Catching the rest requires a
  # `brew upgrade` call outside the bundle.
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
    onActivation.cleanup = "uninstall";
    # Auto-upgrade all brew formulae and casks on every `darwin-rebuild switch`.
    # Keeps AI tools (chatgpt, claude, codex, codex-app, gemini-cli, aicommits,
    # ollama-app, openai-whisper) current; also upgrades all other brews as a side effect.
    onActivation.upgrade = true;
    # Refresh brew's package metadata before upgrading so we pull the latest versions.
    onActivation.autoUpdate = true;

    taps = [
      "antoniorodr/memo"
      "charmbracelet/tap"
      "qrun-io/qctl"
      "steipete/tap"
      "tilt-dev/tap"
    ];

    # Mac App Store apps (managed via mas CLI 6.0+)
    # IMPORTANT: With onActivation.cleanup="uninstall", any MAS app not listed
    # here is removed on `darwin-rebuild switch`. Re-add any you want to keep.
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
      "node@20"
      "node@22"
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
      "rust"
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
