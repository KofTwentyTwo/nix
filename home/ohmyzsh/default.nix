# Oh My Zsh Configuration Module
# ===============================
# Configures Oh My Zsh, a framework for managing zsh configuration.
#
# Features:
#   - Git shortcuts and aliases
#   - Docker and Kubernetes completions
#   - Sudo plugin for quick privilege escalation
#
# Portability:
#   - Works on any machine with zsh
#   - Plugins are standard Oh My Zsh plugins
#   - Add more plugins as needed: [ "git" "docker" "kubectl" "terraform" ]

{ config, pkgs, lib, ... }:
{
  config = {
    programs.zsh.oh-my-zsh = {
      enable = true;
      # Oh My Zsh plugins to load
      # Available plugins: https://github.com/ohmyzsh/ohmyzsh/wiki/Plugins
      # fzf integration comes from programs.fzf.enableZshIntegration (home/default.nix),
      # so the omz fzf plugin is intentionally omitted to avoid double keybindings.
      plugins = [ "git" "sudo" "docker" "kubectl" "aws" "helm" "terraform" "aliases" "extract" ];
    };
  };
}
