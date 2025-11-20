# Neovim Configuration Module
# ===========================
# Manages Neovim configuration using LazyVim.
#
# This module:
#   - Installs Neovim via Home Manager
#   - Manages your Neovim configuration files
#   - Sets up vi/vim aliases
#
# Configuration Structure:
#   - config/init.lua - Entry point
#   - config/lua/config/ - Core configuration (options, keymaps, autocmds)
#   - config/lua/plugins/ - Plugin configurations
#   - config/lazyvim.json - LazyVim settings
#
# Portability:
#   - Configuration is version controlled in this repo
#   - Works on any machine with Neovim installed
#   - LazyVim will auto-install plugins on first run

{ config, pkgs, lib, ... }:

{
  config = {
    programs.neovim = {
      enable = true;
      
      # Create vi and vim aliases pointing to nvim
      viAlias = true;
      vimAlias = true;
      
      # Use Neovim from nixpkgs (or specify a different version)
      # package = pkgs.neovim-unwrapped;  # Uncomment to use unwrapped version
      
      # Default editor settings (also set in zsh sessionVariables)
      defaultEditor = true;
    };

    # Install Neovim configuration directory
    # This copies your entire nvim config to ~/.config/nvim
    home.file."./.config/nvim/" = {
      source = ./config;
      recursive = true;
      
      # Optional: Only copy specific files if you want more control
      # For now, we copy everything to maintain your LazyVim setup
    };
  };
}

