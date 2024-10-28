{ config, pkgs, lib, ... }:
{
   config = {
      programs.zsh = {
         enable = true;
         enableCompletion = true;
         syntaxHighlighting.enable = true;
         enableVteIntegration = true;
         autosuggestion.strategy = "completion";
         initExtra = "export TERM=wezterm";

         shellAliases = {
            switch   = "clear;darwin-rebuild switch --flake ~/.config/nix";
            hist     = "history";
            ping     = "gping";
         };

         history = {
            size = 10000;
            save = 100000;
         };
      };
   };
}
