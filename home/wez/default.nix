# WezTerm Configuration Module
# ===========================
# Configures WezTerm, a GPU-accelerated cross-platform terminal emulator.
#
# Features:
#   - Custom WezTerm configuration (see config/wezterm.lua)
#   - Fonts, colors, keybindings, and window settings
#
# Portability:
#   - Works on any machine with WezTerm installed
#   - Configuration is in config/wezterm.lua
#   - Note: Terminfo file may need manual installation on new machines
#     See README.md for terminfo installation instructions

{ config, lib, pkgs, ... }:

{
   config = {
      programs.wezterm = {
         enable = true;
         package = pkgs.wezterm;
      };

      # Install WezTerm configuration directory
      home.file."./.config/wezterm/" = {
         source = ./config;
         recursive = true;
      };
   };
}





