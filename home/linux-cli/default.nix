# Linux CLI Package Set
# =====================
# On macOS, the bulk of the user's command-line tools come from Homebrew
# (modules/homebrew.nix). Homebrew does not exist on Linux, so this module
# ports the CLI-relevant subset of those formulae to Nix packages for
# Linux/WSL. It is guarded to Linux only — macOS keeps getting these from
# Homebrew, so there is no duplaicate-PATH conflict and the Mac builds are
# completely unaffected.
#
# Deliberately NOT ported (with rationale):
#   - macOS-only:        pinentry-mac, mas, colima, imsg, peekaboo, remindctl,
#                        xcodegen, qctl/notion-sql/memo (private taps)
#   - already provided:  node@24/go/python@3.13 (mise), rustup (rustup),
#                        coreutils/gnu-sed/curl/wget/watch (native GNU on Linux),
#                        git/gnupg/fzf/tmux/k9s/bat/eza/zoxide/delta (programs.*)
#   - heavy / niche:     pytorch, openai-whisper, julia, llvm, sdl2, pandoc-heavy
#                        ML stacks, mysql@8.4 (run in Docker on WSL instead)
#   - GUI / servers:     wireshark (GUI), gitea, coturn, stuntman, platformio
# Add any of the above back here if you actually want them on WSL.

{ config, pkgs, lib, ... }:

{
  config = lib.mkIf pkgs.stdenv.isLinux {
    home.packages = with pkgs; [
      # --- search / files / text ---
      ripgrep          # rg
      fd               # required by the fzf widgets in home/default.nix
      sd               # sed-like find/replace
      ast-grep         # structural code search
      difftastic       # structural diff
      tokei            # code stats
      cloc
      glow             # markdown renderer
      jq
      yq-go            # yq
      w3m

      # --- system / monitoring / disk ---
      btop
      ncdu
      gdu
      dust             # du-dust
      duf
      dua              # dua-cli
      procs
      fastfetch
      hyperfine
      pv
      pwgen

      # --- git ---
      gh
      git-crypt
      git-absorb
      lazygit
      lazydocker
      gitleaks
      bfg-repo-cleaner # bfg

      # --- kubernetes / cloud / devops ---
      kubectx
      kubeseal
      kustomize
      kubernetes-helm  # helm
      helmfile
      stern
      argocd
      eksctl
      krew
      cmctl
      velero
      talosctl
      opentofu
      terragrunt
      tilt
      cosign
      sops
      go-task          # task
      age

      # --- networking ---
      nmap
      mtr
      gping
      doggo
      iperf3
      arping
      inetutils
      prettyping
      xh
      sshpass

      # --- build / language tooling ---
      cmake
      ninja
      gradle
      maven
      lua
      luarocks
      pipx
      uv               # also unblocks home/hermes
      pnpm
      semgrep
      shellcheck
      yamllint
      sqlfluff
      commitizen
      clang-tools      # clang-format
      ansible
      ansible-lint
      act              # run GitHub Actions locally
      circleci-cli     # circleci
      minio-client     # mc

      # --- media / docs ---
      ffmpeg
      imagemagick
      pandoc
      poppler-utils

      # --- fun / misc (parity with brew) ---
      cowsay
      cmatrix
      cbonsai
      asciiquarium
      pipes            # pipes-sh
      nms              # no-more-secrets
      boxes
      tty-clock
      genact
      gum
      tealdeer         # tldr
      ack
      binwalk
      himalaya
      aerc
    ];

    # WezTerm sets TERM=wezterm, but its terminfo entry isn't in the system
    # terminfo db on Linux — ncurses tools (clear, less, tmux, vim) then fail
    # with "'wezterm': unknown terminal type". The entry ships in the nix
    # profile (wezterm provides share/terminfo); point ncurses at it. macOS
    # WezTerm installs its terminfo system-wide, so this is Linux-only.
    home.sessionVariables.TERMINFO_DIRS =
      "${config.home.profileDirectory}/share/terminfo:/usr/share/terminfo";
  };
}
