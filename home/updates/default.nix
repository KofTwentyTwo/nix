# Update Checker Module
# =====================
# Configures automatic update checking for brew and nix flake
# Checks daily and creates a notification file if updates are available
#
# Features:
#   - Daily check for brew package updates
#   - Daily check for nix flake input updates
#   - Notification file created when updates are available
#   - Shell notification on login (similar to oh-my-zsh)
#
# Usage:
#   - Updates are checked automatically via launchd (configured in flake.nix)
#   - Check ~/.config/nix/.updates-available for update status
#   - Run 'check-updates.sh' manually to check immediately

{ config, pkgs, lib, ... }:

let
  homeDir = config.home.homeDirectory;
  scriptsDir = ../../scripts;
in
{
  config = {
    # Install the check-updates script
    home.file."./.local/bin/check-updates.sh" = {
      source = "${scriptsDir}/check-updates.sh";
      executable = true;
    };

    # Create log directory for launchd
    home.file."./.local/log/.keep" = {
      text = "";
    };

    # Launchd agent for the scheduled update checker
    launchd.agents.check-updates = {
      enable = true;
      config = {
        ProgramArguments = [ "${homeDir}/.local/bin/check-updates.sh" ];
        StartCalendarInterval = [
          {
            Hour = 9;
            Minute = 0;
          }
        ];
        StandardOutPath = "${homeDir}/.local/log/check-updates.log";
        StandardErrorPath = "${homeDir}/.local/log/check-updates.error.log";
        RunAtLoad = false;
        EnvironmentVariables = {
          PATH = "/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin:/opt/homebrew/sbin";
        };
      };
    };
  };
}
