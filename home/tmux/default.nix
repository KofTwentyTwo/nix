# Tmux Configuration
# ==================
# Tmux setup with terminal screensaver and hacker-style status bar.
# Matches starship prompt aesthetic (bold green, nerd fonts, structured).
#
# Constraints respected:
#   - No mouse options (preserves existing mouse behavior)
#   - No clipboard options (preserves existing copy/paste behavior)
#   - No keybinding changes (minimal impact to workflow)

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
      set -g status-format[1] "#[fg=green,bold]  #S #[fg=green]░▒▓ #[fg=white]#I:#W#[align=right]#[fg=white] #(whoami)#[fg=green]@#[fg=yellow]#H #[fg=green]│ #[fg=purple]󱫋 #(sysctl -n vm.loadavg | cut -d' ' -f2) #[fg=green]│ #[fg=cyan] %H:%M:%S #[fg=green]│ #[fg=white]󰃰 %d-%b-%y "

      # Colors - match starship (green borders, black bg)
      set -g status-style "bg=black,fg=green"
      set -g message-style "bg=black,fg=green,bold"

      # Pane borders - green to match
      set -g pane-border-style "fg=#444444"
      set -g pane-active-border-style "fg=green,bold"
    '';
  };
}
