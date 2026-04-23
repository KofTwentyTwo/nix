# Tmux Configuration
# ==================
# Tmux setup with terminal screensaver and hacker-style status bar.
# Matches starship prompt aesthetic (bold green, nerd fonts, structured).
#
# Features:
#   - Mouse OFF so WezTerm handles drag-to-select / Cmd+C natively
#     (pre-tmux copy/paste UX). Shift+drag is the universal bypass if you
#     ever need it inside copy-mode or Neovim. Scroll history via PageUp/PageDown.
#   - PageUp/PageDown scroll terminal history
#   - Increased history-limit for Claude Code compatibility
#   - Fast escape-time for responsive TUI apps

{ pkgs, lib, ... }:

{
  # Install cmatrix for the lock screen effect
  home.packages = with pkgs; [
    cmatrix
  ];

  # Auto-reload tmux config on `darwin-rebuild switch` if a server is running.
  # tmux reads tmux.conf once at server start; without this, edits only apply
  # to sessions created after the server restarts, which is confusing.
  #
  # We prefer the brew-installed tmux binary (/opt/homebrew/bin/tmux) because
  # that's what actually runs the user's server. Using pkgs.tmux here fails
  # silently on macOS: nix tmux resolves TMPDIR differently than brew tmux, so
  # list-sessions looks at the wrong socket path and returns no sessions even
  # when one is running. Stderr is captured so failures surface in rebuild
  # output instead of being swallowed.
  home.activation.reloadTmux = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    tmux_bin="/opt/homebrew/bin/tmux"
    if [ ! -x "$tmux_bin" ]; then
      tmux_bin="${pkgs.tmux}/bin/tmux"
    fi

    if "$tmux_bin" list-sessions >/dev/null 2>&1; then
      if out=$("$tmux_bin" source-file "$HOME/.config/tmux/tmux.conf" 2>&1); then
        echo "tmux: reloaded config in running server ($tmux_bin)"
      else
        echo "tmux: source-file failed: $out" >&2
      fi
    else
      echo "tmux: no running server, skipping reload"
    fi
  '';

  # Enable tmux with screensaver and status bar
  programs.tmux = {
    enable = true;

    plugins = with pkgs.tmuxPlugins; [
      {
        plugin = tmux-thumbs;
        extraConfig = ''
          set-environment -g PATH "/opt/homebrew/bin:$HOME/.nix-profile/bin:/run/current-system/sw/bin:/usr/bin:/bin"
          set -g @thumbs-key t
          set -g @thumbs-command 'echo -n {} | pbcopy'
          set -g @thumbs-upcase-command 'echo -n {} | pbcopy && tmux paste-buffer'
          set -g @thumbs-alphabet colemak-homerow
          set -g @thumbs-contrast 1
          set -g @thumbs-fg-color green
          set -g @thumbs-hint-fg-color yellow
        '';
      }
    ];

    extraConfig = ''
      # Performance and responsiveness
      set -sg escape-time 0
      set -g history-limit 50000

      # Terminal capabilities - true color (24-bit) support
      set -g default-terminal "tmux-256color"
      set -g terminal-overrides "xterm-256color:Tc:RGB,wezterm:Tc:RGB"
      set -g allow-passthrough on
      set -ga update-environment "COLORTERM"

      # Window title: show session name in WezTerm's Cmd+Tab / title bar
      set -g set-titles on
      set -g set-titles-string "#{session_name}"

      # Clipboard: enable OSC 52 for WezTerm + pbcopy fallback
      set -ga terminal-features 'wezterm:clipboard'
      set -g copy-command 'pbcopy'

      # Mouse OFF: let WezTerm own mouse input so drag-to-select + Cmd+C work
      # natively, matching the pre-tmux UX. Shift+drag is the universal bypass
      # (configured in home/wez/config/wezterm.lua) for selecting inside Neovim
      # or tmux copy-mode. Scrollback is via PageUp/PageDown (below).
      set -g mouse off

      # PageUp/PageDown - enter copy mode and scroll (keyboard-driven scrollback)
      bind -n PageUp if-shell -F "#{pane_in_mode}" "send-keys PageUp" "copy-mode -eu"
      bind -n PageDown if-shell -F "#{pane_in_mode}" "send-keys PageDown" ""

      # Session management
      # prefix+s: built-in session picker (tree view)
      # prefix+S: create a new named session interactively
      bind S command-prompt -p "new session name:" "new-session -s '%%'"

      # Help menu - prefix+space shows searchable command palette via fzf popup
      bind Space display-popup -E -w 70 -h 30 -T " Tmux Help " -b rounded "$HOME/.local/bin/tmux-help.sh"

      # Nested tmux (SSH): F12 toggles local keys off so prefix reaches remote tmux
      # Visual indicator: status bar dims to gray when in remote mode
      bind -T root F12 \
        set prefix None \;\
        set key-table off \;\
        set status-style "bg=black,fg=#555555" \;\
        set status-format[1] "#[fg=#555555]  #S ░▒▓ #I:#W#[align=right]#[fg=#aa5500] REMOTE #[fg=#555555]│  %H:%M │ 󰃰 %d-%b-%y " \;\
        if -F '#{pane_in_mode}' 'send-keys -X cancel' \;\
        refresh-client -S

      bind -T off F12 \
        set -u prefix \;\
        set -u key-table \;\
        set -u status-style \;\
        set status-format[1] "#[fg=green,bold]  #S #[fg=green]░▒▓ #[fg=white]#I:#W#[align=right]#[fg=yellow]#H #[fg=green]│ #[fg=cyan] %H:%M #[fg=green]│ #[fg=white]󰃰 %d-%b-%y " \;\
        refresh-client -S

      # Lock screen: cmatrix + PIN after 15 minutes idle, prefix+L to trigger manually
      set -g lock-after-time 900
      set -g lock-command "$HOME/.local/bin/tmux-lock.sh"
      bind L lock-session

      # Prompt to set lock PIN on first session if not configured
      set-hook -g session-created 'run-shell -b "$HOME/.local/bin/tmux-pin-check.sh"'
      # Prompt to name sessions with default numeric names (Enter to skip)
      set-hook -ga session-created 'run-shell -b "$HOME/.local/bin/tmux-session-name.sh"'

      # Status bar - hacker aesthetic matching starship prompt
      set -g status on
      set -g status-interval 5
      set -g status-position bottom

      # Bottom bar: separator + session/host/time
      set -g status 2
      set -g status-format[0] "#[fg=green]────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────"
      set -g status-format[1] "#[fg=green,bold]  #S #[fg=green]░▒▓ #[fg=white]#I:#W#[align=right]#[fg=yellow]#H #[fg=green]│ #[fg=cyan] %H:%M #[fg=green]│ #[fg=white]󰃰 %d-%b-%y "

      # Colors
      set -g status-style "bg=black,fg=green"
      set -g message-style "bg=black,fg=green,bold"

      # Top bar (per-pane): repo/branch left, path right
      set -g pane-border-status top
      set -g pane-border-format "#[fg=#444444][#[fg=#888888]#(cd #{pane_current_path} && basename $(git rev-parse --show-toplevel) 2>/dev/null || echo n/a)#[fg=#444444]] [#[fg=#888888]#(cd #{pane_current_path} && git rev-parse --abbrev-ref HEAD 2>/dev/null || echo n/a)#[fg=#444444]]#[align=right][#[fg=#888888]#{pane_current_path}#[fg=#444444]]────"
      set -g pane-border-style "fg=#444444"
      set -g pane-active-border-style "fg=green"
    '';
  };
}
