# GPG Configuration
# =================
# Configures GPG agent with pinentry-mac for GUI passphrase prompts.

{ config, pkgs, lib, ... }:

{
  config = {
    # GPG agent configuration
    home.file.".gnupg/gpg-agent.conf".text = ''
      # Use pinentry-mac for GUI passphrase prompts
      pinentry-program /opt/homebrew/bin/pinentry-mac

      # Cache passphrases for 8 hours (28800 seconds)
      default-cache-ttl 28800
      max-cache-ttl 28800

      # Enable SSH agent support (optional)
      # enable-ssh-support
    '';
  };
}
