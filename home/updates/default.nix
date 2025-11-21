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

    # Launchd plist for the scheduled update checker
    home.file."./Library/LaunchAgents/com.jamesmaes.check-updates.plist" = {
      text = ''
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.jamesmaes.check-updates</string>
    <key>ProgramArguments</key>
    <array>
        <string>${homeDir}/.local/bin/check-updates.sh</string>
    </array>
    <key>StartCalendarInterval</key>
    <dict>
        <key>Hour</key>
        <integer>9</integer>
        <key>Minute</key>
        <integer>0</integer>
    </dict>
    <key>StandardOutPath</key>
    <string>${homeDir}/.local/log/check-updates.log</string>
    <key>StandardErrorPath</key>
    <string>${homeDir}/.local/log/check-updates.error.log</string>
    <key>RunAtLoad</key>
    <false/>
    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key>
        <string>/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin:/opt/homebrew/sbin</string>
    </dict>
</dict>
</plist>
      '';
      executable = false;
      force = true;
    };
  };
}
