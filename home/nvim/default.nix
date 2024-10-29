{ config, pkgs, lib, inputs, ... }:
{
   config = {

   #   home.file."./.config/nvim/" = {
   #      source = ./config;
   #  		recursive = true;
  	#   };

   programs.neovim = 
   let
      toLua = str: "lua << EOF\n${str}\nEOF\n";
      toLuaFile = file: "lua << EOF\n${builtins.readFile file}\nEOF\n";
   in
   {
      enable = true;
      defaultEditor = true;
      viAlias = true;
      vimAlias = true;
      vimdiffAlias = true;


      plugins = with pkgs.vimPlugins; [     
         {
            plugin = vim-sensible;
         }

         {
            plugin = comment-nvim;
            config = toLua "require(\"Comment\").setup()";
         }
      ];

      extraPackages = with pkgs; [ ];


      extraLuaConfig = ''
         ${builtins.readFile ./config/options.lua}
      '';

    };
  };
}
