{ config, pkgs, lib, ... }:
{
  config = {
     	home.file."./.config/nvim/" = {
     		source = ./config;
     		recursive = true;
   	};
    programs.neovim = {
      enable = true;
      defaultEditor = true;
      viAlias = true;
      vimAlias = true;
      vimdiffAlias = true;

      plugins = with pkgs.vimPlugins; [
        vim-sensible
	nvim-lspconfig
        nvim-treesitter.withAllGrammars
        plenary-nvim
        gruvbox-material
        mini-nvim
      ];

      extraPackages = with pkgs; [
      ];

    };
  };
}
