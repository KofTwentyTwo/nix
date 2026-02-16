# AI Profile Configuration Module
# ================================
# Manages ~/.ai/ directory with AI agent configuration files.
#
# Files managed:
#   - ~/.ai/0-init.md         Initialization instructions
#   - ~/.ai/1-profile.md      Personal operating profile (context only)
#   - ~/.ai/2-coding-style.md Engineering style guide (reference)
#   - ~/.ai/3-rules.md        Agent behavioral rules (all mandates)
#   - ~/.ai/4-preferences.yaml Machine-readable preferences (tuning knobs)
#   - ~/.ai/5-learnings.md    Ongoing tool and workflow learnings
#
# Note: ~/.claude/* files are managed by home/claude/default.nix

{ config, pkgs, lib, ... }:

{
  home.file.".ai/0-init.md".source = ./0-init.md;
  home.file.".ai/1-profile.md".source = ./1-profile.md;
  home.file.".ai/2-coding-style.md".source = ./2-coding-style.md;
  home.file.".ai/3-rules.md".source = ./3-rules.md;
  home.file.".ai/4-preferences.yaml".source = ./4-preferences.yaml;
  home.file.".ai/5-learnings.md".source = ./5-learnings.md;
}
