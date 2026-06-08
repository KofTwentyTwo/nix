# Tmux Configuration
# ==================
# Tmux setup with terminal screensaver and hacker-style status bar.
# Matches starship prompt aesthetic (bold green, nerd fonts, structured).
#
# Features:
#   - Mouse ON for scroll wheel (enter copy-mode + scroll pane history), but
#     drag bindings are unbound so WezTerm still owns drag-to-select / Cmd+C
#     natively (pre-tmux copy/paste UX). Shift+drag is the universal bypass
#     if you ever need it inside copy-mode or Neovim.
#   - PageUp/PageDown scroll terminal history (keyboard alternative)
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
  # that's what actually runs the user's server.
  #
  # Socket discovery: tmux derives its server socket as $TMPDIR/tmux-$UID/default
  # (TMUX_TMPDIR > TMPDIR > /tmp). On macOS, an interactive shell gets a
  # per-user TMPDIR from launchd (/var/folders/<hash>/T/), but the running
  # tmux server's socket actually lives under /tmp because of how it was
  # launched. Worse, nix-darwin invokes this activation through
  # `launchctl asuser ... sudo -u ... --set-home ...`, and sudo strips TMPDIR
  # from the env. So a plain `tmux list-sessions` inside this script
  # resolves to a socket path that doesn't match the live server — the
  # rebuild then mis-reports "no running server" every time.
  #
  # Fix: probe candidate sockets explicitly via `tmux -S <path>` so
  # discovery doesn't depend on the activation's env.
  home.activation.reloadTmux = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    tmux_bin="/opt/homebrew/bin/tmux"
    if [ ! -x "$tmux_bin" ]; then
      tmux_bin="${pkgs.tmux}/bin/tmux"
    fi

    uid="$(/usr/bin/id -u)"
    # ''${TMPDIR:-} not ''${TMPDIR%/}: activation runs under `set -u` and
    # sudo strips TMPDIR, so referencing it directly aborts the rebuild.
    # An empty value collapses to "/tmux-$uid/default", which the [ -S ]
    # test below safely rejects.
    candidates=(
      "/tmp/tmux-$uid/default"
      "''${TMPDIR:-}/tmux-$uid/default"
    )

    echo "tmux: probing for live server (bin=$tmux_bin uid=$uid TMPDIR=''${TMPDIR:-unset})"
    reloaded=0
    for sock in "''${candidates[@]}"; do
      if [ ! -S "$sock" ]; then
        echo "tmux:   $sock: not a socket"
        continue
      fi
      # Test list-sessions in the `if` condition, NOT as `ls_out=$(...); rc=$?`.
      # Activation runs under `set -e`, where a bare command-substitution
      # assignment that fails aborts the entire switch before `$?` can be read.
      # A stale/dead tmux socket makes list-sessions exit non-zero, which would
      # otherwise kill the rebuild. The `if` form is errexit-safe (and matches
      # the source-file check below).
      if ls_out=$("$tmux_bin" -S "$sock" list-sessions 2>&1); then
        echo "tmux:   $sock: live (sessions found)"
        if out=$("$tmux_bin" -S "$sock" source-file "$HOME/.config/tmux/tmux.conf" 2>&1); then
          echo "tmux: reloaded config in running server ($sock)"
          reloaded=1
          break
        else
          echo "tmux: source-file failed against $sock: $out" >&2
        fi
      else
        echo "tmux:   $sock: list-sessions failed: $ls_out"
      fi
    done

    if [ $reloaded -eq 0 ]; then
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

      # Extended keys: pass Shift+Enter / Ctrl+Enter / Alt+Enter through to TUI
      # apps. Without this, modified Enter collapses to plain Enter and apps
      # like pi and Claude Code can't tell "send" from "newline in input box".
      # The terminal-features line below tells tmux that WezTerm supports the
      # extended-keys encoding (CSI u), so it knows when to emit it.
      #
      # Format: csi-u (universal CSI u encoding) over the default xterm-style
      # modifyOtherKeys — pi requires csi-u; WezTerm supports both.
      #
      # NOTE: scope is `-s` (server), not `-g`. In tmux 3.6 these live in the
      # server-options namespace; `set -g` silently no-ops and the warning stays.
      set -s extended-keys on
      set -s extended-keys-format csi-u

      # Terminal capabilities - true color (24-bit) support
      set -g default-terminal "tmux-256color"
      set -g terminal-overrides "xterm-256color:Tc:RGB,wezterm:Tc:RGB"
      set -g allow-passthrough on
      set -ga update-environment "COLORTERM"

      # Window title: show session name in WezTerm's Cmd+Tab / title bar
      set -g set-titles on
      set -g set-titles-string "#{session_name}"

      # Clipboard: enable OSC 52 for WezTerm + pbcopy fallback
      # Extkeys: declare that WezTerm supports the extended-keys CSI u encoding
      # (consumed by `set -g extended-keys on` above).
      set -ga terminal-features 'wezterm:clipboard:extkeys'
      set -g copy-command 'pbcopy'

      # Mouse ON for scroll-wheel scrollback, but drag bindings are unbound so
      # WezTerm still owns drag-to-select + Cmd+C natively (matching pre-tmux
      # UX). This walks the line between the two tmux mouse behaviors:
      #   - Wheel in a tmux pane -> enter copy-mode, scroll pane history
      #   - Drag in a tmux pane -> falls through to WezTerm as a raw selection
      # Shift+drag in WezTerm remains the universal bypass (configured in
      # home/wez/config/wezterm.lua) for selecting inside Neovim or copy-mode.
      set -g mouse on
      unbind -n MouseDrag1Pane
      unbind -n MouseDown1Pane
      unbind -T copy-mode MouseDrag1Pane
      unbind -T copy-mode-vi MouseDrag1Pane

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

      # Lock screen: cmatrix + PIN after 30 minutes idle, prefix+L to trigger manually
      set -g lock-after-time 1800
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

      # Top bar (per-pane): repo/branch left, path right.
      # Solves pane redraw latency by querying git status asynchronously via git-pane-info.sh.
      set -g pane-border-status top
      set -g pane-border-format "#(git-pane-info.sh #{pane_current_path})#[align=right]#[fg=#444444][#[fg=#888888]#{pane_current_path}#[fg=#444444]]────"
      set -g pane-border-style "fg=#444444"
      set -g pane-active-border-style "fg=green"
    '';
  };
}
