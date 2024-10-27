{ config, pkgs, lib, ... }:
with lib;
let
  python-debug = pkgs.python3.withPackages (p: with p; [ debugpy ]);
in
{
  config = mkIf config.my-home.useNeovim {
    programs.neovim = {
      enable = true;
      viAlias = true;
      vimAlias = true;
      vimdiffAlias = true;

      plugins = with pkgs.vimPlugins; [
        # Basics
        vim-sensible
      ];

      extraPackages = with pkgs; [
      ];

      extraConfig = ''
        let g:elixir_ls_home = "${pkgs.beam.packages.erlang.elixir-ls}"
        let g:python_debug_home = "${python-debug}"
        :luafile ~/.config/nvim/lua/init.lua
      '';
    };

    xdg.configFile.nvim = {
      source = ./config;
      recursive = true;
    };
  };
}
