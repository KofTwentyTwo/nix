# Starship Prompt Configuration Module
# ====================================
# Configures Starship, a fast and customizable prompt for any shell.
#
# Features:
#   - Custom prompt format (see config/starship.toml)
#   - Git status, Kubernetes context, directory info
#   - Fast and minimal overhead
#
# Portability:
#   - Works on any machine with Starship installed
#   - Prompt configuration is in config/starship.toml

{ config, pkgs, lib, ... }:
{
   config = {
      programs.starship = {
         enable = true;
      };
   
      # Install custom Starship configuration
      home.file."./.config/starship.toml" = {
         source = ./config/starship.toml;
      };
   };
}
