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

      # Terminal capabilities - true color (24-bit) support
      set -g default-terminal "tmux-256color"
      set -ga terminal-overrides ",xterm-256color:Tc:RGB,wezterm:Tc:RGB"
      set -g allow-passthrough on
      set -ga update-environment "COLORTERM"

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

      # Session management
      # prefix+s: built-in session picker (tree view)
      # prefix+S: create a new named session interactively
      bind S command-prompt -p "new session name:" "new-session -s '%%'"

      # Help menu - prefix+space shows a shortcut cheat sheet
      bind Space display-menu -T " Tmux Shortcuts " -x C -y C "Split Horizontal     |" '"' "split-window -h" "Split Vertical       -" '%' "split-window -v" "" "New Window           c" 'c' "new-window" "Next Window          n" 'n' "next-window" "Prev Window          p" 'p' "previous-window" "Pick Window          w" 'w' "choose-tree -Zw" "" "Pick Session         s" 's' "choose-tree -Zs" "New Session          S" 'S' "command-prompt -p 'new session:' 'new-session -s \"%%\"'" "Rename Session       $" '$' "command-prompt -I '#S' 'rename-session -- \"%%\"'" "Detach               d" 'd' "detach-client" "" "Zoom Pane            z" 'z' "resize-pane -Z" "Kill Pane            x" 'x' "confirm-before -p 'kill pane? (y/n)' kill-pane" "Break Pane to Window !" '!' "break-pane" "" "Copy Mode        Enter" '[' "copy-mode" "Screensaver          L" 'L' "lock-session" "" "All Keybindings      ?" '?' "list-keys"

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
