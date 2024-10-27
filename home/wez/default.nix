{ config, lib, pkgs, ... }: with lib; 

let
  cfg = config.modules.terminals.wezterm;
in {

   config = {

      programs.wezterm = {
         enable = true;
         package = pkgs.wezterm;
      };

      home.file."./.config/wezterm/" = {
         source = ./config;
         recursive = true;
      };
   };
}





