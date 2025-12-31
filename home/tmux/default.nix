# Tmux Configuration
# ==================
# Tmux setup with terminal screensaver and hacker-style status bar.
# Matches starship prompt aesthetic (bold green, nerd fonts, structured).
#
# Features:
#   - Mouse scroll enters copy mode (scrolls terminal history)
#   - PageUp/PageDown scroll terminal history
#   - Increased history-limit for Claude Code compatibility
#   - Fast escape-time for responsive TUI apps

{ pkgs, ... }:

{
  # Install cmatrix for the lock screen effect
  home.packages = with pkgs; [
    cmatrix
  ];

  # Enable tmux with screensaver and status bar
  programs.tmux = {
    enable = true;

    extraConfig = ''
      # Performance and responsiveness
      set -sg escape-time 0
      set -g history-limit 50000

      # Terminal capabilities
      set -g default-terminal "tmux-256color"
      set -ga terminal-overrides ",xterm-256color:Tc,wezterm:Tc"

      # Mouse support - scroll enters copy mode for terminal history
      set -g mouse on

      # Mouse wheel scrolling - enter copy mode and scroll
      bind -n WheelUpPane if-shell -F -t = "#{mouse_any_flag}" "send-keys -M" "if -Ft= '#{pane_in_mode}' 'send-keys -M' 'select-pane -t=; copy-mode -e; send-keys -M'"
      bind -n WheelDownPane select-pane -t= \; send-keys -M

      # PageUp/PageDown - enter copy mode and scroll
      bind -n PageUp if-shell -F "#{pane_in_mode}" "send-keys PageUp" "copy-mode -eu"
      bind -n PageDown if-shell -F "#{pane_in_mode}" "send-keys PageDown" ""

      # Stay in copy mode after mouse selection (don't auto-exit)
      unbind -T copy-mode-vi MouseDragEnd1Pane

      # Screensaver: lock after 15 minutes (900 seconds) of inactivity
      set -g lock-after-time 900
      set -g lock-command "/opt/homebrew/bin/cmatrix -s"

      # Status bar - hacker aesthetic matching starship prompt
      set -g status on
      set -g status-interval 1
      set -g status-position bottom

      # Two-line status: top line is separator, bottom line is content
      set -g status 2
      set -g status-format[0] "#[fg=green]────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────"
      # Note: Removed shell commands (sysctl, whoami) - they spawn processes every interval and cause lag
      set -g status-format[1] "#[fg=green,bold]  #S #[fg=green]░▒▓ #[fg=white]#I:#W#[align=right]#[fg=yellow]#H #[fg=green]│ #[fg=cyan] %H:%M:%S #[fg=green]│ #[fg=white]󰃰 %d-%b-%y "

      # Colors - match starship (green borders, black bg)
      set -g status-style "bg=black,fg=green"
      set -g message-style "bg=black,fg=green,bold"

      # Pane borders - green to match
      set -g pane-border-style "fg=#444444"
      set -g pane-active-border-style "fg=green,bold"
    '';
  };
}
