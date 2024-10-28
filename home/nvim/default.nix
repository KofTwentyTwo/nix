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
      ];

      extraPackages = with pkgs; [ ];
    };
  };
}
